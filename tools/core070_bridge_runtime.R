# No fits and no automatic installation: qualify the public setup route only.
options(warn=1)
lib <- "/home/snakagaw/core070-aghq-20260830/oracle-build-01/library"
.libPaths(c(lib, "/home/snakagaw/R/v07-lib", .libPaths()))
stopifnot(normalizePath(find.package("gllvmTMB")) == normalizePath(file.path(lib,"gllvmTMB")))
stopifnot(requireNamespace("JuliaCall",quietly=TRUE))
stopifnot(requireNamespace("jsonlite",quietly=TRUE))
dependency_snapshot <- function(suffix) {
    target <- paste0("bridge-runtime-dependencies-",suffix,".json")
    args <- c("tools/core070_bridge_dependencies.py", find.package("JuliaCall"),
              Sys.getenv("JULIA_HOME"), target)
    pin <- system2("python3", shQuote(args), stdout=TRUE)
    stopifnot(is.null(attr(pin,"status")),length(pin)==1,
              grepl("^[0-9a-f]{64}$",pin))
    cat("BRIDGE_DEPENDENCY_SHA256",target,pin,"\n")
    pin
}
dependencies_before <- dependency_snapshot("before")
cat("R_VERSION",R.version.string,"\n")
cat("JULIACALL_VERSION",as.character(packageVersion("JuliaCall")),"\n")
cat("JULIACALL_LIBRARY",find.package("JuliaCall"),"\n")
parent_preload <- Sys.getenv("LD_PRELOAD")
# Installed JuliaCall adds its own child preload; avoid its unquoted two-path join.
Sys.unsetenv("LD_PRELOAD")
cat("INITIALIZE_JULIACALL_NO_INSTALL\n")
JuliaCall::julia_setup(JULIA_HOME=Sys.getenv("JULIA_HOME"),installJulia=FALSE,
                      install=FALSE,verbose=TRUE)
cat("INITIALIZE_PUBLIC_GLLVM_SETUP\n")
gllvmTMB::gllvm_julia_setup(jl_path=Sys.getenv("JULIA_PROJECT"),julia_home=Sys.getenv("JULIA_HOME"))
version <- JuliaCall::julia_eval("string(VERSION)")
source <- JuliaCall::julia_eval("pathof(GLLVM)")
project <- JuliaCall::julia_eval("Base.active_project()")
roundtrip <- JuliaCall::julia_eval("sum([1.0,2.0,3.0])")
stopifnot(identical(as.numeric(roundtrip),6))
stopifnot(normalizePath(source) == normalizePath(file.path(getwd(),"src","GLLVM.jl")))
failure <- tryCatch({JuliaCall::julia_eval('error("CORE070_EXPECTED_RUNTIME_ERROR")'); "NO_ERROR"}, error=conditionMessage)
stopifnot(grepl("CORE070_EXPECTED_RUNTIME_ERROR",failure,fixed=TRUE))
stopifnot(JuliaCall::julia_eval("1+1")==2)
receipt <- list(parent_preload=parent_preload,child_preload_environment=Sys.getenv("LD_PRELOAD"),expected_error=failure,R=R.version.string,Julia=version,JuliaCall=as.character(packageVersion("JuliaCall")),
    JuliaCall_path=find.package("JuliaCall"),gllvmTMB_path=find.package("gllvmTMB"),
    active_project=project,GLLVM_source=source,roundtrip=roundtrip,
    julia_threads=JuliaCall::julia_eval("Threads.nthreads()"),
    blas_threads=JuliaCall::julia_eval("GLLVM.LinearAlgebra.BLAS.get_num_threads()"),
    libPaths=.libPaths())
stopifnot(receipt$julia_threads==1,receipt$blas_threads==1)
dependencies_after <- dependency_snapshot("after")
stopifnot(identical(dependencies_before,dependencies_after))
receipt$dependencies_sha256 <- dependencies_after
saveRDS(receipt,"bridge-runtime.rds")
jsonlite::write_json(receipt,"bridge-runtime.json",auto_unbox=TRUE,pretty=TRUE,digits=NA)
print(receipt)
cat("CORE070_PUBLIC_BRIDGE_RUNTIME_PASS\n")
