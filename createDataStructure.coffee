###
This file turns the existing data structure into
something more suitable

classes:
    Moment
    Description
    Body
    Link

data (JSON)
    Body has key for Description
    Body has key for one Moment
    Link has keys for 2 Bodys: source and target
    A moment does not hold any information.

    graph = {
        descriptions: {
            "John": {
                "name": "John",
                "colour": "#0715CD",
                "image": "john.png",
                "groups": [
                    "Kids"
                ]
            },
        }

        moments: {
            1901: {
                panelID: 1901
                contractible: true
                split: false
            }
            1902: {
                panelID: 1902
                contractible: true
                split: false
            }
        }

        bodies: {
            "888881": {
                key_moment: 1901
                key_description: "John"
            },
            "888882": {
                key_moment: 1902
                key_description: "John"
            }
        }

        links: [
            {
                key_prev: 888881
                key_next: 888882
            }
        ]
    }

Generated relations (object references):
    moment has a list of characters
    Bodys have a list of links:     links where we are the source
    Bodys have a list of backlinks: links where we are the target

    Moment has its own key

Serialisation should care about ordering things so it can potentially be tract by git.
###





class Graph

    constructor: (timelines) ->

        # create moments
        @moments = {}
        for panelID, panel of timelines
            @moments[panelID] = {
                panelID: panelID
                contractible: true
                split: false
            }

        # create a map such that bodyIDs make more sense
        oldkey2descriptionKey = {
            # These ones are special cases where the name index
            # is the same but something else is different.
            # By default it's the name of the character.
            # Every used combination should be stored in here before use
            "4,2,2,0": "Dave"
            "4,2,3,0": "Dave (Scratch)"
            "6,3,4,0": "Jade"
            "6,4,4,0": "Jade (Grimbark)"
            "10,7,8,2": "DaveSprite"
            "10,2,3,2": "DaveSprite (red text)"
            "16,11,14,3": "Lil' cal (dream)"
            "16,12,15,3": "Lil' cal"
            "16,13,16,3": "Lil' cal (felt)"
            "61,28,44,7": "Karkat"
            "61,29,44,7": "Karkat (grey)"
            "71,5,53,8":  "Jane"
            "71,29,53,8": "Jane (grey)"
            "96,39,64,11": "Caliborn (grey)"
            "96,40,64,11": "Caliborn (dark green)"
            "96,41,64,11": "Caliborn"
        }
        # given index of name, what detailIndecies point to us
        nameCombos = ( {} for name in peoplenames )
        for panelID, panel of timelines
            for oldbody in panel
                oldkey = '' + oldbody.slice(0, 4)
                nameCombos[oldbody[0]][oldkey] = true

        for i, dict of nameCombos
            name = peoplenames[i]
            dictSize = 0
            for k,v of dict
                dictSize += 1
            if dictSize <= 0
                warn "some character isn't referenced"
            else if dictSize == 1
                for oldkey, _ of dict
                    oldkey2descriptionKey[oldkey] = name
            else if dictSize > 1
                for oldkey, _ of dict
                    if oldkey not of oldkey2descriptionKey
                        warn "character should be manually renamed: " + oldkey


        # create character descriptions
        @descriptions = {}
        for panelID, panel of timelines
            for oldbody in panel
                indecies = oldbody.slice(0, 4)
                oldkey = '' + indecies
                key = oldkey2descriptionKey[oldkey]
                if key not in @descriptions
                    # this data comes from 4 environment variables
                    description = {
                        name:   peoplenames[ indecies[0] ]
                        colour: colours[     indecies[1] ]
                        image:  images[      indecies[2] ]
                        groups: [ groups[    indecies[3] ] ]
                    }
                    @descriptions[key] = description


        # create bodies
        @bodies = {}
        @nextBodyID = 0
        panel_index2bodyID = {}
        for panelID, panel of timelines
            for i in [0 .. panel.length-1]
                panel_index2bodyID[panelID+','+i] = @nextBodyID
                oldbody = panel[i]
                oldkey = '' + oldbody.slice(0, 4)
                body = {
                    key_description: oldkey2descriptionKey[oldkey]
                    key_moment: panelID
                }
                @addBody(body)


        # create links
        @links = []
        for panelID, panel of timelines
            for i in [0 .. panel.length-1]
                for oldlink in panel[i][4]
                    link = {
                        key_prev: panel_index2bodyID[panelID    + ',' + i         ]
                        key_next: panel_index2bodyID[oldlink[0] + ',' + oldlink[1]]
                    }
                    @links.push(link)

        # check that nothing is wrong so far
        @validate()

        @buildPointers()


    # appends a new body to the list
    addBody: (body) ->
        @bodies[@nextBodyID] = body
        @nextBodyID += 1

    validate: () ->
        # all keys in links must exist
        for link in @links
            assert link.key_prev of @bodies
            assert link.key_next of @bodies

        # all keys in bodies must exist
        for key, body of @bodies
            assert body.key_moment of @moments
            assert body.key_description of @descriptions


    # this builds the direct links that are not represented in JSON
    buildPointers: () ->

        for id, description of @descriptions
            description.bodies = []

        for id, moment of @moments
            moment.bodies = []

        # create direct pointers for links
        for id, body of @bodies
            body.prev = []
            body.next = []
            body.links_prev = []
            body.links_next = []

            body.description = @descriptions[body.key_description]
            body.description.bodies.push(body)

            body.moment = @moments[body.key_moment]
            body.moment.bodies.push(body)

        for link in @links
            prev = @bodies[link.key_prev]
            next = @bodies[link.key_next]
            link.prev = prev
            link.next = next
            next.prev.push(prev)
            prev.next.push(next)
            next.links_prev.push(link)
            prev.links_next.push(link)

    # delete things so that we get back to what we had before buildPointers()
    deletePointers: () ->
        for id, description of @descriptions
            delete description.bodies

        for id, body of @bodies
            delete body.prev
            delete body.next
            delete body.links_prev
            delete body.links_next
            delete body.description
            delete body.moment

        for link in @links
            delete link.prev
            delete link.next


window.Graph = Graph

