export ALL_EDGE_TYPES, EdgeType, BallOrSocket, Ball, Socket
export opposite, Edge, edges_match

md"""

We define some number of "edge types".  If the puzzle pieces are all
square, then there is only one edge type.  If they are rectangular then
there are two edge types: one for each edge length.  Each different
shape of interlocking edge represents another edge type.

MORE PRACTICALLY THOUGH: since we don't want to match two puzzle
pieces on a flat perimeter edge, each edge on the perimeter of the
puzzle should have a different edge type.  For a 3 by 5 puzzle that
gives 16 edge types before you start defining edge types for the
internal edges.

We define `EdgeType` and create an instance for each distinct edge type.
All an `EdgeType` needs is uniqueness.  It might be handy to note if the
EdgeType represents a perimeter edge though, so we track that.

We accumulate a catalog of every EdgeType in `ALL_EDGE_TYPES`.

"""

ALL_EDGE_TYPES = []

let
    NEXT_EDGE_UID = 1
    
    struct EdgeType
        isperimeter::Bool
        uid::Int
        
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


md"""

At the edge where two puzzle pieces interlock, the edges of those
pieces are mirror images of each other.  At that meeting edge, one
piece has a *ball* and the other has a *socket*.

The edge of a puzzle piece is thus characterized by its EdgeType and
whether it is a ball or socket.

`Ball` and `Socket` are opposites.

We arbitrarily decide that a perimeter edge is always a *ball*.

"""

abstract type BallOrSocket end
struct Ball <: BallOrSocket end
struct Socket <: BallOrSocket end

opposite(::Ball) = Socket()
opposite(::Socket) = Ball()


struct Edge
    edge_type::EdgeType
    bs::BallOrSocket
end


md"""

It is easier to index things if there is a total ordering defined for
them.

`EdgeType`s can be ordered by their `uid`.

Wearbitrarily decide that `Ball` comes before `Socket`.

"""

function Base.isless(a::EdgeType, b::EdgeType)::Bool
    a.uid < b.uid
end

function Base.isless(a::BallOrSocket, b::BallOrSocket)
    false
end

function Base.isless(::Ball, ::Socket)
    true
end


md"""

Two `Edge`s match if they have the same `EdgeType` and their `bs`s are
opposites.

"""

function edges_match(e1::Edge, e2::Edge)::Bool
    (e1.edge_type == e2.edge_type) &&
        (opposite(e1.bs) == e2.bs)
end

