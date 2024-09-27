import XML
using XML: Element

export writing_html_file, html_wrapper, grid_to_html

#=

We need an easy to understand representation of a puzze.  HEre we
generate an HTML table from a puzzle grid.

=#

GRID_STYESHEET = """

.grid {
    display: block;
    margin: 2ex;
    padding: 2ex;
    border: solid yellow;
}
.GridCell {
    display: block;
    margin: 0;
    padding: 2;
    border: solid yellow;
}
.Edge {
    font-family: sans-serif;
}
.Edge.N {
    display: block;
    vertical-align: top;
    text-align: center;
}
.Edge.E {
    display: inline-block;
    margin-left: 1em;
    vertical-align: center;
    text-align: end;
}
.Edge.S {
    display: block;
    vertical-align: bottom;
    text-align: center;
}
.Edge.W {
    display: inline-block;
    margin-right: 1em;
    vertical-align: center;
    text-align: start;
}
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


function grid_to_html(grid::Grid)
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

