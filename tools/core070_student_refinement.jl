# Same original Student fixture: public R controls only, diagnostic until healthy.
using GLLVM, RCall, Random, Distributions, SHA, TOML, Test
ARGS in (String[], ["--bfgs"]) || error("only optional --bfgs is accepted")
bfgs = ARGS == ["--bfgs"]
@assert realpath(Base.pkgdir(GLLVM)) == realpath(pwd())
include(joinpath(pwd(), "test/parity/parity_helpers.jl"))
fixture = "test/parity/test_studentt_parity.jl"
fixture_hash = bytes2hex(sha256(read(fixture)))
@assert fixture_hash == "484aac8346fb9382ea4386cd18ce95fc85bd52a72f9f62e4984f664131711e68"
Random.seed!(71)
p, K, n = 5, 1, 130
β = [0.2, -0.1, 0.3, 0.0, -0.2]
Λ = 0.5 .* parity_loadings_p5k2()[:, 1:K]
η = β .+ Λ * randn(K, n)
Y = zeros(p, n)
for t in 1:p, s in 1:n
    Y[t,s] = η[t,s] + 0.7 * rand(TDist(4.0))
end
data_hash = bytes2hex(sha256(reinterpret(UInt8, vec(Y))))
@assert data_hash == "2c8ac438e655b3ec39209799676f689c8a875ba300ec0df032c76ee506a94365"
original = fit_gllvmtmb_parity_student(Y, K; df_fixed=nothing)
@rput bfgs
R"""
 original_fit <- fit_r
 original_gradient <- original_fit$tmb_obj$gr(original_fit$opt$par)
 refined_fit <- gllvmTMB(
   value ~ 0 + trait + latent(0 + trait | site, d=K, unique=FALSE),
   data=df_long, unit="site", trait="trait", family=fam_obj,
   control=gllvmTMBcontrol(n_init=1L, se=FALSE, start_from=original_fit,
     optimizer=if(bfgs) "optim" else "nlminb",
     optArgs=if(bfgs) list(method="BFGS", control=list(reltol=1e-12, maxit=1500))
       else list(control=list(rel.tol=1e-12, eval.max=2000, iter.max=1500))))
 stopifnot(identical(names(original_fit$opt$par), names(refined_fit$opt$par)),
           identical(original_fit$tmb_data, refined_fit$tmb_data),
           identical(original_fit$tmb_obj$env$map, refined_fit$tmb_obj$env$map))
 refined_gradient <- refined_fit$tmb_obj$gr(refined_fit$opt$par)
 """
native = fit_studentt_gllvm(Y; K=K, nu=nothing, disp_group=:species, iterations=400)
θ = vcat(vec(native.Λ), native.β, log.(native.σ), log.(native.ν .- 1))
objective(x) = -GLLVM.studentt_marginal_loglik_laplace(
    Y, reshape(x[1:5], 5, 1), x[6:10], exp.(x[11:15]); ν=1 .+ exp.(x[16:20]))
native_gradient = GLLVM.ForwardDiff.gradient(objective, θ)
report = Dict{String,Any}(
    "scope" => "ORIGINAL_STUDENT_PUBLIC_CONTROL_DIAGNOSTIC_NOT_FULL_PARITY",
    "fixture_sha256"=>fixture_hash, "data_sha256"=>data_hash,
    "reference_commit"=>"b4d5fee64def88bc768dda1f1f77c29b295edd86",
    "original_loglik"=>original.logLik, "original_code"=>original.optimizer_code,
    "original_message"=>original.optimizer_message,
    "original_gradient_max"=>rcopy(Float64, R"max(abs(original_gradient))"),
    "original_df"=>original.df_vec,
    "refined_loglik"=>rcopy(Float64, R"as.numeric(logLik(refined_fit))"),
    "refined_code"=>rcopy(Int, R"as.integer(refined_fit$opt$convergence)"),
    "refined_message"=>rcopy(String, R"as.character(refined_fit$opt$message)"),
    "refined_gradient_max"=>rcopy(Float64, R"max(abs(refined_gradient))"),
    "refined_gradient"=>rcopy(Vector{Float64}, R"as.numeric(refined_gradient)"),
    "refined_parameters"=>rcopy(Vector{Float64}, R"as.numeric(refined_fit$opt$par)"),
    "refined_df"=>rcopy(Vector{Float64}, R"as.numeric(refined_fit$report$df_student)"),
    "refined_sigma"=>rcopy(Vector{Float64}, R"as.numeric(refined_fit$report$sigma_student)"),
    "native_loglik"=>native.loglik, "native_converged"=>native.converged,
    "native_gradient_max"=>maximum(abs, native_gradient),
    "native_gradient"=>native_gradient, "native_df"=>native.ν,
    "native_sigma"=>native.σ, "native_parameters"=>θ,
    "optimizer"=>(bfgs ? "optim-BFGS" : "nlminb"),
    "tight_public_r_control"=>true, "same_data_map_parameter_names"=>true)
report["loglik_delta"] = abs(native.loglik - report["refined_loglik"])
mkpath("refinement")
open("refinement/result.toml", "w") do io; TOML.print(io, report); end
println("STUDENT_REFINEMENT_RESULT ", report)
@testset "Original Student public-control health" begin
    @test report["refined_code"] == 0
    @test native.converged
    @test report["loglik_delta"] <= 0.001
    @test report["refined_gradient_max"] <= 1e-4
    @test report["native_gradient_max"] <= 1e-4
    @test all(isfinite, report["refined_parameters"])
    @test all(isfinite, θ)
    @test all(v -> isfinite(v) && v > 1, report["refined_df"])
    @test all(v -> isfinite(v) && v > 1, native.ν)
    @test all(v -> isfinite(v) && v > 0, report["refined_sigma"])
    @test all(v -> isfinite(v) && v > 0, native.σ)
end
println("STUDENT_REFINEMENT_HEALTH_PASS")
