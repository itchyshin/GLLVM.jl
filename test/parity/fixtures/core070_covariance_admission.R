# Exercise frozen rewrite/parser behavior; constructor marker bodies are not evidence.
terms_for <- function(text) {
 f <- as.formula(paste('y ~',text))
 parse_multi_formula(rewrite_canonical_aliases(f))$covstructs
}
term_has <- function(text, kind, fields=list(), count=1L, index=1L) {
 cs <- terms_for(text)
 length(cs)==count && identical(cs[[index]]$kind,kind) &&
 all(vapply(names(fields),function(n) identical(cs[[index]]$extra[[n]],fields[[n]]),logical(1)))
}
same_rewrite <- function(text, expected) {
 actual <- rewrite_canonical_aliases(as.formula(paste('y ~',text)))
 identical(actual[[3]],str2lang(expected))
}
