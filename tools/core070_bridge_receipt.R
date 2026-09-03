# Preserve numeric values and matrix shape while removing transport-only classes.
core070_plain_receipt <- function(x) {
    if (is.language(x)) return(paste(deparse(x),collapse=" "))
    if (is.list(x)) return(lapply(x,core070_plain_receipt))
    if (is.object(x)) return(unclass(x))
    x
}

core070_all_true <- function(x,expected_names) {
    identical(sort(names(x)),sort(expected_names)) &&
        all(vapply(x,isTRUE,logical(1)))
}
