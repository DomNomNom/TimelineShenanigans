
type_key = 'key'
type_boolean = 'boolean'
type_string = 'string'
type_stringArray = 'stringArray'

serializationOrder = [
    'serializationVersion'
    'descriptions'
    'moments'
    'bodies'
    'links'
]
serializationMaps = {
    descriptions: [
        [type_string, 'name']
        [type_string, 'colour']
        [type_string, 'image']
        [type_stringArray, 'groups']
    ]
    moments: [
        [type_boolean, 'contractible']
        [type_boolean, 'split']
    ]
    bodies: [
        [type_key, 'key_moment']
        [type_key, 'key_description']
    ]
    links: [
        [type_key, 'key_prev']
        [type_key, 'key_next']
    ]
}

serializationVersion = "1.0"
blockSeparator = '\n\n\n\n\n\n\n'

window.serialize = (graph) ->
    console.log 'serializing...'
    serialize_indented = (stuff) -> JSON.stringify(stuff, {sortKeys: true}, 2)
    # note: str(stuff) == JSON.stringify(stuff)

    serializeString = (string) ->
        assert typeof string == 'string'
        str(string).slice(1, -1)

    serializeKey = (key) ->
        switch typeof key
            when 'number'
                return key
            when 'string'
                # if it is purely an integer-string, no need to have quotes around it
                if key == str parseInt(key)
                    return parseInt(key)  # note: not going to bother with passing base 10. use a more modern browser
                else
                    return serializeString key
            else
                throw 'key of bad type: ' + typeof key

    # this sorts number-strings properly
    sortingFunction = (a, b) -> a.length - b.length or a > b ? 1 : -1;


    outBlocks = []

    for graphProperty in serializationOrder
        if graphProperty == 'serializationVersion'
            outBlocks.push( "serializationVersion: #{ serializationVersion }")
            continue

        subproperties = serializationMaps[graphProperty]
        # an 'instance' is an instance of a moment, body or link
        instances = graph[graphProperty]

        string = '[\n'
        keys = ( key for key of instances )
        keys.sort(sortingFunction)
        for key in keys
            instance = instances[key]
            propertyStrings = [ serializeKey(key) ]

            # serialize each property
            for tuple in subproperties
                value = instance[tuple[1]]
                switch tuple[0]  # object type
                    when type_boolean
                        value = 0 + value  # convert bool to 0 or 1
                    when type_key
                        value = serializeKey(value)
                    when type_string
                        value = serializeString value
                    when type_stringArray
                        assert value.constructor == Array
                        for s in value
                            assert typeof s == 'string'
                        value = str value
                    else
                        throw 'unhandled instance type: ' + tuple[0]

                propertyStrings.push value

            string += propertyStrings.join('\t') + '\n'
        string += ']'
        outBlocks.push(graphProperty + ": " + string)


    console.log 'done serializing'
    return outBlocks.join(blockSeparator)

