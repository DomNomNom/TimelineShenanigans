var panelIDs;
var containedPanelIDs;

var panelsToSplit = [
    3840,
    4827,  // jade: enter
    6844,  // ascend more casually
    4478,  // make her pay
]


var panelStart = 1991 // 006009 - 30; // 1901
var panelEnd   = 10000 // 006009 + 10;
// var panelStart = 006009 - 3000; // 1901
// var panelEnd   = 006009 + 1000;
console.log('starting with panels ' + panelStart + '..' + panelEnd)


function processTimelines() {
    function isRequested(character) {
        if (character.length != 6) {
            throw new Error("invalid argument. it's not a character: " + JSON.stringify(character))
        }

        group = groups[character[3]]
        requestedGroups = ["Kids' Exiles", "Kids' Agents"]
        isInRequestedGroup = requestedGroups.indexOf(group) >= 0

        name = peoplenames[character[0]]
        requestedNames = ['Rose', 'Dave', 'John', 'Jade']
        hasRequestedName = requestedNames.indexOf(name) >= 0
        return hasRequestedName //|| isInRequestedGroup
        return true
        // return (
        //     name == 'Rose' ||
        //     // name == 'John' ||
        //     name == 'Dave' ||
        //     false
        // )
    }

    function isLinkedByRequestedCharacter(character) {
        // is there a link from a requested character that points to us?
        // .forEach(function (backlink) {
        for (var i=0; i<character[5].length; ++i) {
            var backlink = character[5][i]
            var pastCharacter = oldTimelines[backlink[0]][backlink[1]]
            if (!isRequested(pastCharacter)) {
                continue
            }

            for (var linkIndex=0; linkIndex<pastCharacter[4].length; ++linkIndex) {
                var link = pastCharacter[4][linkIndex]
                forwardCharacter = oldTimelines[link[0]][link[1]]
                if (forwardCharacter === character) {
                    return true
                }

                // carefully look up forwardedCharacter in newTimelines
                if (link[0] in newTimelines) {
                    forwardCharacter = newTimelines[link[0]][link[1]]
                    if (forwardCharacter === character) {
                        return true
                    }

                }

            }
        }
        return false
    }

    function isRelevant(character) {
        return isRequested(character) || isLinkedByRequestedCharacter(character)
    }



    oldTimelines = timelines
    timelines = null // so that we don't display anything in case we fail


    // select a subset of panelIDs
    panelIDs = []
    for (var panelID=panelStart; panelID<panelEnd; ++panelID) {
        if (panelID in oldTimelines) {
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
        characters = oldTimelines[panelID]
        var hasRequestedCharacter = false
        characters.forEach(function (character) {
            if (isRelevant(character)) {
                hasRequestedCharacter = true;
            }
        })

        if (hasRequestedCharacter) {
            newTimelines[panelID] = deepCopy(characters)
            newPanelIDs.push(panelID)
        }
    })


    // if there is non-requested character, remove their links
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
                    if (link[0] in oldTimelines) {
                        // console.log("panel was linked and added: " + link[0])

                        // remove all links from new panel
                        newLinkedCharacters = []
                        oldTimelines[panelID].forEach(function (linkedCharacter) {
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

    // utility to remove two indentation levels
    function forEachLink(callback) {
        newPanelIDs.forEach(function(panelID) {
            newTimelines[panelID].forEach(function (character) {
                character[4].forEach(function (link) {
                    callback(link, panelID)
                })
            })
        })
    }


    function sanityCheck() {
        forEachLink(function (link) {
            if (!(link[0] in newTimelines) || newTimelines[link[0]].length <= link[1]) {
                console.error(link)
                console.error(link[0] in newTimelines)
                console.error(newTimelines[link[0]])

                throw new Error("broken link");
            }
        })
    }

    sanityCheck()



    // for each link, decrement their character index by
    // how many non-relevant characters are below that index
    forEachLink(function (link) {
        originalIndex = link[1]
        for (var charIndex=0; charIndex<originalIndex; ++charIndex) {
            if (!isRelevant(oldTimelines[link[0]][charIndex])) {
                link[1] -= 1
            }
        }
    })
    // remove all non-relevant characters
    newPanelIDs.forEach(function(panelID) {
        newTimelines[panelID] = newTimelines[panelID].filter(isRelevant)
    })



    buildBacklinks(newTimelines)

    sanityCheck()



    // ====== split nodes with excesive links ======

    panelsToSplit.forEach(function (panelID) {
        if (!(panelID in newTimelines)) {  // can't split what's not there
            return
        }

        console.log('splitting panel ' + panelID + ': ' + JSON.stringify(newTimelines[panelID]))
        var characters = newTimelines[panelID]

        for (var charIndex=0; charIndex<characters.length; ++charIndex) {
            var newPanelID = panelID + '[' + charIndex + ']'
            if (newPanelID in newTimelines) {
                throw new Error('newID is ALREADY THERE!')
            }

            newPanel = [ deepCopy(characters[charIndex]) ]
            newTimelines[newPanelID] = newPanel

            console.log('new panel ' + newPanelID + ': ' + JSON.stringify(newPanel))
            newPanel.forEach(function (character) {

                // redirect backlinks of our links
                character[4].forEach(function (link) {
                    newTimelines[link[0]][link[1]][5].forEach(function (backlink) {
                        if (backlink[0] == panelID) {
                            backlink[0] = newPanelID
                            backlink[1] = 0
                        }
                    })
                })

                // redirect links of our backlinks
                character[5].forEach(function (backlink) {
                    newTimelines[backlink[0]][backlink[1]][4].forEach(function (link) {
                        if (link[0] == panelID) {
                            link[0] = newPanelID
                            link[1] = 0
                        }
                    })
                })
            })
        }

        delete newTimelines[panelID]

    })

    // re-do panelIDs
    newPanelIDs = []
    for (var key in newTimelines) {
        newPanelIDs.push(key)
    }

    sanityCheck()









    // ====== start graph contraction ======



    // given a panelID, who links to us?
    parents = {}
    newPanelIDs.forEach(function(panelID) {
        parents[panelID] = {}
    })
    forEachLink(function (link, panelID) {
        parents[link[0]][panelID] = true
    })

    // given a panelID, how many people link to us?
    numParents = {}
    for (var panelID in parents) {
        numParents[panelID] = 0
        for (var parentID in parents[panelID]) {
            numParents[panelID] += 1
        }
    }


    // can we contract with some 'next' node
    function canContract(panelID) {
        var nextPanelID = null
        var nextPanel = null

        if (numParents[nextPanelID] > 1) {
            return false
        }


        if (!(panelID in newTimelines)) {
            throw new Error("newTimelines should have contained id: " + panelID)
        }

        var characters = newTimelines[panelID]

        if (characters.length < 1) {
            // console.log("no links because no characters")
            return false
        }

        for (var charIndex=0; charIndex<characters.length; ++charIndex) {
            character = characters[charIndex]

            links = character[4]
            // console.log("character has multiple or no 'next' panels? " +links.length)

            if (links.length != 1) {
                // console.log("character has multiple or no 'next' panels")
                return false
            }

            link = links[0]

            if (nextPanelID === null) {
                nextPanelID = link[0]
                nextPanel = newTimelines[nextPanelID]

                if (nextPanel.length != newTimelines[panelID].length) {
                    // console.log("next panel has a different ")
                    return false
                }

                if (numParents[nextPanelID] > 1) {
                    // console.log("the next panel has multiple parent panels")
                    return false
                }
                if (numParents[nextPanelID] < 1) {
                    // console.error("numParents: " + numParents[nextPanelID])
                    // console.error("from: " + panelID)
                    // console.error("from.. " + JSON.stringify(newTimelines[panelID]))
                    // console.error("newTimelines: " + JSON.stringify(newTimelines[nextPanelID]))
                    throw new Error("The number of parents is obviously wrong: " + nextPanelID)
                }
            }
            else {  // we already have a 'next'
                if (link[0] != nextPanelID) {
                    // console.log("not all characters link to the same panel")
                    return false
                }
            }


            // test whether the next character is the same
            nextCharacter = nextPanel[link[1]]
            for (var prop=0; prop<4; ++prop) {
                if (nextCharacter[prop] != character[prop]) {
                    // console.log("next character properties don't match")
                    return false
                }
            }

        }

        return true
    }



    function isEmpty(obj) {
        for (var key in obj) {
            return false
        }
        return true
    }

    // pop a key from a object as if it were a set
    function pop(obj) {
        for (var key in obj) {
            var result = key;
            // If the property can't be deleted fail with an error.
            if (!delete obj[key]) { throw new Error(); }
            return result;
        }
    }

    toContract = {}
    containedPanelIDs = {}
    newPanelIDs.forEach(function(panelID) {
        if (parseInt(panelID) == NaN) {
            throw new Error("all panelIDs should be numbers")
        }
        toContract[panelID] = true
        containedPanelIDs[panelID] = [ panelID ]
    })

    linearSegments = {}
    // keep contracting until we went through all nodes
    while (!isEmpty(toContract)) {
        startPanelID = pop(toContract)

        currentPanelID = startPanelID
        while (canContract(currentPanelID)) {
            currentCharacters = newTimelines[currentPanelID]
            currentPanelID = currentCharacters[0][4][0][0]  // get the 1st linked panel of the 1st character
            if (currentPanelID in toContract) {
                delete toContract[currentPanelID]
            }
            if (currentPanelID in linearSegments) {
                delete linearSegments[currentPanelID]
            }

            // add the linked contraction to the start contraction
            Array.prototype.push.apply(
                containedPanelIDs[startPanelID],
                containedPanelIDs[currentPanelID]
            )
            delete containedPanelIDs[currentPanelID]

        }

        linearSegments[startPanelID] = newTimelines[currentPanelID]
    }


    // overwrite the timeline variable
    timelines = linearSegments
    panelIDs = []
    for (panelID in timelines) {
        panelIDs.push(panelID)
    }

}

