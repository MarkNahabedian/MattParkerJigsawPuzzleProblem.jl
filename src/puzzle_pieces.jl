export edge_index
export AbstractPuzzlePiece, perimeter_edge_indices
export MutablePuzzlePiece, ImmutablePuzzlePiece

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
    edge_index(::Int)::Int

Turns the argument value into a valid edge index using the modulus
operator.  This allows us to use aritmetic on edge indices and still
get a valid index.
"""
edge_index(i::Int) = mod(i, Base.OneTo(4))


"""
    AbstractPuzzlePiece

AbstractPuzzlePiece is the abstract supertype for all types of jigsaw
puzzle piece.
"""
abstract type AbstractPuzzlePiece end


"""
    perimeter_edge_indices(p::AbstractPuzzlePiece)

Returns a vector of the indices of edges of the puzzle piece `p` that
are perimeter edges.
"""
function perimeter_edge_indices(p::AbstractPuzzlePiece)
    indices = []
    for i in 1:length(p.edges)
        if !ismissing(p.edges[i])
            if p.edges[i].edge_type.isperimeter
                push!(indices, i)
            end
        end
    end
    indices
end


"""
    piece_edge(puzzle_piece, index)::Edge

Returns the [`Edge`](@ref) of `puzzle_piece` which corresponds to the
specified `edge_index`.
"""
function piece_edge(::AbstractPuzzlePiece, index)::Edge
    error("piece_edge has no implementation for AbstractPuzzlePiece.")
end


#=

When constructing a solved puzzle, it is helpful to fill the grid with
puzzle pieces and then assign edges to those pieces to construct a
solved puzzle.

`MutablePuzzlePiece` is a type piece where the edges can be set.

=#

"""
    MutablePuzzlePiece()

Constructs a `MutablePuzzlePiece` with no edges defined yet.
"""
struct MutablePuzzlePiece <: AbstractPuzzlePiece
    edges

    MutablePuzzlePiece() =
        new(Vector{Union{Missing, Edge}}(missing, 4))
end

edge(pp::MutablePuzzlePiece, index::Int) =
    mp.edges[edge_index(index)]


#=

Once puzzle is fully defined, we want to make the pieces immutable.
We can make an [`ImmutablePuzzlePiece`](@ref) for each piece of the
newly constructed puzzle.

Since we have defined a total ordering for `Edge`s, we can identify a
puzzle piece by an ordered sequence of its most `isless` edge and the
remaining three edges clockwise from it.

=#

function find_least_edge(pp::MutablePuzzlePiece)
    index_of_least = 1
    for i in 1:4
        if edge(mp, i) < edge(mp, index_of_least)
            index_of_least = i
        end
    end
    index_of_least
end


"""
    ImmutablePuzzlePiece(from::MutablePuzzlePiece)

Constructs an `ImmutablePuzzlePiece` from a `MutablePuzzlePiece`.
"""
struct ImmutablePuzzlePiece <: AbstractPuzzlePiece
    edges

    function ImmutablePuzzlePiece(from::MutablePuzzlePiece)
        @assert length(from.edges) == 4
        @assert all(e -> e isa Edge, from.edges)
        least = index_of_least(from)
        new(tuple(map(i -> edge(from, edge_index(i)),
                      least : (least + 3))))
    end
end

