using Base.Iterators
import XML
using XML: Element

export writing_html_file, html_wrapper, grids_to_html, grid_to_html

#=

We need an easy to understand representation of a puzze.  Here we
generate an HTML grid from a puzzle grid.

=#

GRID_STYESHEET = """

.grid {
    display: block;
    margin: 2ex;
    padding: 2ex;
    border: solid yellow;
}
.GridCell {
    display: grid;
    gap: 10px;
    grid-template-columns: repeat(3, 1fr);
    grid-template-rows: repeat(3, 1fr);
    margin: 0;
    padding: 2;
    border: solid yellow;
}
.Edge {
    font-family: sans-serif;
}
.Edge.N {
    display: in-line;
    grid-row: 1;
    grid-column: 2:
    text-align: center;
}
.Edge.E {
    display: in-line;
    grid-row: 2;
    grid-column: 3:
    text-align: end;
}
.Edge.S {
    display: in-line;
    grid-row: 3;
    grid-column: 2:
    text-align: center;
}
.Edge.W {
    display: in-line;
    grid-row: 2;
    grid-column: 1:
    text-align: start;
}
.piece_number {
    display: in-line;
    grid-row: 2;
    grid-column: 2:
    margin: 3em;
    font-weight: bold;
    text-align: center;
}
"""

"""
    writing_html_file(body, filename)

Write an HTML file to `filename`.

`body` is a vector of elements to be included in the HTML document.
"""
function writing_html_file(body, filename)
    ## body should return a vector of HTML Elements.
    XML.write(filename,
              html_wrapper(body());
              indentsize=2)
end

function html_wrapper(body_elements)
    Element(
        "html",
        Element(
            "head",
            Element("style", GRID_STYESHEET)),
        Element(
            "body", body_elements...)
    )
end


"""
    grids_to_html(grids::Vector{Grid})

Generates HTML elements for the grids.
"""
function grids_to_html(grids::Vector{Grid})
    all_pieces = Set()
    for grid in grids
        (nrows, ncols) = size(grid)
        for row in 1:nrows
            for col in 1:ncols
                cell = grid[row, col]
                if cell isa GridCell
                    push!(all_pieces, cell.puzzle_piece)
                end
            end
        end
    end
    piece_numbers = Dict{AbstractPuzzlePiece, Int}()
    for (i, p) in enumerate(all_pieces)
        piece_numbers[p] = i
    end
    map(g -> grid_to_html(g, piece_numbers),
        grids)
end


"""
    grid_to_html(grid::Grid, piece_numbers=nothing)

Generates HTML representing a tabular view of `grid`.

If `piece_numbers` is specified it is a Dict mapping from a puzzle
piece to s small integer id to be printed in the center of the piece.
"""
function grid_to_html(grid::Grid, piece_numbers=nothing)
    function piece_number(cell::GridCell)
        if piece_numbers isa Dict
            string(piece_numbers[cell.puzzle_piece])
        else
            ""
        end
    end
    (nrows, ncols) = size(grid)
    Element(
        "div",
        Element(
            "table",
            [ Element(
                "tr",
                [
                    Element(
                        "td",
                        Element(
                            "div",
                            let
                                cell = grid[row, col]
                                if cell isa GridCell
                                    edges = []
                                    for d in [N(), W(), E(), S()]
                                        edge = get_edge(cell, d)
                                        ## Maybe do something to highlight
                                        ## mismatched edges.
                                        push!(edges,
                                              Element(
                                                  "div",
                                                  terserep(edge);
                                                  class="Edge $(string(typeof(d)))"))
                                        if d isa W
                                            push!(edges,
                                                  Element(
                                                      "div",
                                                      piece_number(cell);
                                                      class="piece_number"))
                                        end
                                    end
                                    edges
                                else
                                    [ "&nbsp" ]
                                end
                            end...;
                            class="GridCell")
                    )
                    for col in 1:ncols
                        ]...
                            )
              for row in 1:nrows ]...);
    class="grid")
end

