# Height-four tree precision precursor

Frozen R export `precision-reference.json` retains fourteen root-dropped
nodes, eight observed tips in shuffled order and six marginalized internal
nodes. SHA256: ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170.
The R correlation precision is exactly four times its native precision;
non-ultrametric correlation input is rejected. Export session 67459 exited 0.

The independent Julia path-covariance and marginal-consumer check is in
`test/test_destination_b_tree_precision.jl`. Session 22144 exited 0 with
19/19 assertions passing in 3.3 seconds. Wrong physical scaling, wrong
observation mapping and conditioning on internal nodes are discriminated.
No fitted, interval, recovery,
adapter-admission or Destination B qualification is implied.
