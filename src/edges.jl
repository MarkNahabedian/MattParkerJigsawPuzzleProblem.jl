export ALL_EDGE_TYPES, EdgeType
export BallOrSocket, Ball, Socket, Straight
export opposite, Edge, isperimeter, edges_mate

#=

We define some number of "edge types".  If the puzzle pieces are all
square, then there is only one edge type.  If they are rectangular then
there are two edge types: one for each edge length.  Each different
shape of interlocking edge represents another edge type.

MORE PRACTICALLY THOUGH: since we don't want to match two puzzle
pieces on a flat perimeter edge, each edge on the perimeter of the
puzzle should have a different edge type.  For a 3 by 5 puzzle, that
gives 16 edge types before you start defining edge types for the
internal edges.

We define `EdgeType` and create an instance for each distinct edge type.
All an `EdgeType` needs is uniqueness.  It might be handy to note if the
EdgeType represents a perimeter edge though, so we track that.

We accumulate a catalog of every EdgeType in `ALL_EDGE_TYPES`.

=#

"""
    ALL_EDGE_TYPES

`ALL_EDGE_TYPES` is a vector of all of the `EdgeType`s that have been
created.
"""
ALL_EDGE_TYPES = []

let
    NEXT_EDGE_UID = 1
    
    struct EdgeType
        isperimeter::Bool
        uid::Int
        
        ## For testing:
        EdgeType(isperimeter, uid) = new(isperimeter, uid)

        function EdgeType(isperimeter)
            et = new(isperimeter,
                     let
                         uid = NEXT_EDGE_UID
                         NEXT_EDGE_UID += 1
                         uid
                     end)
            push!(ALL_EDGE_TYPES, et)
            return et
        end
    end
end

@doc """
    EdgeType(isperimeter::Bool)

Creates a unique `EdgeType`.

`isperimeter` indicates if the EdgeType is for an edge on the
perimeter of the puzzle.
""" EdgeType


isperimeter(e::EdgeType) = e.isperimeter

#=

At the edge where two puzzle pieces interlock, the edges of those
pieces are mirror images of each other.  At that meeting edge, one
piece has a *ball* and the other has a *socket*.  If the edge is at
the border of the puzzle then it is straight.

The edge of a puzzle piece is thus characterized by its EdgeType and
whether it is a ball, socket, or straight.

`Ball` and `Socket` are opposites.

`Straight` is its own opposite.

=#

"""
    BallOrSocket
    Ball
    Socket
    Straight
"""
abstract type BallOrSocket end
struct Ball <: BallOrSocket end
struct Socket <: BallOrSocket end
struct Straight <: BallOrSocket end

opposite(::Ball) = Socket()
opposite(::Socket) = Ball()
opposite(::Straight) = Straight()


"""
    Edge(::EdgeType, ::BallOrSocket)

`Edge` represents one edge of a puzzle piece.  It has an `edge_type`.
The `bs` field indicates whether the edge is a *ball* or *socket*.

"""
struct Edge
    edge_type::EdgeType
    bs::BallOrSocket
end

isperimeter(e::Edge) = isperimeter(e.edge_type)
isperimeter(::Missing) = false

opposite(edge::Edge) = Edge(edge.edge_type, opposite(edge.bs))


#=

It is easier to index things if there is a total ordering defined for
them.

`EdgeType`s can be ordered by their `uid`.

We arbitrarily decide that `Ball` comes before `Socket`.

We can then define a total ordering on `Edge`s.

=#

function Base.isless(a::EdgeType, b::EdgeType)::Bool
    a.uid < b.uid
end

Base.isless(::BallOrSocket, ::BallOrSocket) = false
Base.isless(::Ball, ::Socket) = true
Base.isless(::Ball, ::Straight) = true
Base.isless(::Socket, ::Straight) = true

function Base.isless(a::Edge, b::Edge)
    (isless(a.edge_type, b.edge_type) ||
        (a.edge_type == b.edge_type &&
        isless(a.bs, b.bs)))
end


#=

Two `Edge`s match if they have the same `EdgeType` and their `bs`s are
opposites.

=#

"""
    edges_mate(::Edge, ::Edge)::Bool

Two `Edge`s mate if they have the same `EdgeType` and their `bs`s are
opposites.
"""
function edges_mate(e1::Edge, e2::Edge)::Bool
    ## For perimeter edges the EdgeType doesn't matter:
    (e1.bs == e2.bs == Straight()) ||
        ((e1.edge_type == e2.edge_type) &&
        (opposite(e1.bs) == e2.bs))
end

