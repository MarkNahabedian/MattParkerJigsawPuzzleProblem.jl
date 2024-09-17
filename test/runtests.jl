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

@testset "Make SolvedPuzzle" begin
    sp = SolvedPuzzle(3, 4)
    assign_perimeter_edges(sp)
    assign_unique_unassigned_edges(sp)
    # Do all of the edges match?
    (rows, cols) = size(sp)
    for r in 1:rows
        for c in 1:cols
            this_piece = sp[r, c]
            do_cardinal_directions() do direction
                neignbor = sp[direction(this_piece.row, this_piece.col)...]
                if neignbor == nothing
                    this_piece.edges[direction].bs == Ball()
                else
                    @test edges_match(this_piece.edges[direction],
                                      neignbor.edges[opposite(direction)])
                end
            end
        end
    end
end


