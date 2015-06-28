# moments can be split (bodies can be merged into moments)
# moments can choose to be not contractible
# d3nodes are always contracted

# if split one moment has many d3 nodes
# if contracted, one d3node has many moments

###
d3data = {
    nodes: [
        { // contraction
            x: -100.3
            y: 15.3
            isIntroduction: false
            isTerminal: false
            # isSplit: true # this implies that there is exactly one body
            # moments: [ linkToMoment, linkToMoment ]
            bodies:  [ linkToBody ]
            id: contractionID
            subNodes: [
                {
                    bodies: [ body, body ]
                    moment: {
                        panelID: 1902
                        contractible: true
                        split: false
                    }
                }
                {
                    bodies: [ body ]
                    moment: body.moment
                }
            ]
        }
        ...
    ]

    links: [
        {
            prev: node_prev
            next: node_next
            colour: '#0715CD',
            offset_prev: -1.0,
            offset_next:  0.0,
        }
        ...
    ]
}

###


window.createD3data = (graph, bodyIsInteresting, previousData) ->
    ###
    build the set of included bodies
    join bodies into moments unless the moment is split
    ###
    d3nodes = {}
    for id, body of graph.bodies
        if not bodyIsInteresting body
            continue

        d3node = null
        if body.moment.split
            d3node = {
                bodies: [ body ]
                moment: body.moment
            }
            d3nodes["body: #{ id }"] = d3node
        else
            nodeKey = "moment: #{ body.key_moment }"
            if nodeKey of d3nodes
                d3node = d3nodes[nodeKey]
                assert body.moment is d3node.moment
                d3node.bodies.push(body)
            else
                d3node = {
                    bodies: [ body ]
                    moment: body.moment
                }
                d3nodes[nodeKey] = d3node

        assert d3node isnt null
        body.d3node = d3node

    # some assertions
    for id, d3node of d3nodes
        assert 'moment' of d3node
        assert d3node.bodies.length >= 1
    for momentID, moment in graph.moments
        if  moment.split
            assert "moment: #{ momentID }" not of d3nodes
            for id, body of moment.bodies
                if bodyIsInteresting(body)
                    assert "body: #{ id }" of d3nodes
                else
                    assert "body: #{ id }" not of d3nodes
        else
            isInterestingMoment = false
            for id, body of moment.bodies
                assert "body: #{ id }" not of d3nodes
                if bodyIsInteresting(body)
                    isInterestingMoment = true

            if isInterestingMoment
                assert "moment: #{ momentID }" of d3nodes


    getOffset = (index, listLength) ->
        if listLength > 1
            return (index / (listLength-1.0)) - 0.5
        else
            return 0.0

    d3links = []
    for link in graph.links
        if not(
            bodyIsInteresting(link.prev) and
            bodyIsInteresting(link.next)
        )
            continue

        body_prev = link.prev
        body_next = link.next

        bodies_prev = body_prev.d3node.bodies
        bodies_next = body_next.d3node.bodies
        index_prev = bodies_prev.indexOf(link.prev)
        index_next = bodies_next.indexOf(link.next)

        # id = body_prev + '|' + body_next
        link = {
            node_prev: body_prev.d3node
            node_next: body_next.d3node
            colour: body_prev.description.colour
            offset_prev: getOffset(index_prev, bodies_prev.length)
            offset_next: getOffset(index_next, bodies_next.length)
        }
        d3links.push(link)


    ###
    select nodes for contraction
    ###
    numWasContractible = 0
    for id, d3node of d3nodes
        # true - no next links yet
        # (d3node)  - we have a (outwards) 1:1 relationship
        # false - can not contract
        contractible = d3node.moment.contractible
        if not contractible
            numWasContractible += 1
        d3node.prev = contractible
        d3node.next = contractible
        d3node.prevNum = 0
        d3node.nextNum = 0
        d3node.id = id


    for d3link in d3links
        node_prev = d3link.node_prev
        node_next = d3link.node_next

        node_prev.prevNum += 1
        node_next.nextNum += 1
        if node_prev.next is false
        else if node_prev.next is true
            node_prev.next = node_next
        else
            if node_prev.next isnt node_next
                node_prev.next = false


        if node_next.prev is false
        else if node_next.prev is true
            node_next.prev = node_prev
        else
            if node_next.prev isnt node_prev
                node_next.prev = false



    # build a map from d3node id to contractedD3node



    # pop a key from a object as if it were a set
    popQueue = (queue) ->
        for key, value of queue
            assert delete queue[key]
            return value
    isEmpty = (queue) ->
        for key, value of queue
            return false
        return true

    d3nodeQueue = {}
    for id, d3node of d3nodes
        d3nodeQueue[id] = d3node


    d3nodeID2contraction = {}
    contractions = {}
    while not isEmpty(d3nodeQueue)
        start = popQueue(d3nodeQueue)
        # # add ourself
        # addToContractionMap(start)
        subNodes = [ start ]  # what is included in this contaction (ordered)

        check = (d3node) ->
            return d3node.prevNum == d3node.nextNum

        # add previous things
        current = start
        while current.prev not in [true, false] and current.prev.next is current and check(current) and check(current.prev)
            current = current.prev
            if current is start
                log 'a cyclic contraction'
                break
            subNodes.unshift current  # prepend to the array

        # add next things
        current = start
        while current.next not in [true, false] and current.next.prev is current  and check(current) and check(current.next)
            current = current.next
            if current is subNodes[0]
                warn 'a cyclic contraction where I did not expect it.'
                break
            subNodes.push current

        contractionID = subNodes[0].id
        panelID = subNodes[0].moment.panelID

        contraction = {
            x: 10000.0 * (panelID / 10000.0 - 0.5)
            y: (panelID % 100) - 50
            id: contractionID
            subNodes: subNodes
        }
        if previousData? and contractionID of previousData._contractions
            previous = previousData._contractions[contractionID]
            contraction.x     = previous.x
            contraction.y     = previous.y
            contraction.fixed = previous.fixed
        # else
        #     console.log  'notfound: ' + contractionID

        contractions[contractionID] = contraction
        for d3node in subNodes
            delete d3nodeQueue[d3node.id]
            assert not d3node.hasOwnProperty('contraction')
            d3node.contraction = contraction



    ###
    select the links that will be kept
    ###
    contractedLinks = []
    for link in d3links
        contracted_prev = link.node_prev.contraction
        contracted_next = link.node_next.contraction
        if contracted_prev is contracted_next
            continue

        link.contracted_prev = contracted_prev
        link.contracted_next = contracted_next
        contractedLinks.push(link)



    ###
    make everything into a list
    and add the properties that d3 uses
    ###
    list_contrations = ( c for id, c of contractions )
    for index in [0 .. list_contrations.length - 1]
        list_contrations[index].index = index


    for link in contractedLinks
        link.source = link.contracted_prev.index
        link.target = link.contracted_next.index

    # keep positional data for longer history
    if previousData?
        for id, contraction of previousData._contractions
            if id not of contractions
                contraction.fixed = false
                contractions[id] = contraction

    return {
        nodes: list_contrations
        links: contractedLinks

        _contractions: contractions
    }

