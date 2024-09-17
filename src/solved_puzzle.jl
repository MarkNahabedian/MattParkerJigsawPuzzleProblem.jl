export SolvedPuzzlePiece, SolvedPuzzle
export assign_perimeter_edges, assign_unique_unassigned_edges

#=

We can construct a solved puzzle of a specified size by creating
puzzle pieces that fit together into a solution.

In the solution of a puzzle, each piece has a unique location (row and
column) and one of four rotations.

Each edge of a piece, in its solved orientation, can be identified by
a cardinal compass direction: `n`, `e`, `s`, or `w`.

=#


#=

For two puzzle pieces that share a vertical edge, the piece on the
left's `E` edge will have the same `EdgeType` as that of the `W` edge
of the piece on the right.  They will have opposite `BallOrSocket`s.

=#


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


#=
We randomize the order of the EdgeTypes so they don't hint at
the solution.
=#

"""
    random_edge_types(count, is_perimeter)

Create the specified number of unique [`EdgeType`](@ref)s 
and returns them in a random order.
"""
function random_edge_types(count, is_perimeter)
    edge_types = []
    for _ in 1:count
        push!(edge_types, EdgeType(is_perimeter))
    end
    shuffle(edge_types)
end


"""
    assign_perimeter_edges(SolvedPuzzle)::SolvedPuzzle

Assigns a unique [`EdgeType`](@ref) to the perimeter edge of each of
the perimeter puzzle pieces.

The `SolvedPuzzle` is returned.
"""
function assign_perimeter_edges(sp::SolvedPuzzle)::SolvedPuzzle
    (rows, cols) = size(sp)
    ## We randomize the order of the EdgeTypes so they don't hint at
    ## the solution.
    edge_types = random_edge_types(2 * rows + 2 * cols, true)
    for r in 1:rows
        ## Top and bottom edges:
        sp.grid[r, 1].edges[W()] = Edge(pop!(edge_types), Ball())
        sp.grid[r, cols].edges[E()] = Edge(pop!(edge_types), Ball())
    end
    for c in 1:cols
        ## Left and right edges:
        sp.grid[1, c].edges[N()] = Edge(pop!(edge_types), Ball())
        sp.grid[rows, c].edges[S()] = Edge(pop!(edge_types), Ball())
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
    # It's ok to create too many EdgeTypes, they're cheap:
    edge_types = random_edge_types(4 * rows * cols / 2, false)
    for r in 1:rows
        for c in 1:cols
            do_cardinal_directions(; randomize=true) do direction
                piece = sp[r, c]
                if !haskey(piece.edges, direction)
                    ## Edge not yet assigned
                    new_edge_type = pop!(edge_types)
                    neignbor =
                        sp[direction(piece.row, piece.col)...]
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

