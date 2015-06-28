

interestingCharacters = {}
filterFunction = (body) ->
    interestingCharacters[body.key_description] is true
    # 'Kids' in body.description.groups

svg = null
force = null
dataContainer = null
link = null
node = null
d3data = null
# selectedNode = null

editMode = 'info'
editModes = {
    'info':     '#tab-info'
    'contract': '#tab-contract'
    'split':    '#tab-split'
}

# onEdit = () ->
#     assert selectedNode?
#     momentToEdit = selectedNode.subNodes[0].moment
#     assert momentToEdit
#     momentToEdit.contractible = $('#edit-contractible').is(':checked')
#     for subnode in selectedNode.subNodes
#         subnode.moment.split = $('#edit-split').is(':checked')
#     onNodeSelect(null)
#     scheduleRecreateGraph()

onNodeSelect = (node) ->
    selectedNode = node

    if node?
        # console.log node

        html_panel = ''
        html_bodies = ''
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


        # editing
        momentToEdit = selectedNode.subNodes[0].moment
        assert momentToEdit
        $('#info-contractible').html('' + momentToEdit.contractible)
        $('#info-split'       ).html('' + momentToEdit.split)



        # switch to the info tab
        $(editModes['info']).tab('show')

    showIfTrue(node?, '#info-node', '#info-no-node')
    showIfTrue(node?, '#edit-controls', '#edit-noselection')


copyPosition = (_contraction) ->
    return {
        x:      _contraction.x
        y:      _contraction.y
        fixed:  _contraction.fixed
    }

recreateVisualization = () ->
    graphContainer = $("#graph-container")
    width  = graphContainer.width()
    height = window.innerHeight - 10

    # remove old stuff
    if force?
        force.alpha(0.0)
    if svg?
        d3.select("svg").remove()


    zoomed = () ->
        d3.event.translate[0] += 0.5 * d3.event.scale * width
        d3.event.translate[1] += 0.5 * d3.event.scale * height

        dataContainer.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")")

    startingZoom = 0.3
    zoom = d3.behavior.zoom()
        .scaleExtent([0.2, 2])
        .scale(startingZoom)
        .on("zoom", zoomed)

    svg = d3.select("#graph-container").html("")
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

    dataContainer = svg.append("g")
        .attr("transform", "translate(" + [width*0.5*startingZoom, height*0.5*startingZoom] + ")scale(" + startingZoom + ")")




    # create a force-directed dynamic graph layout.
    force = d3.layout.force()
        .gravity(0)
        .charge(-100)
        .linkDistance(50)
        # .size([width, height])
        .on("tick", () ->

            node.attr("transform", (d) ->
                "translate(#{ d.x }, #{ d.y })"
            )

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


        )

    force.drag()
        .on("dragstart", (d) ->
            d3.event.sourceEvent.stopPropagation()

            if editMode != 'info'
                console.warn('invalid editMode: ' + editMode)
                return

            onNodeSelect(d)

            d.dragstart_x = d.x
            d.dragstart_y = d.y
            d.startedFixed = if d.fixed & 1 then true else false

            d.fixed = true
            d3.select(this).classed("fixed", d.fixed)
        )
        .on("dragend", (d) ->
            # if editMode is not 'info'
            #     console.log this
            #     onNodeSelect(null)
            #     d.fixed = false
            #     d3.select(this).classed("fixed", d.fixed)
            #     return

            dragDistance = length(
                d.dragstart_x - d.x,
                d.dragstart_y - d.y
            )

            fixed = dragDistance > 10 || !d.startedFixed

            if not fixed
                onNodeSelect(null)

            d3.select(this).classed("fixed", d.fixed = fixed)

        )

    recreateGraph()


timeout_recreate = null
scheduleRecreateGraph = () ->
    clearTimeout timeout_recreate
    timeout_recreate = setTimeout(recreateGraph, 10)


