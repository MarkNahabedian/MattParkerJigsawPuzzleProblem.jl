
export edge_index_key, make_edge_index
export PuzzlePieceIncidenceGraph
export find_incidence_graph_connections
export Solver, add_one_piece, solve

#=

For the pieces of a puzzle, we can produce an index mapping from
[`EdgeType`](@ref) and [`BallOrSocket`](@ref) to the puzzle peices
having that `EdgeType` and `BallOrSocket` as an edge.

=#

const EdgeIndexKey = Tuple{EdgeType, <:BallOrSocket}

Base.isless(k1::EdgeIndexKey, k2::EdgeIndexKey) =
    isless(k1[1], k2[1]) ||
    (k1[1] == k2[1] && isless(k1[2], k2[2]))

const EdgeIndex = SortedDict{EdgeIndexKey,
                             Vector{ImmutablePuzzlePiece}}

edge_index_key(edge::Edge) = (edge.edge_type, edge.bs)

function make_edge_index(pieces::Vector{ImmutablePuzzlePiece})
    edge_index = SortedDict{EdgeIndexKey,
                            Vector{ImmutablePuzzlePiece}}()
    for piece in pieces
        for edge in piece.edges
            key = edge_index_key(edge)
            if !haskey(edge_index, key)
                edge_index[key] = ImmutablePuzzlePiece[]
            end
            push!(edge_index[key], piece)
        end
    end
    edge_index
end

#=

To solve a puzzle, first we build an incidence graph where both axes
are indexed by ImmutablePuzzlePiece.  That graph is represented by a
square array.

=#

struct PuzzlePieceIncidenceGraph
    pieces::Vector{ImmutablePuzzlePiece}
    incidence_graph

    function PuzzlePieceIncidenceGraph(pieces)
        l = length(pieces)
        graph = new(pieces,
                    Array{Any, 2}(missing, l, l))
        for i in 1:l
            for j in 1:l
                graph.incidence_graph[i, j] = Tuple{Int64, Int64}[]
            end
        end
        edge_index = make_edge_index(pieces)
        for piece in pieces
            for edge in piece.edges
                if edge.bs isa Ball
                    if !edge.edge_type.isperimeter
                        for other in edge_index[(edge.edge_type,
                                                 opposite(edge.bs))]
                            if other == piece
                                continue
                            end
                            mating_piece_indices(piece, other) do idx1, idx2
                                push!(graph[piece, other],
                                      (idx1, idx2))
                            end
                        end
                    end
                end
            end
        end
        graph
    end
end

function Base.getindex(g::PuzzlePieceIncidenceGraph,
                       p1::ImmutablePuzzlePiece,
                       p2::ImmutablePuzzlePiece)
    r = findfirst(==(p1), g.pieces)
    c = findfirst(==(p2), g.pieces)
    g.incidence_graph[r, c]
end

function Base.setindex!(g::PuzzlePieceIncidenceGraph,
                        new_value,
                        p1::ImmutablePuzzlePiece,
                       p2::ImmutablePuzzlePiece)
    r = findfirst(==(p1), g.pieces)
    c = findfirst(==(p2), g.pieces)
    g.incidence_graph[r, c] = new_value
end                        


function find_incidence_graph_connections(graph::PuzzlePieceIncidenceGraph)
    arcs = []
    l = first(size(graph.incidence_graph))
    for b in 1:l
        for s in 1:l
            for arc in graph.incidence_graph[b, s]
                push!(arcs, (graph.pieces[b], arc[1],
                             graph.pieces[s], arc[2]))
            end
        end
    end
    arcs
end


#=

For each possible solution, we assemble the puzzle pieces into a grid.
That grid is square, and of the larger dimension of the originally
generated puzzle.

=#

PuzzleSolutionGrid(size::Int) = Grid(missing, size, size)

function PuzzleSolutionGrid(grid::Grid)
    ## Make a new grid that is a copy of grid.
    l = first(size(grid))
    new_grid = PuzzleSolutionGrid(l)
    for r in 1:l
        for c in 1:l
            new_grid[r, c] = grid[r, c]
        end
    end
    new_grid
