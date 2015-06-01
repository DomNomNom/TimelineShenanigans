

function buildBacklinks() {
    // add a 6th property to each character in each panel: back links
    for (var panelID in timelines) {
        timelines[panelID].forEach(function (character) {
            character.push([])
        })
    }

    for (var panelID in timelines) {
        characters = timelines[panelID]
        for (var charIndex=0; charIndex<characters.length; ++charIndex) {
            characters[charIndex][4].forEach(function (link) {
                targetCharacter = timelines[link[0]][link[1]]
                targetCharacter[5].push([panelID, charIndex])
            })
        }
    }


    // sanity check that all backlinks have a forward link
    for (var panelID in timelines) {
        characters = timelines[panelID]
        for (var charIndex=0; charIndex<characters.length; ++charIndex) {
            characters[charIndex][5].forEach(function (backlink) {
                targetCharacter = timelines[backlink[0]][backlink[1]]
                var hasForwardLink = false
                targetCharacter[4].forEach(function (link) {
                    if (link[0] == panelID  &&  link[1] == charIndex) {
                        hasForwardLink = true
                    }
                })

                if (!hasForwardLink) {
                    throw new Error("no matching forward link for backlink")
                }
            })
        }
    }

    console.log('backlinks created.')
}

