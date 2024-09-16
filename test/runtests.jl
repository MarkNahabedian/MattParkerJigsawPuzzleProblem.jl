using MattParkerJigsawPuzzleProblem
using Test

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
                neignbor = sp[neighbor_coordinates(this_piece, direction)...]
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


