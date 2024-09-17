export CardinalDirection, N, E, S, W
export opposite, next, previous
export cardinal_directions_from
export do_cardinal_directions
export edge_direction

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

abstract type CardinalDirection end
struct N <: CardinalDirection end
struct E <: CardinalDirection end
struct S <: CardinalDirection end
struct W <: CardinalDirection end

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

(::N)(row, col) = [row - 1, col]
(::E)(row, col) = [row,     col + 1]
(::S)(row, col) = [row + 1, col]
(::W)(row, col) = [row,     col - 1]

#=

Which edge of a puzzle piece is facing a given `CardinalDirection`
depends on the rotation of that piece.

The rotation of a puzzle piece is represented by one of the integers
0, 1, 2, or 3, also in clockwise order.

=#

"""
    edge_direction(rotation::Int, edge_index::Int)::CardinalDirection

For the specified `edge_index` and rotation of a puzzle piece, return
the `CardinalDirection` that that edge faces.
"""
function edge_direction(piece_rotation::Int, edge_index::Int)::CardinalDirection
    @assert piece_rotation in 0:3
    direction = cardinal_directions_from(N())[mod(edge_index, Base.OneTo(4))]
    while piece_rotation > 0
        direction = previous(direction)
        piece_rotation -= 1
    end
    direction
end

