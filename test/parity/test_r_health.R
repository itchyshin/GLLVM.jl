source('test/parity/r_health.R')
opt <- list(par = c(beta = 0, logit_p_tweedie = 0), objective = 100,
            convergence = 0L, message = 'converged')
good <- core070_tweedie_health(opt, c(0, 0), 1, 1.5)
stopifnot(good$healthy, good$n_free == 2L, good$n_power_free == 1L)
stopifnot(!core070_tweedie_health(opt, c(1, 0), 1, 1.5)$healthy)
bad <- opt; bad$convergence <- 1L
stopifnot(!core070_tweedie_health(bad, c(0, 0), 1, 1.5)$healthy)
bad <- opt; bad$par[1] <- Inf
stopifnot(!core070_tweedie_health(bad, c(0, 0), 1, 1.5)$healthy)
stopifnot(!core070_tweedie_health(opt, c(NA_real_, 0), 1, 1.5)$healthy)
stopifnot(!core070_tweedie_health(opt, 0, 1, 1.5)$healthy)
stopifnot(!core070_tweedie_health(opt, c(0, 0), -1, 1.5)$healthy)
stopifnot(!core070_tweedie_health(opt, c(0, 0), 1, 2)$healthy)
bad <- opt; bad$par[2] <- 21
stopifnot(!core070_tweedie_health(bad, c(0, 0), 1, 1.5)$healthy)
fixed <- opt; fixed$par <- c(beta = 0)
stopifnot(core070_tweedie_health(fixed, 0, 1, 1.5)$n_power_free == 0L)

# R's $ partial matching must not treat sdreport_error as an sdreport object.
stopifnot(is.na(core070_hessian_pd(list(sdreport_error="not computed"))))
stopifnot(is.na(core070_hessian_pd(list(sd_report=FALSE))))
stopifnot(identical(core070_hessian_pd(list(sd_report=list(pdHess=TRUE))),TRUE))
stopifnot(identical(core070_hessian_pd(list(sd_report=list(pdHess=FALSE))),FALSE))
stopifnot(is.na(core070_hessian_pd(list(sd_report=list(pdHessian=TRUE)))))
cat('CORE070_R_HEALTH_CONTROLS_PASS\n')
