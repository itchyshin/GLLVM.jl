#!/usr/bin/env julia
# tools/julia-checkpoint.jl
#
# Julia analog of `tools/codex-checkpoint.R` from the drmTMB repo, adapted for
# GLLVM.jl conventions (AGENTS.md, docs/dev-log/after-task/).
#
# Usage:
#     julia --project=. tools/julia-checkpoint.jl
#
# Takes no arguments. Reads git state and the most recent after-task report
# from the current repo and prints a recovery-checkpoint markdown snippet to
# STDOUT. Nothing is written to disk — the snippet is meant to be pasted into
# a new session at the start of a recovery / context-switch task.
#
# What it produces (sections):
#   ## Goal               (placeholder — user fills in one line)
#   ## Constraints        (auto-pulled from AGENTS.md `## Hard boundaries`)
#   ## Files in flight    (auto: git status --porcelain)
#   ## Tests              (auto: head of newest docs/dev-log/after-task/*.md)
#   ## Remaining          (placeholder — user fills in)
#   ## Risks              (placeholder — user fills in)
#   ## Next command       (auto: rehydration cmds + last 3 commits)
#
# When to use:
#   - Start of a new session that resumes interrupted work.
#   - Before a context switch (closing one slice, opening another).
#   - When the working tree is non-trivial and you want a durable handoff.
#
# Hard boundary: this script does NOT call git add / git commit / git push.
# Stage-by-name and commits are the maintainer's call after Rose audit.

using Dates
using Printf

# ---------------------------------------------------------------------------
# Shell helpers
# ---------------------------------------------------------------------------

"""
    run_capture(cmd) -> (stdout::String, status::Int)

Run an external command, capturing combined stdout/stderr as a String.
Returns ("", non-zero) on failure rather than throwing — the checkpoint is
best-effort.
"""
function run_capture(cmd::Cmd)
    out_buf = IOBuffer()
    try
        run(pipeline(cmd, stdout = out_buf, stderr = out_buf))
        return (String(take!(out_buf)), 0)
    catch err
        msg = sprint(showerror, err)
        return (String(take!(out_buf)) * "\n(ERROR: " * msg * ")", 1)
    end
end

"""
    repo_root() -> String

Resolve the git repository root, falling back to the current working dir.
"""
function repo_root()
    out, status = run_capture(`git rev-parse --show-toplevel`)
    return status == 0 ? strip(out) : pwd()
end

"""
    code_block(text; lang="text") -> String

Wrap a chunk of text in a fenced code block. Replaces an empty body with
"(no output)" so the block always renders.
"""
function code_block(text::AbstractString; lang::String = "text")
    body = isempty(strip(text)) ? "(no output)" : rstrip(text)
    return "```" * lang * "\n" * body * "\n```"
end

# ---------------------------------------------------------------------------
# Section content extraction
# ---------------------------------------------------------------------------

"""
    hard_boundaries(agents_path) -> String

Read the `## Hard boundaries` section of AGENTS.md verbatim. Returns a
fallback string if AGENTS.md is missing or the section is absent.
"""
function hard_boundaries(agents_path::AbstractString)
    if !isfile(agents_path)
        return "_(AGENTS.md not found at `$(agents_path)`)_"
    end
    lines = readlines(agents_path)
    start_idx = findfirst(l -> startswith(l, "## Hard boundaries"), lines)
    if start_idx === nothing
        return "_(`## Hard boundaries` section not found in AGENTS.md)_"
    end
    # Find the next H2 heading after start_idx; collect bullets in between.
    end_idx = length(lines)
    for i in (start_idx + 1):length(lines)
        if startswith(lines[i], "## ") && !startswith(lines[i], "## Hard boundaries")
            end_idx = i - 1
            break
        end
    end
    section = lines[(start_idx + 1):end_idx]
    body = strip(join(section, "\n"))
    return isempty(body) ? "_(Hard boundaries section is empty)_" : body
end

"""
    files_in_flight() -> String

Wrapped `git status --porcelain` output.
"""
function files_in_flight()
    out, _ = run_capture(`git status --porcelain`)
    return code_block(out)
end

"""
    newest_after_task(dir) -> (path::Union{String,Nothing}, mtime::Union{DateTime,Nothing})

Locate the most recently modified `*.md` file under `docs/dev-log/after-task/`.
Returns (nothing, nothing) if the directory is missing or empty.
"""
function newest_after_task(dir::AbstractString)
    isdir(dir) || return (nothing, nothing)
    md_files = filter(f -> endswith(f, ".md"), readdir(dir; join = true))
    isempty(md_files) && return (nothing, nothing)
    sort!(md_files; by = f -> mtime(f), rev = true)
    newest = md_files[1]
    ts = Dates.unix2datetime(mtime(newest))
    return (newest, ts)
end

"""
    test_summary(report_path) -> String

Return the first ~20 non-blank lines of the report so the checkpoint shows
the title + result tally. Caller has already verified the path exists.
"""
function test_summary(report_path::AbstractString)
    lines = readlines(report_path)
    keep = String[]
    for ln in lines
        push!(keep, ln)
        length(keep) >= 20 && break
    end
    return code_block(join(keep, "\n"); lang = "markdown")
end

"""
    last_commits(n) -> String

Wrapped `git log --oneline -n N` output.
"""
function last_commits(n::Int)
    out, _ = run_capture(`git log --oneline -$(n)`)
    return code_block(out)
end

"""
    branch_and_head() -> (branch, sha)
"""
function branch_and_head()
    b_out, _ = run_capture(`git rev-parse --abbrev-ref HEAD`)
    s_out, _ = run_capture(`git rev-parse --short HEAD`)
    return (strip(b_out), strip(s_out))
end

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------

function render()
    root = repo_root()
    cd(root)

    branch, sha = branch_and_head()
    now_local = Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS")

    agents_path = joinpath(root, "AGENTS.md")
    constraints_md = hard_boundaries(agents_path)

    files_md = files_in_flight()

    after_dir = joinpath(root, "docs", "dev-log", "after-task")
    newest_path, newest_mtime = newest_after_task(after_dir)
    tests_md = if newest_path === nothing
        "_(no after-task reports found under `docs/dev-log/after-task/`)_"
    else
        rel = relpath(newest_path, root)
        ts_str = Dates.format(newest_mtime, dateformat"yyyy-mm-dd HH:MM")
        "Newest after-task report: `$(rel)` (modified $(ts_str))\n\n" *
            test_summary(newest_path)
    end

    commits_md = last_commits(3)

    next_md = """
```sh
git status --short --branch
git diff --stat
julia --project=. test/runtests.jl
```

Recent commits:

$(commits_md)
"""

    println("# GLLVM.jl Recovery Checkpoint")
    println()
    println("Generated: $(now_local)")
    println("Branch: `$(branch)` @ `$(sha)`")
    println("Repository: `$(root)`")
    println()
    println("## Goal")
    println()
    println("_(fill in: one-sentence description of what this session is resuming)_")
    println()
    println("## Constraints")
    println()
    println("From `AGENTS.md` § Hard boundaries:")
    println()
    println(constraints_md)
    println()
    println("## Files in flight")
    println()
    println("`git status --porcelain`")
    println()
    println(files_md)
    println()
    println("## Tests")
    println()
    println(tests_md)
    println()
    println("## Remaining")
    println()
    println("_(fill in: bullet list of unfinished sub-steps)_")
    println()
    println("## Risks")
    println()
    println("_(fill in: known fragile pieces, parallel agents on overlapping files, untested edge cases)_")
    println()
    println("## Next command")
    println()
    println(next_md)
    return nothing
end

render()
