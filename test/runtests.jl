using MattParkerJigsawPuzzleProblem
using Test

@testset "edges_mate" begin
    @test edges_mate(Edge(EdgeType(true, 0), Straight()),
                     Edge(EdgeType(true, 1), Straight()))
    @test edges_mate(Edge(EdgeType(false, 2), Ball()),
                     Edge(EdgeType(false, 2), Socket()))
    @test !edges_mate(Edge(EdgeType(false, 2), Ball()),
                      Edge(EdgeType(false, 2), Ball()))
    @test !edges_mate(Edge(EdgeType(false, 2), Ball()),
                      Edge(EdgeType(false, 3), Socket()))
end

@testset "Cardinal directions" begin
    for dir in CARDINAL_DIRECTIONS
        @test opposite(opposite(dir)) == dir
    end
    @test N()(2, 2) == [1, 2]
    @test E()(2, 2) == [2, 3]
    @test S()(2, 2) == [3, 2]
    @test W()(2, 2) == [2, 1]
end

@testset "ordering" begin
    @test isless(Edge(EdgeType(false, 2), Ball()),
                 Edge(EdgeType(false, 3), Ball()),)
    @test !isless(Edge(EdgeType(false, 3), Ball()),
                  Edge(EdgeType(false, 2), Ball()),)
    @test isless(
        ImmutablePuzzlePiece(
            sort([
                Edge(EdgeType(false, 2), Ball()),
                Edge(EdgeType(false, 3), Ball()),
                Edge(EdgeType(false, 4), Ball()),
                Edge(EdgeType(false, 5), Ball())
            ])),
        ImmutablePuzzlePiece(
            sort([
                Edge(EdgeType(false, 2), Ball()),
                Edge(EdgeType(false, 5), Ball()),
                Edge(EdgeType(false, 6), Ball()),
                Edge(EdgeType(false, 7), Ball())
            ])))
    @test isless(
        ImmutablePuzzlePiece(
            sort([
                Edge(EdgeType(false, 1), Ball()),
                Edge(EdgeType(false, 3), Ball()),
                Edge(EdgeType(false, 4), Ball()),
                Edge(EdgeType(false, 5), Ball())
            ])),
        ImmutablePuzzlePiece(
            sort([
                Edge(EdgeType(false, 1), Ball()),
                Edge(EdgeType(false, 5), Ball()),
                Edge(EdgeType(false, 6), Ball()),
                Edge(EdgeType(false, 7), Ball())
            ])))
    @test !isless(
        ImmutablePuzzlePiece(
            sort([
                Edge(EdgeType(false, 5), Ball()),
                Edge(EdgeType(false, 6), Ball()),
                Edge(EdgeType(false, 7), Ball()),
                Edge(EdgeType(false, 8), Ball())
            ])),
        ImmutablePuzzlePiece(
            sort([
                Edge(EdgeType(false, 1), Ball()),
                Edge(EdgeType(false, 5), Ball()),
                Edge(EdgeType(false, 6), Ball()),
                Edge(EdgeType(false, 7), Ball())
            ])))
end

@testset "GridCell operations" begin
    grid = new_grid(3, 3)
    for r in 1:3
        for c in 1:3
            grid[r, c] = GridCell(r, c, MutablePuzzlePiece(),
                                  rotation(r + c))
        end
    end
    @test N()(grid[2, 2]) == [1, 2]
    @test E()(grid[2, 2]) == [2, 3]
    @test S()(grid[2, 2]) == [3, 2]
    @test W()(grid[2, 2]) == [2, 1]
    e = Edge(EdgeType(false), Ball())
    set_edge!(grid[1, 1], S(), e)
    @test get_edge(grid[1, 1], S()) == e
end

