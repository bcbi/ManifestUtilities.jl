using ManifestUtilities
using Documenter

DocMeta.setdocmeta!(ManifestUtilities, :DocTestSetup, :(using ManifestUtilities); recursive=true)

makedocs(;
    modules=[ManifestUtilities],
    authors="Dilum Aluthge and contributors",
    repo="https://github.com/bcbi/ManifestUtilities.jl/blob/{commit}{path}#{line}",
    sitename="ManifestUtilities.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://bcbi.github.io/ManifestUtilities.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    strict=true,
)

deploydocs(;
    repo="github.com/bcbi/ManifestUtilities.jl",
    devbranch="main",
)
