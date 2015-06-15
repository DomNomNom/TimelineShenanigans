


resize = () ->
    # TODO: make resizing better
    $('#sidebar').height(window.innerHeight)

window.onresize = resize




$ ->
    resize()
    colours[0] = '#2d65cd'  # make John's colour more visible

    graphContainer = $("#graph-container")
    #window.width  = window.innerWidth  - 30
    #window.height = window.innerHeight - 50
    width  = graphContainer.width()
    height = window.innerHeight - 10



    graph = new Graph(timelines)

    filterFunction = (body) ->
        'Kids' in body.description.groups

    d3data = createD3data(graph, filterFunction)



    # graph.deletePointers()
    # log JSON.stringify(graph, null, 4)
    # log 'stringify 1'
    # # txt = JSON.stringify(graph, null, 4)
    # txt = JSON.stringify(graph.descriptions, null, 4)
    # log 'stringify 2'
    # window.d3.select('#debugtext').html(txt)
    # log 'stringify 3'




    zoomed = () ->
        d3.event.translate[0] += 0.5 * d3.event.scale * width
        d3.event.translate[1] += 0.5 * d3.event.scale * height

        container.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")")


    zoom = d3.behavior.zoom()
        .scaleExtent([0.2, 2])
        .on("zoom", zoomed)


    svg = d3.select("#graph-container")
        .append("svg")
            .attr("width", width)
            .attr("height", height)
        .append("g")
            .call(zoom)

    rect = svg.append("rect")
        .attr("width", width)
        .attr("height", height)
        .style("fill", "none")
        .style("pointer-events", "all")

    container = svg.append("g")
        .attr("transform", "translate(" + [width*0.5, height*0.5] + ")")



    link = container.selectAll(".link")
        .data(d3data.links)
        .enter()
        .append("path")
        .style("fill", "none")
        .style('stroke', (d) ->
            d.colour
            #colours[0]
            #colours[d.colourID]
        )

    node = container.selectAll(".node")
        .data(d3data.nodes)
        .enter().append("circle")
        .attr("class", (d) ->
            "node"
            # cls = "node"
            # basePanelID = d.panelID.split('[')[0]
            # if panelsToSplit == basePanelID
            #     cls += " split"
            # return cls
        )
        .attr("r", (d) -> 10 )  # radius



    # create a force-directed dynamic graph layout.
    force = d3.layout.force()
        .gravity(0)
        .charge(-100)
        .linkDistance(50)
        .nodes(d3data.nodes)
        # .size([width, height])
        .links(d3data.links)
        .start()
        .on("tick", () ->
            link.attr("d", (d) ->
                x1 = d.source.x
                y1 = d.source.y
                x2 = d.target.x
                y2 = d.target.y
                dx = x2 - x1
                dy = y2 - y1

                arrowLength = 10.0
                arrowWidth = 1.5
                linkBandWidth = 15.0

                x_source = x1
                y_source = y1
                x_target = x2
                y_target = y2

                vx = x_target - x_source
                vy = y_target - y_source
                lenV = Math.sqrt(vx * vx + vy * vy)
                vx /= lenV
                vy /= lenV

                x_target -= 10 * vx
                y_target -= 10 * vy


                # tangent
                tx = - vy
                ty =  vx


                x_source += linkBandWidth * d.offset_prev * tx
                y_source += linkBandWidth * d.offset_prev * ty
                x_target += linkBandWidth * d.offset_next * tx
                y_target += linkBandWidth * d.offset_next * ty

                vx = x_target - x_source
                vy = y_target - y_source
                lenV = Math.sqrt(vx * vx + vy * vy)
                vx /= lenV
                vy /= lenV
                tx = - vy
                ty =  vx


                # tx = -dy
                # ty =  dx
                # lenTangent = Math.sqrt(tx*tx + ty*ty)
                # tx /= lenTangent
                # ty /= lenTangent


                # x_target = lerp(x_source, x_target, 0.9)
                # y_target = lerp(y_source, y_target, 0.9)

                txt = "M#{ x_source },#{ y_source }"
                txt += "L#{ x_target },#{ y_target }"
                txt += "L"
                txt +=    "#{ x_target - arrowLength * vx + arrowWidth * tx },"
                txt +=    "#{ y_target - arrowLength * vy + arrowWidth * ty }"
                txt += "L"
                txt +=    "#{ x_target - arrowLength * vx - arrowWidth * tx },"
                txt +=    "#{ y_target - arrowLength * vy - arrowWidth * ty }"
                txt += "L#{ x_target },#{ y_target }"
                return txt
            )

            node.attr("transform", (d) ->
                "translate(#{ d.x }, #{ d.y })"
            )

        )




    setInfoData = (node) ->
        $('#tab-info').tab('show')



        if node?
            html_panel = ''
            html_bodies = ''
            console.log node

            bodies = []
            for subnode in node.subNodes
                panelID = subnode.moment.panelID
                html_panel += """
                    <a
                     href="http://mspaintadventures.com/?s=6&p=#{ pad(panelID, 6) }"
                     target="_blank"
                    >
                        #{ panelID }
                    </a>
                    &nbsp
                """
                bodies = subnode.moment.bodies

            for body in bodies
                description = body.description
                html_bodies += """
                    <span style="color: #{ description.colour };">
                        #{ description.name }
                    </span>
                    &nbsp
                """


            $('#info-panels').html(html_panel)
            $('#info-bodies').html(html_bodies)


            $('#info-node'   ).removeClass('hidden')
            $('#info-no-node').addClass('hidden')
        else
            $('#info-node'   ).addClass('hidden')
            $('#info-no-node').removeClass('hidden')



    force.drag()
        .on("dragstart", (d) ->
            d3.event.sourceEvent.stopPropagation()
            setInfoData(d)

            d.dragstart_x = d.x
            d.dragstart_y = d.y
            d.startedFixed = if d.fixed & 1 then true else false
            d3.select(this).classed("fixed", d.fixed = true)
        )
        .on("dragend", (d) ->

            dragDistance = length(
                d.dragstart_x - d.x,
                d.dragstart_y - d.y
            )

            fixed = dragDistance > 10 || !d.startedFixed

            if not fixed
                setInfoData(null)

            d3.select(this).classed("fixed", d.fixed = fixed)

        )

    node.call(force.drag)


    force.alpha(0.2)
