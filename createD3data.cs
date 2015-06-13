# moments can be split (bodies can be merged into moments)
# moments can choose to be not contractible
# d3nodes are always contracted

# if split one moment has many d3 nodes
# if contracted, one d3node has many moments

###
d3node = {
    x: -100.3
    y: 15.3
    isIntroduction: false
    isTerminal: false
    # isSplit: true # this implies that there is exactly one body
    bodies:  [ linkToBody ]
    moments: [ linkToMoment, linkToMoment ]
}


d3link = {
    prev: d3node_prev
    next: d3node_next
    colour: '#0715CD',
    offset_prev: -1.0,
    offset_next:  0.0,
}

###


window.createD3data = (graph) ->
    build the set of included bodies
        filter bodies if they match a function


    ###

    split:
    d3nodes = {}
    loop through each included body:
        var d3node;
        if body.moment.split
            d3node = {
                bodies: [ body ]
            }
            d3nodes['body:#{bodyID}']: d3node
        else
            nodeKey = 'moment:#{body.key_moment}'
            if nodeKey of d3nodes
                d3node = {
                    bodies: [ body ]
                    moment: body.moment
                }
                d3nodes[nodeKey] = d3node
            else
                d3node = d3nodes[nodeKey]
                assert body.moment is d3node.moment
                d3node.bodies.push(body)

        body.d3node = d3node

    assert:
        (if !moment.split then    no body in moment is a d3node, there is a  d3node for moment)
        (if  moment.split then every body in moment is a d3node, there is no d3node for moment)
        each body has a d3node
        each d3node has a list of bodies
        each body.d3node.bodies.indexof(body) >= 0

    # build the set of included links
    #     filter links where both ends are included bodies


    ###
    getOffset = (index, listLength) ->
        if (listLength > 1)
            return (index / (listLength-1.0)) - 0.5
        else
            return 0.0;

    d3links = {}
    for link in selectedLinks
        body_prev = link.body_prev
        body_next = link.body_next

        bodies_prev = body_prev.d3node.bodies
        bodies_next = body_next.d3node.bodies
        index_prev = bodies_prev.indexOf(link.body_prev)
        index_next = bodies_next.indexOf(link.body_next)

        id = body_prev + '|' + body_next
        d3links[id] = {
            node_prev: body_prev.d3node
            node_next: body_next.d3node
            colour: body_prev.description.colour
            offset_prev: getOffset(index_prev, bodies_prev.length)
            offset_next: getOffset(index_next, bodies_next.length)
        }



    # select nodes for contraction
    for id, d3node of d3nodes
        # true - no next links yet
        # (d3node)  - we have a (outwards) 1:1 relationship
        # false - can not contract
        contractible = true
        if d3node.dontContract
            contractible = false
        d3node.prev = contractible
        d3node.next = contractible
        d3node.id = id

    for id, d3link of d3links
        node_prev = d3link.prev
        node_next = d3link.next

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
            if node_next.prev isnt body prev
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

        # add previous things
        current = start
        while current.prev not in [true, false] and current.prev.next is current
            current = current.prev
            if current is start
                log 'a cyclic contraction'
                break
            subNodes.unshift current  # prepend to the array

        # add next things
        current = start
        while current.next not in [true, false] and current.next.prev is current
            current = current.next
            if current is subNodes[0]
                warn 'a cyclic contraction where I did not expect it.'
                break
            subNodes.push current

        contractionID = subNodes[0].id
        contraction = {
            # id: contractionID
            subNodes: subNodes
        }
        contractions[contractionID] = contraction
        for d3node in subNodes
            delete d3nodeQueue[d3node.id]
            assert not d3node.hasOwnProperty('contraction')
            d3node.contraction = contraction



    ###
    select the links that will be kept
    ###
    contractedLinks = {}
    for link in selectedLinks
        body_prev = link.body_prev
        body_next = link.body_next

        contracted_prev = body_prev.d3node.contraction
        contracted_next = body_next.d3node.contraction
        if contracted_prev is contracted_next
            continue

        id = body_prev + '|' + body_next
        link = d3links[id]
        link.contracted_prev = contracted_prev
        link.contracted_next = contracted_next
        contractedLinks[id] = link



    ###
    make everything into a list
    ###
    list_contrations = ( c for id, c in contractions )
    for id in [0 .. list_contrations.length - 1]
        list_contrations[id].id = id

    list_links = ( l for id, l in contractedLinks )
    for link in list_links
        link.source = link.contracted_prev.id
        link.target = link.contracted_next.id


    return {
        nodes: list_contrations
        links: list_links
    }

