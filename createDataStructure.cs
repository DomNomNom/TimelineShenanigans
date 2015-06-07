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
log = (x) -> console.log x
str = (x) -> JSON.stringify x
assert = (condition, message) ->
    if not condition
        throw message or "Assertion failed"




class Graph

    constructor: (timelines) ->

        # create moments
        @moments = {}
        for panelID, panel of timelines
            @moments[panelID] = {}


        # create character descriptions
        forEachBody = (timelines, callback) ->
            for panelID, panel of timelines
                for character in panel
                    callback(character)
        @descriptions = {}
        for panelID, panel of timelines
            for oldbody in panel
                indecies = oldbody.slice(0, 4)
                key = '' + indecies
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
                body = {
                    key_description: '' + oldbody.slice(0, 4)
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
txt = JSON.stringify(graph, null, 4)
log 'stringify 2'
window.d3.select('#debugtext').html(txt)
log 'stringify 3'

# log = console.log
# log "done."

