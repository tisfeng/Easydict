#!/bin/sh

#  Script.sh
#  OpenBob
#
#  Created by tisfeng on 2022/11/18.
#  Copyright © 2022 izual. All rights reserved.


#tell application "Safari"
#    activate
#end tell

tell application "System Events"
    tell process "Safari.app"
        keystroke "c" using {command down}
        delay 0.1
        set myData to (the clipboard) as text
        return myData
    end tell
end tell
