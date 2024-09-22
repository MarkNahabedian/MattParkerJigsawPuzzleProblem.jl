using MattParkerJigsawPuzzleProblem
using Test

@testset "Cardinal directions" begin
    do_cardinal_directions() do dir
        @test opposite(opposite(dir)) == dir
        @test next(previous(dir)) == dir
        @test previous(next(dir)) == dir
        @test next(dir) == opposite(previous(dir))
        @test next(dir) == previous(opposite(dir))
        @test previous(dir) == opposite(next(dir))
        @test previous(dir) == next(opposite(dir))
    end
    @test cardinal_directions_from(N()) == (N(), E(), S(), W())
    @test cardinal_directions_from(W()) == (W(), N(), E(), S())
    @test edge_direction(0, 1) == N()
    @test edge_direction(0, 5) == N()
    @test edge_direction(0, 2) == E()
    @test edge_direction(1, 1) == W()
    @test N()(2, 2) == [1, 2]
    @test E()(2, 2) == [2, 3]
    @test S()(2, 2) == [3, 2]
    @test W()(2, 2) == [2, 1]
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

@testset "MultipleSolutionPuzzle - single grid" begin
    puzzle = MultipleSolutionPuzzle(3, 5, 1)
    ## Verify for each grid that the perimeters are correct:
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
    ## Verify for each grid that the edges mate
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

