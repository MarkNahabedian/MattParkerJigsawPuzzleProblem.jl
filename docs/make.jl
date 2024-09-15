using MattParkerJigsawPuzzleProblem
using Documenter

DocMeta.setdocmeta!(MattParkerJigsawPuzzleProblem, :DocTestSetup, :(using MattParkerJigsawPuzzleProblem); recursive=true)

makedocs(;
    modules=[MattParkerJigsawPuzzleProblem],
    authors="MarkNahabedian <naha@mit.edu> and contributors",
    sitename="MattParkerJigsawPuzzleProblem.jl",
    format=Documenter.HTML(;
        canonical="https://MarkNahabedian.github.io/MattParkerJigsawPuzzleProblem.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/MarkNahabedian/MattParkerJigsawPuzzleProblem.jl",
    devbranch="main",
)
