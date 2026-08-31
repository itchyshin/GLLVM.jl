isdefined(@__MODULE__, :Core070CovarianceFormulaCases) || include("covariance_formula_cases.jl")
Core070CovarianceFormulaCases.run_group!(Core070CaseRegistry.COVARIANCE_MODE_IDS,
    joinpath(_core070_receipt_dir(), "covariance-formula-modes-raw"))
