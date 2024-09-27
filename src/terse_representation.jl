
using Printf

export terserep

#=

To help with debugging, we define a more terse representation of
edges, puzzle pieces and grids.

=#


terserep(et::EdgeType) = @sprintf("%d", et.uid)

terserep(::Ball) = "b"
terserep(::Socket) = "s"
terserep(::Straight) = "_"

terserep(::Nothing) = "?"

terserep(edge::Edge) =
    @sprintf("%s%s",
             terserep(edge.edge_type),
             terserep(edge.bs))

terserep(piece::AbstractPuzzlePiece) =
    join(terserep.(piece.edges), "/")

terserep(cell::GridCell) =
    join(terserep.([ get_edge(cell, direction)
                     for direction in CARDINAL_DIRECTIONS ]),
         "/")

terserep(::Missing) = "#"

function terserep(grid::Grid)
    (nrows, ncols) = size(grid)
    for r in 1:nrows
        for c in 1:ncols
            print(terserep(grid[r, c]), "\t")
        end
        println()
    end
end



"""
    terserep(puzzle)

Output a terse printed representation of the puzzle.
"""
function terserep(puzzle::MultipleSolutionPuzzle)
    for grid in puzzle.grids
        terserep(grid)
        println()
    end
end

