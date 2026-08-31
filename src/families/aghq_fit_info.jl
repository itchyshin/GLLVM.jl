# Estimator identity for the public Poisson Stage1a route. Internal types.
struct AGHQPoissonData
    responses::Matrix{Float64}
    mask::BitMatrix
    offset::Matrix{Float64}
end
struct AGHQFitInfo{C,B,R}
    requested::Union{Symbol,Int}
    actual::Symbol
    k::Int
    requested_k::Int
    node_count::Int
    reason::Symbol
    penalised::Bool
    ridge::Float64
    controls::C
    base_controls::B
    result::R
    caches::Vector{AGHQAdaptation}
    data::Union{Nothing,AGHQPoissonData}
    input_digest::String
    mode_gradient_max::Float64
end

function _aghq_request(value)
    value===false || value===nothing ? (return :off) : nothing
    value===true || value===:auto ? (return :auto) : nothing
    value isa Integer && !(value isa Bool) && 0<value<=typemax(Int) ||
        throw(ArgumentError("aghq must be false, nothing, true/:auto, or a positive integer node count"))
    return Int(value)
end
function _aghq_controls(input)
    input isa NamedTuple || throw(ArgumentError("aghq_control must be a NamedTuple"))
    defaults=(n_adapt=400,iter_cap=1,continuation=true,escalate_patience=3,
        shift_tol=1e-4,grad_tol=1e-4,grad_tol_rel=1e-6,f_tol=1e-9,
        rho_min=1/64,optimizer_iterations=1000,multistart=true,mode_gradient_tol=1e-7,mode_maxiter=100,mode_tol=1e-9)
    isempty(setdiff(keys(input),keys(defaults))) || throw(ArgumentError("unknown aghq_control key"))
    c=merge(defaults,input)
    for name in (:n_adapt,:iter_cap,:escalate_patience,:optimizer_iterations,:mode_maxiter)
        v=getproperty(c,name)
        v isa Integer && !(v isa Bool) && 0<v<=typemax(Int) ||
            throw(ArgumentError("aghq_control.$name must be a positive integer"))
    end
    for name in (:continuation,:multistart)
        getproperty(c,name) isa Bool || throw(ArgumentError("aghq_control.$name must be Bool"))
    end
    for name in (:shift_tol,:grad_tol,:grad_tol_rel,:f_tol,:mode_gradient_tol,:mode_tol,:rho_min)
        v=getproperty(c,name)
        v isa Real && !(v isa Bool) && isfinite(v) && v>=0 ||
            throw(ArgumentError("aghq_control.$name must be finite and nonnegative"))
    end
    c.mode_tol>0 || throw(ArgumentError("mode_tol must be positive"))
    c.mode_gradient_tol>0 || throw(ArgumentError("mode_gradient_tol must be positive"))
    0<c.rho_min<=1 || throw(ArgumentError("rho_min must be in (0,1]"))
    return c
end
_aghq_outer_controls(c)=(n_adapt=c.n_adapt,iter_cap=c.iter_cap,continuation=c.continuation,
    escalate_patience=c.escalate_patience,shift_tol=c.shift_tol,grad_tol=c.grad_tol,
    grad_tol_rel=c.grad_tol_rel,f_tol=c.f_tol,rho_min=c.rho_min,optimizer_iterations=c.optimizer_iterations)
_aghq_data_digest(d::AGHQPoissonData)=bytes2hex(SHA.sha256(
    string(size(d.responses))*"|"*join(vec(d.responses),",")*"|"*join(vec(d.mask),",")*"|"*join(vec(ifelse.(d.mask,d.offset,0.0)),",")))
