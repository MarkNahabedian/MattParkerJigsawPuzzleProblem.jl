export MultipleSolutionPuzzle, perimeters, puzzle_pieces

#=

Matt Parker's YouTube video is about jigsaw puzzles that have more
than one solution.  Here we attempt to construct such a puzzle by
makiing one grid for each solution and placiing the same set of
[`MutablePuzzlePiece`](@ref)s, with different locations and
orientations, in each grid.

=#

"""
    MultipleSolutionPuzzle(number_of_rows, number_of_columns, number_of_grids)

MultipleSolutionPuzzle is used to generate jigsaw puzzles with the
specified numnber of rows and colukmns.  It will attempy to generate
`number_of_grids` puzzles with the same pieces.  The pieces that are
generated can be assembled least that number of of different ways.
One must run the solver to see how many ways the pieces can actually
be assembled.

Use [`puzzle_pieces`](@ref) to get the pieces.
"""
struct MultipleSolutionPuzzle
    grids

    ## It's simpler to populate the first grid with Pieces that have
    ## no edges yet, add the perimeter edges and then permute them for
    ## the other grids.
    function MultipleSolutionPuzzle(number_of_rows, number_of_columns,
                                    number_of_grids)
        puzzle = new(map(_ -> new_grid(number_of_rows, number_of_columns),
                         1:number_of_grids))
        ## Populate the first grid and set its perimeter edges:
        grid1 = puzzle.grids[1]
        corners = []
        edges = []
        middle = []
        for r in 1:number_of_rows
            for c in 1:number_of_columns
                piece = MutablePuzzlePiece()
                cell = GridCell(r, c, piece, rand(0:3))
                grid1[r, c] = cell
                perimeter_count = 0
                if r == 1
                    set_edge!(cell, N(), Edge(EdgeType(true), Straight()))
                    perimeter_count += 1
                elseif r == number_of_rows
                    set_edge!(cell, S(), Edge(EdgeType(true), Straight()))
                    perimeter_count += 1
                end
                if c == 1
                    set_edge!(cell, W(), Edge(EdgeType(true), Straight()))
                    perimeter_count += 1
                elseif c == number_of_columns
                    set_edge!(cell, E(), Edge(EdgeType(true), Straight()))
                    perimeter_count += 1
                end
                if perimeter_count == 2
                    push!(corners, piece)
                elseif perimeter_count == 1
                    push!(edges, piece)
                elseif perimeter_count == 0
                    push!(middle, piece)
                else
                    error("Puzzle is too small")
                end
            end
        end
        ## Once we permute the corner or edge pieces of a puzzle for
        ## other grids, they won't end up in the same locations so
        ## might need to be rotated of thealternate locations.
        ## Compute the rotation for the cell such that the perimeter
        ## edges of the piece match those of the cell.
        function cell_rotation(row, col, piece::MutablePuzzlePiece)
            count_perimeters(pmtrs) = sum(p -> p == true, pmtrs)
            cell_perimeters = perimeters(puzzle, row, col)
            for rot in 0:3
                piece_perimeters =
                    [ isperimeter(piece.edges[i])
                      for i in edge_index.((1:4) .+ rot) ]
                @assert count_perimeters(cell_perimeters) ==
                    count_perimeters(piece_perimeters)
                if cell_perimeters == piece_perimeters
                    return rot
                end
            end
            @assert false "Can't determine piece rotation."
        end
        ## Populate the remaining grids with permutations of the
        ## pieces from grid1:
        for i in 2:number_of_grids
            grid = puzzle.grids[i]
            permuted_corners = Random.shuffle(corners)
            permuted_edges = Random.shuffle(edges)
            permuted_middle = Random.shuffle(middle)
            for r in 1:number_of_rows
                for c in 1:number_of_columns
                    if r in [1, number_of_rows] && c in [1, number_of_columns]
                        piece = pop!(permuted_corners)
                    elseif (r in [1, number_of_rows] ||
                        c in [1, number_of_columns])
                        piece = pop!(permuted_edges)
                    else
                        piece = pop!(permuted_middle)
                    end
                    rotation = cell_rotation(r, c, piece)
                    grid[r, c] = GridCell(r, c, piece, rotation)
                end
            end
        end
        ## Make sure every piece is in every grid exactly once:
        let
            all_pieces = Set([corners..., edges..., middle...])
            for grid in puzzle.grids
                grid_pieces = Set()
                for cell in grid
                    push!(grid_pieces, grid[r, c].puzzle_piece)
                end
                @assert all_pieces == grid_pieces
            end
        end
        # Assign edges to every puzzle piece
        function propagate_edge(edge::Edge, piece::MutablePuzzlePiece)
            ## edge is the one that was just set in piece.
            ## Propagate to the neighboring piece in each grid.
            for gridi in 1:length(puzzle.grids)
                grid = puzzle.grids[gridi]
                cell = grid[findfirst(grid) do cell
                                cell.puzzle_piece == piece
                            end]
                direction = direction_for_edge(cell, edge)
                neighbor = direction(grid, cell)
                @assert isa(neighbor, GridCell)
                neighbor_edge = get_edge(neighbor, opposite(direction))
                if !isa(neighbor_edge, Edge)
                    neighbor_edge = opposite(edge)
                    set_edge!(neighbor, opposite(direction),
                              neighbor_edge)
                    propagate_edge(neighbor_edge, neighbor.puzzle_piece)
                else
                    ## Neighbor already has an Edge facing us, so make
                    ## sure it matches:
                    if !edges_mate(edge, neighbor_edge)
                        writing_html_file("edges_do_not_mate.html") do
                            grids_to_html(puzzle.grids)
                        end
                        error("Edges don't mate: $gridi $cell\n$edge\n$neighbor_edge\n")
                    end
                end
            end
        end
        ## Fill in the missing edges of grid1 and propagate the new
        ## edges:
        for r in 1:number_of_rows
            for c in 1:number_of_columns
                for direction in CARDINAL_DIRECTIONS
                    cell = grid1[r, c]
                    if ismissing(get_edge(cell, direction))
                        new_edge = Edge(EdgeType(false),
                                        (Ball(), Socket())[rand(1:2)])
                        set_edge!(cell, direction, new_edge)
                        propagate_edge(new_edge, cell.puzzle_piece)
                    end
                end
            end
        end
        ## Make sure every cell has a puzzle piece with all four edges:
        for g in 1:length(puzzle.grids)
            grid = puzzle.grids[g]
            for r in 1:number_of_rows
                for c in 1:number_of_columns
                    cell = grid[r, c]
                    @assert(cell.puzzle_piece isa MutablePuzzlePiece,
                            "grid $g, cell $r $c is not a puzzle piece")
                    for direction in CARDINAL_DIRECTIONS
                        @assert(!ismissing(get_edge(cell, direction)),
                                "grid, $g cell $r $c has no edge for $direction")
                    end
                end
            end
        end
        puzzle
    end
