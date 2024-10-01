```@meta
CurrentModule = MattParkerJigsawPuzzleProblem
```

# MattParkerJigsawPuzzleProblem

Documentation for [MattParkerJigsawPuzzleProblem](https://github.com/MarkNahabedian/MattParkerJigsawPuzzleProblem.jl).

In [this YouTube
video](https://youtu.be/b5nElEbbnfU?si=IrswVLoaAn2xw6yt) Matt Parker
asks for a program to help design and solve jigsaw puzzles.

The idea is to produce a set of jigsaw puzzle pieces where the pieces
can be assembled in more than one way, and, ideally, in exactly two
ways.

This is an attempt at that.


## Usage

Here is a simple usage example:

```@example 2by2
using MattParkerJigsawPuzzleProblem

begin
    # Degenerate example of a puzzle, 2 × 2 grid
    # with 4 possible solutions:
    puzzle = MultipleSolutionPuzzle(2, 2, 4)
    pieces = map(ImmutablePuzzlePiece, puzzle_pieces(puzzle))  
    # Find the solutions and show them in HTML:
    solver = Solver(size(puzzle), pieces)
    solve(solver)
    writing_html_file("two_by_two_example.html") do
        grids_to_html(solver.solved_grids)
    end
    length(solver.solved_grids)
end
```

See the resulting solution grids:
[two_by_two_example.html](two_by_two_example.html)

The rest of the documentation (see the menu in the corner above)
presents the theory of operation.


## Index
```@index
```

## Descriptions
```@autodocs
Modules = [MattParkerJigsawPuzzleProblem]
```
