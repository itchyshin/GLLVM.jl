module Core070Receipts

using SHA
using TOML
using Test

export ExecutionRun, abort_run!, execution_inventory, finish_run!, record_case!,
       start_run!, testset_counts

"""State for one immutable, terminal CORE-070 parity receipt."""
mutable struct ExecutionRun
    dir::String
    requested_case_ids::Vector{String}
    source::Dict{String, Any}
    inventory::Dict{String, Any}
    contract_sha256::String
    run_id::String
    cells::Dict{String, Dict{String, Any}}
    terminal::Bool
end

_sha256(path::AbstractString) = bytes2hex(sha256(read(path)))
_run_id(dir::AbstractString) = bytes2hex(sha256("$(time_ns())\0$(getpid())\0$(dir)"))

function _inventory_digest(entries)
    rows = sort(["$(entry["path"])\0$(entry["sha256"])" for entry in entries])
    return bytes2hex(sha256(join(rows, "\n")))
end

"""
    execution_inventory(root, paths)

Hash every executable file in `paths`, recursively for directories.  The resulting
inventory is immutable input to both the run and each cell receipt; it deliberately
includes adapters and environment files rather than only `src/`.
"""
function execution_inventory(root::AbstractString, paths::AbstractVector{<:AbstractString})
    root_abs = abspath(root)
    entries = Dict{String, Any}[]
    for raw in paths
        path = abspath(root_abs, raw)
        ispath(path) || throw(ArgumentError("execution-inventory path is missing: $raw"))
        if isfile(path)
            islink(path) && throw(ArgumentError("execution-inventory path may not be a symlink: $raw"))
            push!(entries, Dict("path" => relpath(path, root_abs), "sha256" => _sha256(path)))
        else
            for (dir, _, files) in walkdir(path)
                for file in sort(files)
                    candidate = joinpath(dir, file)
                    islink(candidate) && continue
                    push!(entries, Dict("path" => relpath(candidate, root_abs),
                                        "sha256" => _sha256(candidate)))
                end
            end
        end
    end
    sort!(entries; by = entry -> entry["path"])
    paths_seen = [entry["path"] for entry in entries]
    length(paths_seen) == length(unique(paths_seen)) ||
        throw(ArgumentError("execution-inventory paths must be unique"))
    return Dict("entries" => entries, "manifest_sha256" => _inventory_digest(entries))
end

function _assert_fresh_dir(dir::AbstractString)
    isdir(dir) || mkpath(dir)
    occupied = filter(name -> name == "run.toml" ||
                       (startswith(name, "cell-") && endswith(name, ".toml")), readdir(dir))
    isempty(occupied) || throw(ArgumentError(
        "receipt directory already contains run evidence; choose a new directory to preserve prior receipts"))
end

function _write_toml(dir::AbstractString, name::AbstractString, receipt::Dict{String, Any})
    path = joinpath(dir, name)
    open(path, "w") do io
        TOML.print(io, receipt)
    end
    return path
end

function _counts_dict(passed::Integer, failed::Integer, errored::Integer, broken::Integer)
    all(x -> x >= 0, (passed, failed, errored, broken)) ||
        throw(ArgumentError("test counts cannot be negative"))
    return Dict("passed" => Int(passed), "failed" => Int(failed),
                "errored" => Int(errored), "broken" => Int(broken))
end

function _cell_status(counts::Dict{String, Int})
    counts["passed"] > 0 && counts["failed"] == 0 && counts["errored"] == 0 &&
        counts["broken"] == 0 ? "success" : "failed"
end

function _run_receipt(run::ExecutionRun, status::String; reason::Union{Nothing, String} = nothing)
    cells = Dict{String, Any}(id => cell for (id, cell) in run.cells)
    receipt = Dict{String, Any}(
        "status" => status,
        "run_id" => run.run_id,
        "requested_case_ids" => run.requested_case_ids,
        "completed_case_ids" => sort!(collect(keys(run.cells))),
        "scope" => length(run.requested_case_ids) == 17 ? "all17" : "subset",
        "actual_assertions" => sum((cell["assertions"]["passed"] for cell in values(run.cells)); init = 0),
        "source" => run.source,
        "execution" => run.inventory,
        "contract_sha256" => run.contract_sha256,
        "cells" => cells,
    )
    reason === nothing || (receipt["failure_reason"] = reason)
    status == "success" && (receipt["success_marker"] = "CORE070_PARITY_SUCCESS")
    status == "success" && (receipt["exit_code"] = 0)
    status == "started" && (receipt["exit_code"] = -1)
    status == "failed" && (receipt["exit_code"] = 1)
    return receipt