end
    

struct Solver
    size::Int
    all_pieces::Vector{ImmutablePuzzlePiece}
    edge_index::EdgeIndex
    incidence_graph::PuzzlePieceIncidenceGraph
    working_grids::Vector{Grid}
    solved_grids::Vector{Grid}

    function Solver(puzzle_size,
                    pieces::Vector{ImmutablePuzzlePiece})
        pieces = sort(pieces)
        size = max(puzzle_size...)
        edge_index = make_edge_index(pieces)
        incidence_graph = PuzzlePieceIncidenceGraph(pieces)
        solver = new(size, pieces, edge_index, incidence_graph,
                     Vector{Grid}(),
                     Vector{Grid}())
        # Seed the first grid with a corner
        push!(solver.working_grids,
              let
                  grid = new_grid(solver)
                  corner = pieces[1]
                  @assert sum(isperimeter, corner.edges) >= 2
                  grid[1, 1] = GridCell(1, 1, corner, 0)
                  grid
              end)
        solver
    end
end

new_grid(solver::Solver) = Grid(missing, solver.size, solver.size)

function finish_grid(solver::Solver, grid::Grid, issolved::Bool)
    if issolved
        push!(solver.solved_grids, grid)
    end
    deleteat!(solver.working_grids,
              findall(g -> g === grid, solver.working_grids))
    solver
end


function find_next_empty(grid)
    (nrows, ncols) = size(grid)
    for r in 1:nrows
        for c in 1:ncols
            cell = grid[r, c]
            if cell isa GridCell
                ## We can trust that the edges aren't missing because
                ## Solver only deals with completed
                ## ImmutablePuzzlePiees.
                if get_edge(cell, E()).edge_type.isperimeter
                    if get_edge(cell, S()).edge_type.isperimeter
                        return nothing
                    end
                    continue
                end
            else
                return (r, c)
            end
        end
    end
    nothing
end


"""
    add_one_piece(solver::Solver, grid::Grid)

Looks for a piece to fit into the grid.  If there is more than one
mating piece then additional grids are created for them.
"""
function add_one_piece(solver::Solver, grid::Grid)
    next_empty_index = find_next_empty(grid)
    if next_empty_index === nothing
        finish_grid(solver, grid, true)
        return
    end
    next_empty_index = Tuple(next_empty_index)
    ## Find a neighboring puzzle piece:
    (neighbor, candidates) =
        let
            neighbor = nothing
            candidates = nothing
            for d in CARDINAL_DIRECTIONS
                neighbor = d(grid, next_empty_index...)
                if neighbor isa GridCell
                    candidates = solver.edge_index[
                        edge_index_key(opposite(get_edge(neighbor, opposite(d))))]
                    break
                end
            end
            (neighbor, candidates)
        end
    @assert neighbor isa GridCell
    @assert candidates != nothing
    fits = 0
    for c in candidates
        ## Have we already used c in the puzzle?
        if c in filter(cell -> (cell isa GridCell
                                && c == cell.puzzle_piece),
                       grid)
            continue
        end
        (row, col) = next_empty_index
        fit_piece(grid, row, col, c) do rot
            ## candidate fits with the given rotation
            fits += 1
            ## If we've already put a piece in this location of this
            ## grid then add a new grid:
            if !ismissing(grid[next_empty_index...])
                grid = copy(grid)
                push!(solver.working_grids, grid)
            end
            grid[row, col] = GridCell(row, col, c, rot)
        end
    end
    if fits == 0
        ## We were not able too add a piece to this grid.  Don't do
        ## any more work on it.
        finish_grid(solver, grid, false)
    end
    return
end

function solve(solver::Solver)
    while !isempty(solver.working_grids)
        add_one_piece(solver, first(solver.working_grids))
    end
end

function unused_pieces(grid::Grid, solver::Solver)
    pieces_in_grid = map(grid) do cell
        if cell isa GridCell
            cell.puzzle_piece
        end
    end
    unused = []
    for piece in solver.all_pieces
        if !(piece in pieces_in_grid)
            push!(unused, piece)
        end
    end
    unused
end
    
