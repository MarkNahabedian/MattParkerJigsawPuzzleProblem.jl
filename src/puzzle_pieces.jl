
#=

A jigsaw puzzle is constructed as a two dimensional grid of *pieces*.

Each piece has four *edges*, which we can identify using the small
positive integers 1, 2, 3, and 4 (*edge indices*), which identify the
piece's edges in clockwise order.  An edge is modeled by
[`Edge`](@ref).  A puzzle piece is basically a mapping from one of the
four edge indices to an [`Edge`](@ref).

In the solution of a puzzle, each piece should have a unique location
in that grid and be in one of four rotations.

=#

"""
    AbstractPuzzlePiece

AbstractPuzzlePiece is the abstract supertype for all types of jigsaw
puzzle piece.
"""
abstract type AbstractPuzzlePiece end


"""
    piece_edge(puzzle_piece, edge_index)::Edge

Returns the [`Edge`](@ref) of `puzzle_piece` which corresponds to the
specified `edge_index`.
"""
function piece_edge(::AbstractPuzzlePiece, edge_index)::Edge
    error("piece_edge has no implementation for AbstractPuzzlePiece.")
end

