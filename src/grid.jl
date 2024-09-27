export CardinalDirection, N, E, S, W, CARDINAL_DIRECTIONS
export opposite, next, previous
export cardinal_directions_from
export do_cardinal_directions
export rotation, GridCell
export get_edge, set_edge!, direction_for_edge
export edge_direction, Grid, new_grid, get_neighboring_edge, fit_piece

#=

Puzzle pieces are assembled into a *grid* when the puzzle is being put
together.  That grid has some number of *rows* and *columns*.  For a
given row and column the grid has a *cell* which can be
associated with the puzzle piece that belongs there.

The grid has three kinds of cells: *corner*, *edge*, and *middle*.  If
a grid has `R` rows and `C` columns, it will have `R × C` cells. No
matter the size of the grid, it will have `4` corner cells.  The
number of edge cells is `2 × (R - 2) + 2 * (C - 2)`.  The remaining
`(R - 2) × (C - 2)` cells are middle cells.

Each cell has four *neighbors*, one in each of the cardinal compass
directions.

=#

"""
    GridCell(::AbstractPuzzlePiece, rotation::Int)

A GridCell is the container for a puzzle piece in a puzzle grid.
"""
struct GridCell
    row::Int
    col::Int
    puzzle_piece
    rotation::Int

    GridCell(row, col, piece, rotation) =
        new(row, col, piece, mod(rotation, 4))
end

const Grid = Array{Union{Missing, GridCell}, 2}

"""
    new_grid(number_of_rows, number_of_columns)::Grid

Creates an empty puzzle grid of the specified dimensions.
"""
new_grid(number_of_rows, number_of_columns)::Grid =
    Grid(missing, number_of_rows, number_of_columns)


abstract type CardinalDirection end
struct N <: CardinalDirection end
struct E <: CardinalDirection end
struct S <: CardinalDirection end
struct W <: CardinalDirection end

const CARDINAL_DIRECTIONS = (N(), E(), S(), W())

#=

There are various relationships among the `CardinalDirection`s:
*opposite*, *next*, and *previous*.

=#

"""
    opposite(::CardinalDirection)::CardinalDirection

Returns the opposite direction.  `N()` and `S()` are opposites.
`E()` and `W()` are opposites.
"""
opposite(::N) = S()
opposite(::E) = W()
opposite(::S) = N()
opposite(::W) = E()

"""
    next(::CardinalDirection)::CardinalDirection

Returns the next direction clockwise from the given direction.
"""
next(::N) = E()
next(::E) = S()
next(::S) = W()
next(::W) = N()

"""
    previous(::CardinalDirection)::CardinalDirection

Returns the previous direction, that which is counter-clockwise,
from the given direction.
"""
previous(::N) = W()
previous(::E) = N()
previous(::S) = E()
previous(::W) = S()

edge_index(::N) = 1
edge_index(::E) = 2
edge_index(::S) = 3
edge_index(::W) = 4


#=

Starting from a given `CardinalDirection`, we can identify a sequence
of all of the `CardinalDirection`s in clockwise order.

=#


"""
    cardinal_directions_from(d::CardinalDirection)

Returns the four caerdinal directions, starting with `d`, in `next`
order.
"""
cardinal_directions_from(d::CardinalDirection) =
    (d, next(d), next(next(d)), next(next(next(d))))


#=

`do_cardinal_directions` allows us to easily iterate over the cardinal
directions, either clockwise or in a raandom order.

=#

"""
    do_cardinal_directions(f; randomize=false)

Applies the function `f` to each of the four `CardinalDirection`s.

If `randomize` is true then the directions are considered in random
order.
"""
function do_cardinal_directions(f; randomize=false)
    directions = cardinal_directions_from(N())
    if randomize
        directions = Random.shuffle(collect(directions))
    end
    for d in directions
        f(d)
    end
end


#=

Given the row and column indices of a grid cell, and a
`CardinalDirection`, we can compute the coordinates of the neighboring
cell in that direction.

Each instance of a `CardinalDirection` serves as an operator for going
from one pair of row/coumn indices to the neighboring ones in that
direction.  As these operators don't know the size of the grid, bounds
checking must be by their callers.done 

=#

(::N)(row::Int, col::Int) = [row - 1, col]
(::E)(row::Int, col::Int) = [row,     col + 1]
(::S)(row::Int, col::Int) = [row + 1, col]
(::W)(row::Int, col::Int) = [row,     col - 1]

#=

Which edge of a puzzle piece is facing a given `CardinalDirection`
depends on the rotation of that piece.

