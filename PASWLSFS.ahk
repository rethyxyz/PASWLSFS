; Persistent Application-Specific Window Layout Script with File Storage
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; File to store window layouts
layoutsFilePath := A_ScriptDir "\windowLayouts.txt"

; Dictionary to store layouts for each window based on window class and process ID
windowLayouts := {}

; Function to toggle the capturePos1 flag for a window
ToggleCapturePos1(windowKey) {
    global windowLayouts
    if (windowLayouts[windowKey]["capturePos1"]) {
        windowLayouts[windowKey]["capturePos1"] := false
    } else {
        windowLayouts[windowKey]["capturePos1"] := true
    }
}

; Function to load layouts from file
LoadLayouts() {
    global layoutsFilePath
    global windowLayouts
    FileRead, content, %layoutsFilePath%
    lines := StrSplit(content, "`n", "`r")
    windowLayouts := {}
    for each, line in lines {
        if (line != "") {
            parsed := StrSplit(line, "|")
            windowKey := parsed[1]
            windowLayouts[windowKey] := {"pos1X": parsed[2], "pos1Y": parsed[3], "pos1Width": parsed[4], "pos1Height": parsed[5], "pos2X": parsed[6], "pos2Y": parsed[7], "pos2Width": parsed[8], "pos2Height": parsed[9], "capturePos1": parsed[10] = "true" ? true : false}
        }
    }
}

; Function to save layouts to file
SaveLayouts() {
    global layoutsFilePath
    global windowLayouts
    FileDelete, %layoutsFilePath%
    for windowKey, layout in windowLayouts {
        line := windowKey "|" layout["pos1X"] "|" layout["pos1Y"] "|" layout["pos1Width"] "|" layout["pos1Height"] "|" layout["pos2X"] "|" layout["pos2Y"] "|" layout["pos2Width"] "|" layout["pos2Height"] "|" (layout["capturePos1"] ? "true" : "false")
        FileAppend, %line%`n, %layoutsFilePath%
    }
}

; Load layouts from file at script start
LoadLayouts()

; The rest of the script for setting positions and toggling layouts remains the same,
; but include calls to SaveLayouts() after updating the layouts dictionary

; Example of modifying layout and saving:
F3::
    WinGet, active_id, ID, A  ; Get the active window ID
    WinGetClass, winClass, A  ; Get the window class of the active window
    WinGet, pid, PID, A  ; Get the process ID of the active window
    windowKey := winClass "_" pid  ; Create a unique key for the window based on class and PID
    
    if (!windowLayouts.HasKey(windowKey)) {
        windowLayouts[windowKey] := {"capturePos1": true}  ; Initialize with capturePos1 set to true
    }
    if (windowLayouts[windowKey]["capturePos1"]) {
        ; Capture the first position and size
        WinGetPos, posX, posY, width, height, A
        windowLayouts[windowKey]["pos1X"] := posX, windowLayouts[windowKey]["pos1Y"] := posY
        windowLayouts[windowKey]["pos1Width"] := width, windowLayouts[windowKey]["pos1Height"] := height
        MsgBox, % "Position 1 for window with PID " pid " set."
    } else {
        ; Capture the second position and size
        WinGetPos, posX, posY, width, height, A
        windowLayouts[windowKey]["pos2X"] := posX, windowLayouts[windowKey]["pos2Y"] := posY
        windowLayouts[windowKey]["pos2Width"] := width, windowLayouts[windowKey]["pos2Height"] := height
        MsgBox, % "Position 2 for window with PID " pid " set."
    }
    ToggleCapturePos1(windowKey)  ; Toggle the flag for next capture
    ; Existing logic to set layout...
    SaveLayouts()  ; Call after updating layout
return

F5::
    WinGet, active_id, ID, A  ; Get the active window ID
    WinGetClass, winClass, A  ; Get the window class of the active window
    WinGet, pid, PID, A  ; Get the process ID of the active window
    windowKey := winClass "_" pid  ; Create a unique key for the window based on class and PID
    
    if (!windowLayouts.HasKey(windowKey)) {
        MsgBox, % "No layouts found for window with PID " pid ". Please set positions first with F5."
        return
    }
    
    ; Ensure the window is not set to Always On Top before moving
    WinSet, AlwaysOnTop, Off, ahk_id %active_id%
    
    layout := windowLayouts[windowKey]
    WinGetPos, currentX, currentY, currentWidth, currentHeight, A
    ; Determine if the window is closer to position 1 or position 2 and toggle accordingly
    dx1 := Abs(currentX - layout["pos1X"]), dy1 := Abs(currentY - layout["pos1Y"])
    dx2 := Abs(currentX - layout["pos2X"]), dy2 := Abs(currentY - layout["pos2Y"])
    if (dx1 + dy1 < dx2 + dy2) {  ; Closer to position 1, so move to position 2
        WinMove, A, , % layout["pos2X"], % layout["pos2Y"], % layout["pos2Width"], % layout["pos2Height"]
    } else {  ; Closer to position 2 or same, so move to position 1
        WinMove, A, , % layout["pos1X"], % layout["pos1Y"], % layout["pos1Width"], % layout["pos1Height"]
	}
return
