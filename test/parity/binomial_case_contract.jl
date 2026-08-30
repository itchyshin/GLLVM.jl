using SHA, TOML
function binomial_case_contract(root::AbstractString, id::AbstractString)
    path=joinpath(root,"docs/dev-log/core070/binomial-paired-contract.toml")
    c=TOML.parsefile(path)
    c["reference_commit"]=="b4d5fee64def88bc768dda1f1f77c29b295edd86" || error("wrong frozen reference")
    c["status"]=="PREDECLARED_CASES_NOT_EXECUTED" || error("unexpected case contract status")
    rows=c["case"]
    expected=["BINOMIAL-$(uppercase(l))-$(uppercase(t))" for l in ("logit","probit","cloglog") for t in ("bernoulli","varying")]
    sort([x["id"] for x in rows])==sort(expected) || error("missing, duplicate or unknown model case")
    length(unique(x["seed"] for x in rows))==6 || error("seeds must identify distinct fixed fixtures")
    for (index,expected_id) in enumerate(expected)
        x=only(filter(x->x["id"]==expected_id,rows))
        x["seed"]==90100+index || error("predeclared seed changed")
        x["link"] in ("logit","probit","cloglog") || error("unknown link")
        x["trials"] in ("bernoulli","varying") || error("unknown trial shape")
        x["id"]=="BINOMIAL-$(uppercase(x["link"]))-$(uppercase(x["trials"]))" || error("model case relabeled")
        (x["p"],x["n"],x["K"])==(3,160,1) || error("fixture dimensions changed")
        x["hessian"]=="observed" || error("same-estimator observed curvature required")
        x["classification"]=="required_core" && x["result_status"]=="NOT_EXECUTED" || error("unearned status or classification")
    end
    required=["tools/core070_binomial_paired.jl","test/parity/binomial_case_contract.jl",
              "test/parity/parity_helpers.jl","test/parity/parity_trial_inputs.jl"]
    Set(keys(c["source_pins"]))==Set(required) || error("missing executable source pin")
    c["acceptance"]["loglik_rtol"]==1e-6 || error("likelihood tolerance changed")
    c["acceptance"]["gradient_max"]==1e-4 || error("health tolerance changed")
    c["acceptance"]["fd_stability"]==1e-4 || error("FD stability gate changed")
    c["acceptance"]["reevaluation_atol"]==1e-8 || error("objective gate changed")
    for (name,pin) in c["source_pins"]
        bytes2hex(sha256(read(joinpath(root,name))))==pin || error("stale source: $name")
    end
    matches=filter(x->x["id"]==id,rows)
    length(matches)==1 || error("unknown binomial case: $id")
    row=only(matches)
    (row["p"],row["n"],row["K"])==(3,160,1) || error("fixture dimensions changed")
    row["hessian"]=="observed" || error("same-estimator observed curvature required")
    return c,row
end
