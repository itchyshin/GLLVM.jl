using Documenter
using DocumenterVitepress
using GLLVM

makedocs(;
    sitename = "GLLVM.jl",
    authors  = "Shinichi Nakagawa",
    modules  = [GLLVM],
    format   = MarkdownVitepress(
        repo      = "github.com/itchyshin/GLLVM.jl",
        devbranch = "main",
        devurl    = "dev",
    ),
    pages    = [
        "Getting Started" => [
            "Overview"        => "index.md",
            "Quick Start"     => "quickstart.md",
            "Tutorial"        => "tutorial.md",
            "Common Pitfalls" => "pitfalls.md",
        ],
        "Vignettes" => [
            "Community Abundance (JSDM)" => "vignettes/community-abundance.md",
            "Phylogenetic GLLVM"         => "vignettes/phylogenetic-gllvm.md",
            "Morphometrics"              => "morphometrics.md",
        ],
        "Guides & Methods" => [
            "Mathematical Model"       => "model.md",
            "Response Families"        => "response-families.md",
            "Working with a Fit"       => "working-with-a-fit.md",
            "Covariance & Correlation" => "covariance-correlation.md",
            "Structured Dependence"    => "structured-dependence.md",
            "Confidence Intervals"     => "confidence-intervals.md",
        ],
        "Reference & Benchmarks" => [
            "API Reference"          => "api.md",
            "Benchmarks"             => "benchmarks.md",
            "Comparison vs gllvmTMB" => "comparison.md",
            "Capability Parity"      => "gllvmtmb-parity.md",
            "Roadmap"                => "roadmap.md",
            "Changelog"              => "changelog.md",
        ],
    ],
    warnonly = true,
)

# Use DocumenterVitepress.deploydocs (NOT Documenter's): it flattens the Vitepress
# build output (build/1/*) into the version root on gh-pages and rewrites the
# site `base`. Plain Documenter.deploydocs deploys build/ verbatim, which lands
# the site under dev/1/ with base=/dev/ — every asset/nav link then 404s.
DocumenterVitepress.deploydocs(;
    repo         = "github.com/itchyshin/GLLVM.jl.git",
    target       = joinpath(@__DIR__, "build"),
    devbranch    = "main",
    branch       = "gh-pages",
    push_preview = true,
)
