# Actual R adapter fixtures — public admission closed

Exporter87205 executes the scoped R adapter in the frozen namespace, without
loading Julia or changing the R engine. All three payloads match canonical
Q/determinant within1e-12 and exact maps/scales. Six tree internal nodes and
four pedigree founders remain in their precision systems. Dense covariance
regularization is done once on R side. FixtureSHA256:
089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549.

This is adapter transport evidence, not public R fit or extractor admission.
The emitting R adapter source hash and frozen DLL hash are in the fixture.

Actual bridge consumer21001 ran all three fits and retained flat outputs,
with94 assertions passing and three test-map assertions failing: input maps
are zero-based, returned Julia maps are one-based. Corrected the assertion,
not the implementation; final28020 passes97/97 in8.3s. An earlier22489 test
call failed before fitting because y is keyword-only. All numerical receipt
outputs remain from21001, unchanged. No R engine/model/tolerance changes.

All three bridge fits converge and match retained native likelihoods, fixed
effects and all twelve interval endpoint pairs. Every flat result explicitly
reports admission_status=closed. These tests exercise R payload preparation
and Julia bridge_fit, NOT JuliaCall marshalling or the public R fitted-object
wrapper/extractors. Those and independent review remain required S3b/S4 work.
