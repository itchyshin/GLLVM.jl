# Independent high-precision reference, not an R-oracle workaround.
using Test, GLLVM

function student_precision_reference(ν, σ, y)
    h=(ν+1)/2
    GLLVM.loggamma(h)-GLLVM.loggamma(ν/2)-log(ν*big(π))/2-log(σ)-
        h*log1p(y^2/(ν*σ^2))
end

@testset "Student-t density precision and outer derivatives" begin
    setprecision(BigFloat,256) do
        @testset "Float64 density including Gaussian limit" begin
            for ν in (4.0,63.999,64.0,64.001,1e3,1e6,1e8,2.3174518756022614e10,1e12), y in (0.0,0.7,3.0)
                observed=GLLVM._glm_logpdf(GLLVM.StudentTFamily(ν,0.7),0.0,1,y)
                reference=student_precision_reference(BigFloat(ν),BigFloat(0.7),BigFloat(y))
                @test abs(BigFloat(observed)-reference) <= big"1e-12"
            end
        end
        @testset "ForwardDiff log-df gradient and Hessian" begin
            for ν in (4.0,64.0,1e3,1e6,1e12), y in (0.0,3.0)
                θ=log(ν-1)
                f(x)=GLLVM._glm_logpdf(GLLVM.StudentTFamily(1+exp(x),0.7),0.0,1,y)
                ref(x)=student_precision_reference(1+exp(x),BigFloat(0.7),BigFloat(y))
                x=BigFloat(θ); h=big"1e-10"
                grad=(ref(x+h)-ref(x-h))/(2h)
                hess=(ref(x+h)-2ref(x)+ref(x-h))/h^2
                @test isapprox(GLLVM.ForwardDiff.derivative(f,θ),Float64(grad);rtol=1e-7,atol=1e-14)
                @test isapprox(GLLVM.ForwardDiff.hessian(z->f(z[1]),[θ])[1,1],Float64(hess);rtol=1e-6,atol=1e-14)
            end
        end
        @testset "BigFloat precision is not silently reduced" begin
            for ν in (big"1000",big"1e12")
                observed=GLLVM._glm_logpdf(GLLVM.StudentTFamily(ν,big"0.7"),big"0",1,big"3")
                reference=student_precision_reference(ν,big"0.7",big"3")
                @test abs(observed-reference) <= big"1e-50"
                θ=log(ν-1); h=big"1e-20"
                f(x)=GLLVM._glm_logpdf(GLLVM.StudentTFamily(1+exp(x),big"0.7"),big"0",1,big"3")
                expected=(f(θ+h)-f(θ-h))/(2h)
                @test abs(GLLVM.ForwardDiff.derivative(f,θ)-expected) <= big"1e-40"
            end
        end
    end
end