@testset "get_neighboring_edge" begin
    grid = new_grid(3, 3)
    grid[1, 1] = GridCell(1, 1,
                          ImmutablePuzzlePiece([
                              Edge(EdgeType(true, 1), Straight()),
                              Edge(EdgeType(false, 2), Ball()),
                              Edge(EdgeType(false, 3), Socket()),
                              Edge(EdgeType(true, 4), Straight())
                          ]), 0)
    ## Top left corner
    @test get_neighboring_edge(grid, 1, 1, N()) ==
        Edge(EdgeType(true, 0), Straight())
    @test ismissing(get_neighboring_edge(grid, 1, 1, E()))
    @test ismissing(get_neighboring_edge(grid, 1, 1, S()))
    @test get_neighboring_edge(grid, 1, 1, W()) ==
        Edge(EdgeType(true, 0), Straight())
    ## Bottom right corner:
    @test get_neighboring_edge(grid, 3, 3, E()) ==
        Edge(EdgeType(true, 0), Straight())
    @test get_neighboring_edge(grid, 3, 3, S()) ==
        Edge(EdgeType(true, 0), Straight())
    # Cell woth a real neighbor:
    @test get_neighboring_edge(grid, 2, 1, N()) ==
        Edge(EdgeType(false, 3), Socket())
end


## Verify for each grid that the perimeters are correct:
function check_perimeters(puzzle::MultipleSolutionPuzzle)
    (nrows, ncols) = size(puzzle)
    for g in 1:length(puzzle.grids)
        grid = puzzle.grids[g]
        for row in 1:nrows
            for col in 1:ncols
                cell = grid[row, col]
                if row == 1
                    @test isperimeter(cell, N())
                elseif row == nrows
                    @test isperimeter(cell, S())
                end
                if col == 1
                    @test isperimeter(cell, W())
                elseif col == ncols
                    @test isperimeter(cell, E())
                end
            end
        end
    end
end    

## Verify for each grid that the edges mate
function check_that_edges_mate(puzzle::MultipleSolutionPuzzle)
    (nrows, ncols) = size(puzzle)
    for grid in puzzle.grids
        (nrows, ncols) = size(grid)
        for r in 1:nrows
            for c in 1:ncols
                cell = grid[r, c]
                for direction in CARDINAL_DIRECTIONS
                    neighbor = direction(grid, cell)
                    # Make sure we haven't fallen off the edge of the
                    # grid:
                    if neighbor isa GridCell
                    # We're testing every edge twice.  So what?
                        @test edges_mate(get_edge(cell, direction),
                                         get_edge(neighbor, opposite(direction)))
                    end
                end
            end
        end
    end
end

@testset "MultipleSolutionPuzzle - single grid" begin
    puzzle = MultipleSolutionPuzzle(4, 5, 1)
    check_perimeters(puzzle)
    check_that_edges_mate(puzzle)
    writing_html_file("single_grid_puzzle.html") do
        grids_to_html(puzzle.grids)
    end
    solver = Solver(size(puzzle),
                    map(ImmutablePuzzlePiece,
                        puzzle_pieces(puzzle)))
    solve(solver)
    writing_html_file("solved_single_grid_puzzle.html") do
        grids_to_html(solver.solved_grids)
    end
end

#=
@testset "MultipleSolutionPuzzle - two grids" begin
    puzzle = MultipleSolutionPuzzle(3, 5, 2)
    check_perimeters(puzzle)
    check_that_edges_mate(puzzle)
    writing_html_file("two_grid_puzzle.html") do
        grids_to_html(puzzle.grids)
    end
    solver = Solver(size(puzzle),
                    map(ImmutablePuzzlePiece,
                        puzzle_pieces(puzzle)))
    solve(solver)
    writing_html_file("solved_two_grid_puzzle.html") do
        grids_to_html(solver.solved_grids)
    end
    @test length(solver.solved_grids) >= 2
end
=#

#=

using MattParkerJigsawPuzzleProblem
using MattParkerJigsawPuzzleProblem: unused_pieces, find_next_empty

begin
    puzzle = MultipleSolutionPuzzle(4, 5, 1)
    solver = Solver(size(puzzle),
                    map(ImmutablePuzzlePiece,
                        puzzle_pieces(puzzle)))
    grid = solver.working_grids[1]
    nothing
end

find_next_empty(grid)

unused_pieces(grid, solver)

add_one_piece(solver, grid)

writing_html_file("working.html") do
    grids_to_html(solver.working_grids)
end

=#

