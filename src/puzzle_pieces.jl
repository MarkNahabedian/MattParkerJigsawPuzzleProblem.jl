export edge_index
export AbstractPuzzlePiece, perimeter_edge_indices
export MutablePuzzlePiece, ImmutablePuzzlePiece
export mating_piece_indices

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

edge(piece::AbstractPuzzlePiece, index::Int) =
    piece.edges[edge_index(index)]


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


#=

Once a puzzle is fully defined, we want to make the pieces immutable.
We can make an [`ImmutablePuzzlePiece`](@ref) for each piece of the
newly constructed puzzle.

Since we have defined a total ordering for `Edge`s, we can identify a
puzzle piece by an ordered sequence of its most `isless` edge and the
remaining three edges clockwise from it.

=#

function find_least_edge(piece::MutablePuzzlePiece)
    index_of_least = 1
    for i in 1:4
        if edge(piece, i) < edge(piece, index_of_least)
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

    # Constructor for testing
    function ImmutablePuzzlePiece(edges::Vector{Edge})
        @assert length(edges) == 4
        new(sort(edges))
    end

    function ImmutablePuzzlePiece(from::MutablePuzzlePiece)
        @assert length(from.edges) == 4
        @assert all(e -> e isa Edge, from.edges)
        least = find_least_edge(from)
        new(tuple(map(i -> edge(from, edge_index(i)),
                      least : (least + 3))...))
    end
end

function Base.isless(piece1::ImmutablePuzzlePiece,
                     piece2::ImmutablePuzzlePiece)
    function test_index(i)
        if i > 4
            return false
        end
        if isless(piece1.edges[i],
                  piece2.edges[i])
            true
        elseif piece1.edges[i] == piece2.edges[i]
            test_index(i + 1)
        else
            false
        end
    end
    test_index(1)
end


"""
    mating_piece_indices(continuation, piece1::ImmutablePuzzlePiece, piece1::ImmutablePuzzlePiece) 

for each `Edge` of `piece1` that mates with an `Edge` of `piece2,
Calls `continuation, on the indices into those two pieces of those
mating edges.
"""
function mating_piece_indices(continuation,
                              piece1::ImmutablePuzzlePiece,
                              piece2::ImmutablePuzzlePiece)
    for idx1 in 1:4
        for idx2 in 1:4
            if edges_mate(edge(piece1, idx1),
                          edge(piece2, idx2))
                # Check for borders:
                if (edge(piece1, idx1 - 1).edge_type.isperimeter) &&
                    !(edge(piece2, idx2 + 1).edge_type.isperimeter)
                    continue
                end
                if (edge(piece1, idx1 + 1).edge_type.isperimeter) &&
                    !(edge(piece2, idx2 - 1).edge_type.isperimeter)
                    continue
                end
                continuation(idx1, idx2)
            end
        end
    end
end

