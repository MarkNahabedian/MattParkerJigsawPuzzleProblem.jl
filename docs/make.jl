using MattParkerJigsawPuzzleProblem
using Documenter
using Markdown
using Literate

DocMeta.setdocmeta!(MattParkerJigsawPuzzleProblem, :DocTestSetup,
                    :(using MattParkerJigsawPuzzleProblem);
                    recursive=true)

let
    (REPO_ROOT, _) = splitdir(@__DIR__)
    for (root, _, files) in walkdir(normpath(joinpath(@__DIR__,
                                                      "..", "src")))
        for file in files
            (name, ext) = splitext(file)
            if ext == ".jl"
                abs = normpath(joinpath(root, file))
                outdir = joinpath(@__DIR__, relpath(root, REPO_ROOT))
                Literate.markdown(
                    abs, outdir;
                    execute = false,
                    codefence = "```julia" => "```")
            end
        end
    end
end


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
        "Edges" => "edges.md",
        "Grid" => "grid.md",
        "PuzzlePieces" => "puzzle_pieces.md",
        "Constructing a Puzzle" => "multiple_solutions.md",
        "Solving" => "solver.md",
        "HTML Grid" => "grid_html.md"
    ],
)

deploydocs(;
    repo="github.com/MarkNahabedian/MattParkerJigsawPuzzleProblem.jl",
    devbranch="main",
)
