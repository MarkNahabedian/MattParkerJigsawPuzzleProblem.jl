export CardinalDirection, N, E, S, W
export SolvedPuzzlePiece, SolvedPuzzle
export neighbor_coordinates, do_cardinal_directions
export assign_perimeter_edges, assign_unique_unassigned_edges


#=

We can construct a solved puzzle of a specified size by creating
puzzle pieces that fit together into a solution.

In the solution of a puzzle, each piece has a unique location (row and
column) and one of four rotations.

Each edge of a piece, in its solved orientation, can be identified by
a cardinal compass direction: `n`, `e`, `s`, or `w`.

=#

abstract type CardinalDirection end
struct N <: CardinalDirection end
struct E <: CardinalDirection end
struct S <: CardinalDirection end
struct W <: CardinalDirection end


#=

`do_cardinal_directions` allows us to easily iterate over the cardinal
directions.

=#

"""
    do_cardinal_directions(f)

Applies the function `f` to each of the four cardinal directions.
"""
function do_cardinal_directions(f)
    for dt in subtypes(CardinalDirection)
        f(dt())
    end
end


#=

For each cardinal compass direction, there is the opposite
dirtection.

For two puzzle pieces that share a vertical edge, the piece on the
left's `E` edge will have the same `EdgeType` as that of the `W` edge
of the piece on the right.  The will have opposite `BallOrSocket`s.

=#

opposite(::N) = S()
opposite(::E) = W()
opposite(::S) = N()
opposite(::W) = E()


"""
    SolvedPuzzlePiece(row, column)

Represents the piece of a `SolvedPuzzle` at the specified `row` and
`column`.

The `edges` field is a `Dict` which maps from a `CardinalDirection`
to and [`Edge`](@ref).
"""
struct SolvedPuzzlePiece
    row::Int
    col::Int
    edges::Dict{CardinalDirection, Edge}

    function SolvedPuzzlePiece(row, col)
        new(row, col, Dict{CardinalDirection, Edge}())
    end
end


"""
    SolvedPuzzle(rows, columns)

Constructs a `SolvedPuzzle` with the specified numbers of rows and
columns.

The `grid` field is populated with `SolvedPuzzlePiece`s.
"""
struct SolvedPuzzle
    grid

    function SolvedPuzzle(rows::Int, columns::Int)
        sp = new(Array{SolvedPuzzlePiece, 2}(undef, rows, columns))
        for r in 1:rows
            for c in 1:columns
                sp.grid[r, c] = SolvedPuzzlePiece(r, c)
            end
        end
        sp
    end
end

#=

It is conventient for SolvedPuzzle to serve as an indexible surrogate
for its own grid of puzzle pieces.  We need `getindex` but not
`setindex!`.

For out ofbounds indecies we just return `nothing` rather than
throwing an error.

=#

Base.size(sp::SolvedPuzzle) = size(sp.grid)

Base.IndexStyle(sp::SolvedPuzzle) = IndexCartesian()

function Base.getindex(sp::SolvedPuzzle, row::Int, col::Int)
    (rows, cols) = size(sp)
    if row < 1 || row > rows || col < 1 || col > cols
        return nothing
    end
    sp.grid[row, col]
end


neighbor_coordinates(spp::SolvedPuzzlePiece, ::N) = [spp.row - 1, spp.col]
neighbor_coordinates(spp::SolvedPuzzlePiece, ::E) = [spp.row, spp.col + 1]
neighbor_coordinates(spp::SolvedPuzzlePiece, ::S) = [spp.row + 1, spp.col]
neighbor_coordinates(spp::SolvedPuzzlePiece, ::W) = [spp.row, spp.col - 1]


"""
    assign_perimeter_edges(SolvedPuzzle)::SolvedPuzzle

Assigns a unique [`EdgeType`](@ref) to the perimeter edge of each of
the perimeter puzzle pieces.

The `SolvedPuzzle` is returned.
"""
function assign_perimeter_edges(sp::SolvedPuzzle)::SolvedPuzzle
    (rows, cols) = size(sp)
    for r in 1:rows
        ## Top and bottom edges:
        sp.grid[r, 1].edges[W()] = Edge(EdgeType(true), Ball())
        sp.grid[r, cols].edges[E()] = Edge(EdgeType(true), Ball())
    end
    for c in 1:cols
        ## Left and right edges:
        sp.grid[1, c].edges[N()] = Edge(EdgeType(true), Ball())
        sp.grid[rows, c].edges[S()] = Edge(EdgeType(true), Ball())
    end
    sp
end


"""
    assign_unique_unassigned_edges(sp::SolvedPuzzle)::SolvedPuzzle

Assigns an [`EdgeType`](@ref)] to each of the *internal* edges of the
puzzle.

The `SolvedPuzzle` is returned.
"""
function assign_unique_unassigned_edges(sp::SolvedPuzzle)::SolvedPuzzle
    (rows, cols) = size(sp)
    for r in 1:rows
        for c in 1:cols
            do_cardinal_directions() do direction
                piece = sp[r, c]
                if !haskey(piece.edges, direction)
                    ## Edge not yet assigned
                    new_edge_type = EdgeType(false)
                    neignbor =
                        sp[neighbor_coordinates(piece, direction)...]
                    ## Maybe we should randomize which BallOrSocket to
                    ## use, but why bother?
                    piece.edges[direction] = Edge(new_edge_type, Ball())
                    if neignbor != nothing
                        neignbor.edges[opposite(direction)] =
                            Edge(new_edge_type, Socket())
                    end
                end
            end
        end
    end
    sp
end

