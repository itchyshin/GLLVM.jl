# Point-estimation checks for the frozen Tweedie oracle. This is test harness
# code, never an R engine change or a recovery/interval-calibration verdict.
core070_tweedie_health <- function(opt, gradient, phi, power,
                                   g_tol = 1e-5, xi_max = 20,
                                   hessian_pd = NA) {
  stopifnot(length(g_tol) == 1L, is.finite(g_tol), g_tol > 0,
            length(xi_max) == 1L, is.finite(xi_max), xi_max > 0)
  pars <- opt$par
  finite_objective <- length(opt$objective) == 1L && is.finite(opt$objective)
  finite_parameters <- is.numeric(pars) && length(pars) > 0L && all(is.finite(pars))
  finite_report <- is.numeric(phi) && length(phi) > 0L && all(is.finite(phi)) &&
    all(phi > 0) && is.numeric(power) && length(power) == length(phi) &&
    all(is.finite(power)) && all(power > 1 & power < 2)
  finite_gradient <- is.numeric(gradient) && length(gradient) == length(pars) &&
    length(gradient) > 0L && all(is.finite(gradient))
  scaled_gradient <- if (finite_gradient && finite_objective)
    max(abs(gradient)) / max(1, abs(opt$objective)) else Inf
  power_coordinates <- grepl('^logit_p_tweedie', names(pars))
  power_interior <- all(is.finite(pars[power_coordinates])) &&
    all(abs(pars[power_coordinates]) <= xi_max)
  optimizer_ok <- isTRUE(as.integer(opt$convergence) == 0L)
  list(healthy = optimizer_ok && finite_objective && finite_parameters &&
         finite_report && finite_gradient && scaled_gradient <= g_tol && power_interior,
       optimizer_code = opt$convergence, optimizer_message = opt$message,
       finite_objective = finite_objective, finite_parameters = finite_parameters,
       finite_report = finite_report, gradient_max_scaled = scaled_gradient,
       gradient_tolerance = g_tol, power_interior = power_interior,
       n_free = length(pars), n_power_free = sum(power_coordinates),
       hessian_pd = hessian_pd,
       hessian_diagnostic = if (is.na(hessian_pd)) 'not measured; se=FALSE' else 'reported, not a recovery verdict')
}