end

function _write_run!(run::ExecutionRun, status::String; reason::Union{Nothing, String} = nothing)
    return _write_toml(run.dir, "run.toml", _run_receipt(run, status; reason))
end

function start_run!(dir::AbstractString; requested_case_ids::AbstractVector{<:AbstractString},
                    source::AbstractDict, inventory::Dict{String, Any}, contract_sha256::AbstractString)
    requested = String.(requested_case_ids)
    isempty(requested) && throw(ArgumentError("required receipt run needs at least one requested case"))
    length(requested) == length(unique(requested)) ||
        throw(ArgumentError("requested case IDs must be unique"))
    entries = get(inventory, "entries", nothing)
    entries isa AbstractVector || throw(ArgumentError("execution inventory has no entries"))
    get(inventory, "manifest_sha256", nothing) == _inventory_digest(entries) ||
        throw(ArgumentError("execution inventory hash does not bind its entries"))
    isempty(contract_sha256) && throw(ArgumentError("contract hash is required"))
    target = abspath(dir)
    _assert_fresh_dir(target)
    source_dict = Dict{String, Any}(String(key) => value for (key, value) in source)
    run = ExecutionRun(target, requested, source_dict, inventory, String(contract_sha256), _run_id(target),
                       Dict{String, Dict{String, Any}}(), false)
    _write_run!(run, "started")
    return run
end

function record_case!(run::ExecutionRun, id::AbstractString, fixture::AbstractString;
                      passed::Integer, failed::Integer = 0, errored::Integer = 0, broken::Integer = 0)
    run.terminal && throw(ArgumentError("cannot record a cell after a terminal receipt"))
    id_string = String(id)
    id_string in run.requested_case_ids || throw(ArgumentError("case was not requested: $id_string"))
    haskey(run.cells, id_string) && throw(ArgumentError("duplicate completed case: $id_string"))
    isfile(fixture) || throw(ArgumentError("fixture is missing: $fixture"))
    counts = _counts_dict(passed, failed, errored, broken)
    cell = Dict{String, Any}(
        "id" => id_string,
        "run_id" => run.run_id,
        "status" => _cell_status(counts),
        "fixture" => String(fixture),
        "fixture_sha256" => _sha256(fixture),
        "assertions" => counts,
        "execution_manifest_sha256" => run.inventory["manifest_sha256"],
        "contract_sha256" => run.contract_sha256,
    )
    run.cells[id_string] = cell
    _write_toml(run.dir, "cell-$(id_string).toml", cell)
    return cell
end

"""Return pass/fail/error/broken counts from a Test.jl testset."""
function testset_counts(testset)
    counts = Test.get_test_counts(testset)
    # Test.jl reports direct counts first, then recursive child counts.
    # Every family fixture nests below the runner wrapper.
    return _counts_dict(counts[1] + counts[5], counts[2] + counts[6],
                        counts[3] + counts[7], counts[4] + counts[8])
end

function abort_run!(run::ExecutionRun, reason)
    run.terminal && return nothing
    run.terminal = true
    message = reason isa AbstractString ? String(reason) : sprint(showerror, reason)
    _write_run!(run, "failed"; reason = message)
    return nothing
end

function finish_run!(run::ExecutionRun)
    run.terminal && throw(ArgumentError("receipt run is already terminal"))
    completed = sort!(collect(keys(run.cells)))
    expected = sort(copy(run.requested_case_ids))
    bad_cells = [id for id in completed if run.cells[id]["status"] != "success"]
    if completed != expected || !isempty(bad_cells)
        run.terminal = true
        _write_run!(run, "failed"; reason = completed != expected ?
            "requested/completed case inventory mismatch" : "one or more cells have failed, skipped, broken, or zero assertions")
        throw(ArgumentError("cannot certify CORE-070 receipt: requested/completed inventory or assertions are invalid"))
    end
    run.terminal = true
    _write_run!(run, "success")
    return nothing
end

end # module
