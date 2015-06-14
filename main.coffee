$( () ->
    log 'hello world'
    graph = new Graph(timelines)
    window.createD3data(graph, (body) -> true)



    graph.deletePointers()
    # log JSON.stringify(graph, null, 4)
    log 'stringify 1'
    # txt = JSON.stringify(graph, null, 4)
    txt = JSON.stringify(graph.descriptions, null, 4)
    log 'stringify 2'
    window.d3.select('#debugtext').html(txt)
    log 'stringify 3'
)
