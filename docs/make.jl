using Documenter
using DocumenterVitepress
using GLLVM

makedocs(;
    root = @__DIR__,
    remotes = "--local" in ARGS ? nothing : Dict(),
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
            "Tweedie Power"            => "tweedie-power.md",
            "Student-t Parity Limits"  => "studentt-parity.md",
            "Working with a Fit"       => "working-with-a-fit.md",
            "Covariance & Correlation" => "covariance-correlation.md",
            "Structured Dependence"    => "structured-dependence.md",
            "Structured-Term Fitting"  => "structured-term-fitting.md",
            "Confidence Intervals"     => "confidence-intervals.md",
            "Derived Confidence Intervals" => "derived-confidence-intervals.md",
        ],
        "Reference & Benchmarks" => [
            "API Reference"                  => "api.md",
            "Post-Fit Extractors"            => "postfit-extractors.md",
            "Post-Fit Tables & Prediction"   => "postfit-tables.md",
            "Diagnostics & Model Comparison" => "diagnostics.md",
            "SE & Profile Machinery"         => "se-profile-machinery.md",
            "Low-level Reference"    => "low-level-reference.md",
            "Benchmarks"             => "benchmarks.md",
            "Comparison vs gllvmTMB" => "comparison.md",
            "Capability Parity"      => "gllvmtmb-parity.md",
            "Roadmap"                => "roadmap.md",
            "Changelog"              => "changelog.md",
        ],
    ],
    warnonly = false,
)

# A standalone local preview still requests this script from the version picker.
# Deployment supplies its own version index; do not write one for deployed builds.
if "--local" in ARGS
    local_sites = filter(path -> isdir(path) && isfile(joinpath(path, "index.html")),
                         readdir(joinpath(@__DIR__, "build"); join=true))
    isempty(local_sites) && error("No rendered local documentation site found")
    for site in local_sites
        write(joinpath(site, "versions.js"), "var DOC_VERSIONS = [\"dev\"];\n")
    end
end

# Use DocumenterVitepress.deploydocs (NOT Documenter's): it flattens the Vitepress
# build output (build/1/*) into the version root on gh-pages and rewrites the
# site `base`. Plain Documenter.deploydocs deploys build/ verbatim, which lands
# the site under dev/1/ with base=/dev/ — every asset/nav link then 404s.
if !("--local" in ARGS)
    DocumenterVitepress.deploydocs(;
    repo         = "github.com/itchyshin/GLLVM.jl.git",
    target       = joinpath(@__DIR__, "build"),
    devbranch    = "main",
    branch       = "gh-pages",
    push_preview = true,
    )
end # --local builds never call deploydocs