recreateGraph = () ->

    d3data = createD3data(graph, filterFunction, d3data)

    force.stop()
    force.nodes(d3data.nodes)
    force.links(d3data.links)
    force.start()
    force.alpha(0.2)

    dataContainer.selectAll("*").remove()

    link = dataContainer.selectAll(".link")
        .data(d3data.links)
        .enter()
        .append("path")
        .style("fill", "none")
        .style('stroke', (d) ->
            d.colour
        )

    node = dataContainer.selectAll(".node")
        .data(d3data.nodes)
        .enter()
        .append("circle")
        .attr("class", (d) ->
            cls = "node"
            if d.fixed & 1
                cls += ' fixed'
            if not d.subNodes[0].moment.contractible
                cls += ' uncontractible'
            if any ( subNode.moment.split for subNode in d.subNodes )
                cls += ' split'

            return cls
        )
        .attr("r", (d) -> 10 )  # radius
        # .call(force.drag)


    # set up interaction for nodes
    if editMode == 'info'
        node.call(force.drag)
    else if editMode == 'contract'
        node.on('click', (d) ->
            onNodeSelect(null)
            d.fixed = false

            # make the middle moment not contractible
            momentIndex = d.subNodes.length // 2
            momentToEdit = d.subNodes[momentIndex].moment

            # initialize potential positions to where this node is
            copyPos = copyPosition(d)
            d3data._contractions[d.subNodes[momentIndex].id] = copyPos
            if momentIndex + 1 < d.subNodes.length
                d3data._contractions[d.subNodes[momentIndex + 1].id] = copyPos
            momentToEdit.contractible = not momentToEdit.contractible
            scheduleRecreateGraph()
        )
    else if editMode == 'split'
        node.on('click', (d) ->
            onNodeSelect(null)
            d.fixed = false

            shouldSplit = not any ( subNode.moment.split for subNode in d.subNodes )
            for subnode in d.subNodes
                subnode.moment.split = shouldSplit

            # initialize potential positions to where this node is
            copyPos = copyPosition(d)
            if shouldSplit
                for subNode in d.subNodes
                    for body in subNode.moment.bodies
                        d3data._contractions["body: #{ body.key_self }"] = copyPos
            else
                for subnode in d.subNodes
                    d3data._contractions["moment: #{ subNode.key_moment }"] = copyPos

            scheduleRecreateGraph()
        )



resize = () ->
    # TODO: make resizing better
    $('#sidebar').height(window.innerHeight)
    recreateVisualization()



changeEditMode = (newEditMode) ->
    assert newEditMode of editModes
    $(editModes[editMode]).tab('show')


    editMode = newEditMode
    dataContainer.attr('class', editMode)

    recreateGraph()




$ ->
    colours[0] = '#2d65cd'  # make John's colour more visible
    # TODO: make caliborn (grey) more visible

    window.graph = new Graph(timelines)

    # create the list of interesting characters
    $('#filter-checkboxes input').each () ->
        character = $(this).attr('char')
        if character?
            interestingCharacters[character] = $(this).is(":checked")
        return true

    # add checkboxes that weren't added manually
    missedCheckboxes = {}
    missedCheckboxes[key] = val for key, val of graph.descriptions
    for key, val of interestingCharacters
        delete missedCheckboxes[key]
    html_otherCheckboxes = ''
    for key, description of missedCheckboxes
        html_otherCheckboxes += """
            <li><input type="checkbox" char="#{ key }"><span>#{ description.name }</span>
        """
        # console.log """<li><input type="checkbox" char="#{ key }"><span>#{ description.name }</span>"""
    $('#filter-others').html html_otherCheckboxes


    ### events ###
    $('#filter-checkboxes input[char]').change(() ->
        character = $(this).attr('char')
        interestingCharacters[character] = $(this).is(":checked")

        # make sure we don't call recreateGraph more than once for a sweeping change
        scheduleRecreateGraph()

        return true
    )

    # edit mode change
    $('#sidebarTabs a').click( (e) ->
        e.preventDefault()
        $(this).tab('show')

        href = $(this).attr('href')
        if href?
             newEditMode = href.split('tabcontent-')[1]
             if newEditMode of editModes
                changeEditMode(newEditMode)

    )

    $(document).keydown((e) ->
        switch e.which

            # 1 2 3
            when 49 then changeEditMode 'info'
            when 50 then changeEditMode 'contract'
            when 51 then changeEditMode 'split'

            when 32 # space
                console.log 'spaaaaaaaaaace!'
    )

    window.onresize = resize
    resize()

