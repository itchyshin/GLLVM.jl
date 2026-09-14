# Destination B transport alignment

Frozen source: gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`.

| Quantity | R model / source | Julia contract | Independent check / target |
|---|---|---|---|
| Q=A⁻¹ | `R/fit-multi.R:3810,3846,3862` | canonical augmented sparse precision, unchanged | dense small A, including ancestor marginal block |
| log determinant | `log_det_A_phy_rr=logdet(A)`; explicit minus at line3811; C++ prior line1771 | native `PrecisionPhy.log_det=logdet(Q)`; adapter negates R field once | reject unnegated determinant; same 1e-8 checksum |
| factor field | C++1750–1774: each g column N(0,A) | augmented nodes × rank; ancestors retained | independent Gaussian draw and covariance recovery |
| response | C++2638–2644: eta(o)+=Lambda(t,k)g(node(o),k) | trait and node are separate axes; repeated observations share fields | response covariance entries and trait-covariance targets LL′ |
| node map | R3819: zero-based entry per observation, possibly repeated | native payload: unique zero-based entry per observed tip; model adapter separately maps observations to tips | reordered/repeated-label fixtures; never apply R observation map as native tip map |
| dense regularisation | R3860–3863: select named covariance block, add 1e-8 I, solve once | consume resulting Q; do not invert input again | record original covariance condition number and operation |

Earlier Julia payload documentation incorrectly called its logdet(Q) the shipped R logdet(A). The existing numerical checksum was already for Q; changing its sign would break that contract. Correct the description and perform the explicit sign conversion at the R adapter. No public R admission is opened by this documentation/check correction.

Scale metadata records what R already applied to Q, not an instruction to multiply Q a second time. Native tree scaling remains unchanged. The exact R observation map also cannot be substituted for the unique native tip map: both maps must be represented explicitly at the adapter boundary.