end


Base.size(puzzle::MultipleSolutionPuzzle) = size(puzzle.grids[1])


"""
    perimeters(puzzle::MultipleSolutionPuzzle, row::Int, col::Int)

Returns a four element vector indicating for each direction (N, E, S,
W) whether that side of the cell at `row`, `col` is a perimeter of the
puzzle.
"""
function perimeters(puzzle::MultipleSolutionPuzzle, row::Int, col::Int)
    (nrows, ncols) = size(puzzle)
    [
        row == 1,
        col == ncols,
        row == nrows,
        col == 1
    ]
end


function check_puzzle(puzzle::MultipleSolutionPuzzle)
    errors = []
    (nrows, ncols) = size(puzzle)
    for gridi in 1:length(puzzle.grids)
        grid = puzzle.grids[gridi]
        for r in 1:nrows
            for c in 1:ncols
                for d in [N(), E()]
                    cell = grid[r, c]
                    neighbor = d(grid, cell)
                    cell_edge = get_edge(cell, d)
                    neighbor_edge = get_edge(neighbor, opposite(d))
                    if !edges_mate(cell_edge, neighbor_edge)
                        push!(errors,
                              "$gridi $r $c $d: $cell_edge $neighbor_edge")
                    end
                end
            end
        end
    end
    return isempty(erros), errors
end


"""
    puzzle_pieces(puzzle::MultipleSolutionPuzzle)::Vector{MutablePuzzlePiece}

Returns a vector of all of the `MutablePuzzlePiece`s of `puzzle`.
"""
function puzzle_pieces(puzzle::MultipleSolutionPuzzle)
    pieces = []
    for cell in puzzle.grids[1]
        push!(pieces, cell.puzzle_piece)
    end
    pieces
end

