# Execute exactly the Documenter example, then check fitted-object integration.
using GLLVM, Test, SHA, TOML
page = "docs/src/response-families.md"
source = read(page, String)
blocks = collect(eachmatch(r"```@example pervar_design\n(.*?)\n```"s, source))
length(blocks) == 1 || error("expected exactly one named pervar example")
code = blocks[1].captures[1]
include_string(Main, code, page)
@testset "Documented pervar design integration" begin
    @test fit_x.converged
    @test length(coef(fit_x)) == p+1
    @test GLLVM._nparams(fit_x) == p+1+GLLVM.rr_theta_len(p,1)+p
    @test aic(fit_x) ≈ -2fit_x.loglik+2GLLVM._nparams(fit_x)
    @test bic(fit_x,n) ≈ -2fit_x.loglik+log(n)*GLLVM._nparams(fit_x)
    @test all(isfinite,coef(fit_x))
end
mkpath("example")
open("example/result.toml","w") do io
    TOML.print(io,Dict("page_sha256"=>bytes2hex(sha256(source)),
        "code_sha256"=>bytes2hex(sha256(code)),"coefficients"=>coef(fit_x),
        "nparams"=>GLLVM._nparams(fit_x),"loglik"=>fit_x.loglik,
        "aic"=>aic(fit_x),"bic"=>bic(fit_x,n),"n_sites"=>n,
        "converged"=>fit_x.converged,"assertions"=>6))
end
println("PERVAR_DOCUMENTED_EXAMPLE_PASS")
