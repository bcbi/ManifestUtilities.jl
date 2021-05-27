using ManifestStuff
using Documenter

DocMeta.setdocmeta!(ManifestStuff, :DocTestSetup, :(using ManifestStuff); recursive=true)

makedocs(;
    modules=[ManifestStuff],
    authors="Dilum Aluthge, contributors",
    repo="https://github.com/bcbi/ManifestStuff.jl/blob/{commit}{path}#{line}",
    sitename="ManifestStuff.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://bcbi.github.io/ManifestStuff.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/bcbi/ManifestStuff.jl",
)