The rotation of a puzzle piece is represented by one of the integers
0, 1, 2, or 3, also in clockwise order.

=#

"""
    rotation(rot::Int)

Normalizes the rotation of the placement of a puzzle piece to one of
0, 1, 2, or 3.
"""
rotation(r::Int) = mod(r, 4)


ImmutablePuzzlePiece(cell::GridCell) =
    ImmutablePuzzlePiece(cell.puzzle_piece)

#=

Within a grid, a `GridCell` has a neighbor in each direction.

=#

(cd::CardinalDirection)(gc::GridCell) = cd(gc.row, gc.col)

function (cd::CardinalDirection)(grid::Grid, row::Int, col::Int)
    (r, c) = cd(row, col)
    (nrows, ncols) = size(grid)
    if !(r in 1:nrows) || !(c in 1:ncols)
        return missing
    end
    return grid[r, c]
end

(cd::CardinalDirection)(grid::Grid, cell::GridCell) =
    cd(grid, cell.row, cell.col)
     

function get_edge(gc::GridCell, direction::CardinalDirection)
    i = edge_index(edge_index(direction) + gc.rotation)
    gc.puzzle_piece.edges[i]
end

function set_edge!(gc::GridCell, direction::CardinalDirection,
                   edge::Edge)
    i = edge_index(edge_index(direction) + gc.rotation)
    gc.puzzle_piece.edges[i] = edge
end

isperimeter(cell::GridCell, direction::CardinalDirection) =
    isperimeter(get_edge(cell, direction))

function direction_for_edge(cell::GridCell, edge::Edge)
    for d in CARDINAL_DIRECTIONS
        e = get_edge(cell, d)
        if e isa Edge
            if e == edge
                return d
            end
        end
    end
    return missing
end


"""
    edge_direction(rotation::Int, index::Int)::CardinalDirection

For the specified `edge_index` and rotation of a puzzle piece, return
the `CardinalDirection` that that edge faces.
"""
function edge_direction(piece_rotation::Int, index::Int)::CardinalDirection
    @assert piece_rotation in 0:3
    direction = cardinal_directions_from(N())[edge_index(index)]
    while piece_rotation > 0
        direction = previous(direction)
        piece_rotation -= 1
    end
    direction
end


"""
    perimeter_edge_indices(grid::Grid, row::int, col::Int)

Returns a vector of the indices of edges of the specified cell of
`grid` that are perimeter edges.
"""
function perimeter_edge_indices(grid::Grid, row::Int, col::Int)
    indices = []
    (nrows, ncols) = size(grid)
    if row == 1;      push!(indices, 1); end
    if col == ncols;  push!(indices, 2); end
    if row == nrows;  push!(indices, 3); end
    if col == 1;      push!(indices, 4); end
    indices
end

"""
   get_neighboring_edge(grid::Grid, row::Int, col::Int, direction::CardinalDirection) 

Returns the `Edge` of the "neighboring cell" to the specified grid
location.  If that location is out of bounds then `Edge(EdgeType(true,
0), Straight())` is returned.  Otherwise, if there is no GridCell at
the specified location yet, then `missing` is returned.
"""
function get_neighboring_edge(grid::Grid, row::Int, col::Int,
                              direction::CardinalDirection)
    (nrows, ncols) = size(grid)
    neighbor_indices = direction(row, col)
    if (neighbor_indices[1] < 1 ||
        neighbor_indices[1] > nrows ||
        neighbor_indices[2] < 1 ||
        neighbor_indices[2] > ncols
        )
        return Edge(EdgeType(true, 0), Straight())
    else
        cell = grid[neighbor_indices...]
        if cell isa GridCell
            return get_edge(cell, opposite(direction))
        end
    end
    return missing
end


"""
    fit_piece(continuation, grid::Grid, row::Int, col::Int,
                   piece::ImmutablePuzzlePiece)

Attempts to fit `piece` into the specified location of `grid`.
`continuation` is called for each rotation of `piece` that fits.
"""
function fit_piece(continuation, grid::Grid, row::Int, col::Int,
                   piece::ImmutablePuzzlePiece)
    # If the piece fits at the specified location in grid, call
    # continuation with the rotation of the piece.
    for rot in 0:3
        for d in CARDINAL_DIRECTIONS
            piece_edge = piece.edges[edge_index(rot + edge_index(d))]
            neighbor_edge = get_neighboring_edge(grid, row, col, d)
            if ismissing(neighbor_edge)
                continue
            end
            if !edges_mate(piece_edge, neighbor_edge)
                @goto no_fit
            end
        end
        continuation(rot)
        @label no_fit
    end
end
