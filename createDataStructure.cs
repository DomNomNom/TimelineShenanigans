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

Generated relations (object references):
    moment has a list of characters
    Bodys have a list of links:     links where we are the source
    Bodys have a list of backlinks: links where we are the target

    Moment has its own key

Serialisation should care about ordering things so it can potentially be tract by git.
###

# shorthands
str = (x) -> JSON.stringify x
log = (x) -> console.log x
warn = (x) -> console.warn x
assert = (condition, message) ->
    if not condition
        throw message or "Assertion failed"




class Graph

    constructor: (timelines) ->

        # create moments
        @moments = {}
        for panelID, panel of timelines
            @moments[panelID] = {}

        # create a map such that bodyIDs make more sense
        oldkey2descriptionKey = {
            # These ones are special cases where the name index
            # is the same but something else is different.
            # By default it's the name of the character.
            # Every used combination should be stored in here
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

        log 'duplicates: '
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
                log('   '  + name + ': ' + (str dict))
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
                        key_source: panel_index2bodyID[panelID    + ',' + i         ]
                        key_target: panel_index2bodyID[oldlink[0] + ',' + oldlink[1]]
                    }
                    @links.push(link)

        # check that nothing is wrong so far
        @validate()


    # appends a new body to the list
    addBody: (body) ->
        @bodies[@nextBodyID] = body
        @nextBodyID += 1

    validate: () ->
        # all keys in links must exist
        for link in @links
            assert link.key_source of @bodies
            assert link.key_target of @bodies

        # all keys in bodies must exist
        for key, body of @bodies
            assert body.key_moment of @moments
            assert body.key_description of @descriptions

        return true



graph = new Graph(timelines)
# log JSON.stringify(graph, null, 4)
log 'stringify 1'
# txt = JSON.stringify(graph, null, 4)
txt = JSON.stringify(graph.descriptions, null, 4)
log 'stringify 2'
window.d3.select('#debugtext').html(txt)
log 'stringify 3'

# log = console.log
# log "done."

