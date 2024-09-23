
using Printf

export terserep

#=

To help with debugging, we define a more terse representation of
edges, puzzle pieces and grids.

=#

terserep(et::EdgeType) = @sprintf("%d", et.uid)

terserep(::Ball) = "b"
terserep(::Socket) = "s"

terserep(edge::Edge) =
    @sprintf("%s%s",
             terserep(edge.edge_type),
             if edge.edge_type.isperimeter
                 "_"
             else
                 terserep(edge.bs)
             end)

terserep(piece::AbstractPuzzlePiece) =
    join(terserep.(piece.edges), "/")

terserep(cell::GridCell) =
    join(terserep.([ get_edge(cell, direction)
                     for direction in CARDINAL_DIRECTIONS ]),
         "/")

