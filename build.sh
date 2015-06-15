#!/bin/bash

if ( cake sbuild )  then
        echo "done compiling"

        # launch or refresh a browser pointing at the website
        windowID=$(xdotool search --name localhost:8000)
        if [[ $windowID == "" ]]
        then
            echo "launching browser"
            chromium-browser http://localhost:8000
            sleep 0.5
            windowID=$(xdotool search --name localhost:8000)
            xdotool windowactivate $windowID
        else
            xdotool windowactivate $windowID
            sleep 1.0
            xdotool key F5
        fi
        echo "browser should have refreshed now"
fi

