
function isRequested(character) {
    if (character.length != 5) {
        throw new Error("invalid argument. it's not a character")
    }
    name = peoplenames[character[0]]
    return true
    return (
        // name == 'Rose' ||
        name == 'John' ||
        name == 'Dave' ||
        false
    )
}

var panelStart = 1991 // 006009 - 30; // 1901
var panelEnd   = 2300 // 006009 + 10;

// select a subset of panelIDs
var panelIDs = []
for (var panelID=panelStart; panelID<panelEnd; ++panelID) {
    if (panelID in timelines) {
        panelIDs.push(panelID)
    }
    else {
        // console.log("panel doesn't exist: " + panelID)
    }
}


function deepCopy(obj) {
    return JSON.parse(JSON.stringify(obj))
}



// add panels that are selected by ID
// if they contain a requested character
newTimelines = []
newPanelIDs = []
panelIDs.forEach(function(panelID) {
    characters = timelines[panelID]
    var hasRequestedCharacter = false
    characters.forEach(function (character) {
        if (isRequested(character)) {
            hasRequestedCharacter = true;
        }
    })

    if (hasRequestedCharacter) {
        newTimelines[panelID] = deepCopy(characters)
        newPanelIDs.push(panelID)
    }
})


// if there is a unwanted character, remove their links
newPanelIDs.forEach(function(panelID) {
    newTimelines[panelID].forEach(function (character) {
        if (!isRequested(character)) {
            character[4] = []
        }
    })
})



// add panels that are being linked to
// if we don't have them
// but without their links
toAddPanelIDs = []
newPanelIDs.forEach(function(panelID) {
    newTimelines[panelID].forEach(function (character) {
        character[4].forEach(function (link) {
            if (!(link[0] in newTimelines)) {
                if (link[0] in timelines) {
                    // console.log("panel was linked and added: " + link[0])

                    // remove all links from new panel
                    newLinkedCharacters = []
                    timelines[panelID].forEach(function (linkedCharacter) {
                        newLinkedCharacter = deepCopy(linkedCharacter)
                        newLinkedCharacter[4] = []
                        newLinkedCharacters.push(newLinkedCharacter)
                    })

                    newTimelines[panelID] = newLinkedCharacters
                    toAddPanelIDs.push(panelID)
                }
                else {
                    console.warn("panel was linked but doesn't exist: " + link[0])
                }
            }
            else {
                // console.log("link in newTimelines: " + link[0])
            }

        })
    })
})

// add the newly added nodes to the list
Array.prototype.push.apply(newPanelIDs, toAddPanelIDs)



// for each link, decrement their character index by
// how many non-requested characters are below that index
newPanelIDs.forEach(function(panelID) {
    newTimelines[panelID].forEach(function (character) {
        character[4].forEach(function (link) {
            originalIndex = link[1]
            for (var charIndex=0; charIndex<originalIndex; ++charIndex) {
                if (!isRequested(timelines[link[0]][charIndex])) {
                    link[1] -= 1
                }
            }
        })
    })
})
// remove all non-requested characters
newPanelIDs.forEach(function(panelID) {
    newTimelines[panelID] = newTimelines[panelID].filter(isRequested)
})








// overwrite the timeline variable
panelIDs = newPanelIDs
timelines = newTimelines


