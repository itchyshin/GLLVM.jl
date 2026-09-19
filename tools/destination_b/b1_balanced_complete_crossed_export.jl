# Export the immutable B1 fixture for the one authorized frozen-R control.
# It constructs data only and never imports GLLVModels or calls an optimizer.

length(ARGS) == 1 || error("Use: julia b1_balanced_complete_crossed_export.jl OUTPUT.csv")
output = ARGS[1]
!ispath(output) || error("Refusing to overwrite existing B1 input: $output")
include(joinpath(@__DIR__, "..", "..", "test", "fixtures", "destination_b_b1_balanced_complete_crossed_design.jl"))
fixture = destination_b_b1_balanced_complete_crossed_design()
# Julia's supported modes omit Python's exclusive-create "x".  The prior
# `ispath` guard makes this single-lane export no-clobber in this protocol.
open(output, "w") do io
    println(io, "value,trait,unit,obs,cluster_id,cluster2_id")
    for row in fixture.long
        println(io, join((repr(row.value), row.trait, row.unit, row.obs, row.cluster_id, row.cluster2_id), ','))
    end
end
println("B1 balanced complete-crossed fixture export PASS rows=$(fixture.nlong)")
