--[[
Dynamics translator for controlling Cinematic Studio Libraries with input from Musescore 4
Dynamics_Humaniser.lua
Copyright © 2023 3YY3, MIT License
Not affiliated with Cinematic Studio Series in any way.
]]--


--Default values
coefficient = 0
-- Real GUI default values are located at the end of the GUI section. Their setting 
-- is bugged in slider element so one needs to set values manually. Manual
-- setting is done in a super-shitty 'additive' way dependent on min max values,
-- horizontal/vertical type and increment value of particular slider. Take care.

--End


--Get the package path to MIDIUtils 
 package.path = reaper.GetResourcePath() .. '/Scripts/sockmonkey72 Scripts/MIDI/?.lua'
local mu = require 'MIDIUtils'
--End


--Scythe GUI initialization
local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please install 'Scythe library v3' from ReaPack, then run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")()
--End


--Error messages and checks
function takeError()
    reaper.ShowMessageBox("Please, open some MIDI take in editor first.", "Error", 0)
end

function takeCheck(check) -- REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR 
    local check = true
    local noteFound = false
    local totalcnt, notecnt, cccnt = reaper.MIDI_CountEvts(take) -- Count everything, analyse what is channel pressure event and count them?
    for i = 0, notecnt, 1 do
        local _, sel = reaper.MIDI_GetNote(take, i)
        if sel == true then
            noteFound = true
        end
    end
    if cccnt == 0 then
        reaper.ShowMessageBox("No channel pressure events to alter!", "Error", 0)
        check = false
    end
    return check
end
--End


--CC1 event table
local eventTable = {}
function readEventTable()
    for _, eventInfo in ipairs(eventTable) do
        local ppqpos = eventInfo.ppqpos
        local value = eventInfo.value
        local mode = eventInfo.mode
        local id = eventInfo.id

        if mode == "INSERT" then -- Insert new CC events using eventTable

            -- Insert CC1 event with the desired value
            reaper.MIDI_InsertCC(take, false, false, ppqpos, 0xB0, 0, 1, value)

            -- Set the desired CC shape to bezier
            local _, _, cccnt = reaper.MIDI_CountEvts(take)
            for i = 0, cccnt, 1 do
                local _, _, _, ccppqpos = reaper.MIDI_GetCC(take, i)
                if ccppqpos == ppqpos then
                    reaper.MIDI_SetCCShape(take, i, 5, 0)
                end
            end

        elseif mode == "SET" then -- Change already existing CC events using eventTable
            reaper.MIDI_SetCC(take, id, false, false, ppqpos, 0xB0, 0, 1, value)
        end

    end
end
--End




--Button click function
function btnClick()
    coefficient = GUI.Val("CoefficientSlider")
    local method = GUI.Val("MethodMenubox")

    if method == 1 then -- Add-subtract
        redrawCC1_addsubtract()
    elseif method == 2 then -- Add above
        redrawCC1_addabove()
    elseif method == 3 then -- Add below
        redrawCC1_addbelow()
    end

    window:close()
end
--End


--Shaper add above
function redrawCC1_addabove()
    local totalcnt, notecnt, cccnt = reaper.MIDI_CountEvts(take)
    totalcnt = totalcnt * 3 -- Multiplication done because MIDI.CountEvts() function sucks and lies

    -- Already existing CC1 event (here, evtValue is cc number) ; Has to run before pressure event type loop because of IDs of CC events
    for i = 0, totalcnt, 1 do
        local _, _, _, ppqpos, chanmsg, chan, evtValue, ccValue = reaper.MIDI_GetCC(take, i)
        local presentTime = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)
        local _, presentCC1Val = mu.MIDI_GetCCValueAtTime(take, 0xB0, 0, 1, presentTime)
        local _, presentCPVal = mu.MIDI_GetCCValueAtTime(take, 0xD0, 0, nil, presentTime)
        if chanmsg == 0xB0 and evtValue == 1 then 
            local newCC1Val = math.floor((presentCPVal * coefficient) + ccValue)
            if newCC1Val > 127 then
                newCC1Val = 127
            elseif newCC1Val < 1 then -- CS libraries are silent at value 0
                newCC1Val = 1
            end
            table.insert(eventTable, {ppqpos = ppqpos, value = newCC1Val, mode = "SET", id=i})
        end
    end

    -- Channel Pressure event type (here, evtValue is channel pressure value)
    for j = 0, totalcnt, 1 do
        local _, _, _, ppqpos, chanmsg, chan, evtValue, ccValue = reaper.MIDI_GetCC(take, j)
        local presentTime = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)
        local _, presentCC1Val = mu.MIDI_GetCCValueAtTime(take, 0xB0, 0, 1, presentTime)
        if chanmsg == 0xD0 then 
            local newCC1Val = math.floor((evtValue * coefficient) + presentCC1Val)
            if newCC1Val > 127 then
                newCC1Val = 127
            elseif newCC1Val < 1 then -- CS libraries are silent at value 0
                newCC1Val = 1
            end
            table.insert(eventTable, {ppqpos = ppqpos, value = newCC1Val, mode = "INSERT", id = 0})
        end
    end

    -- Process what is written in the event table
    readEventTable()
end
--End


--Shaper add-subtract
function redrawCC1_addsubtract()
    local totalcnt, notecnt, cccnt = reaper.MIDI_CountEvts(take)
    totalcnt = totalcnt * 3 -- Multiplication done because MIDI.CountEvts() function sucks and lies

    -- Already existing CC1 event (here, evtValue is cc number) ; Has to run before pressure event type loop because of IDs of CC events
    for i = 0, totalcnt, 1 do
        local _, _, _, ppqpos, chanmsg, chan, evtValue, ccValue = reaper.MIDI_GetCC(take, i) 
        local presentTime = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)
        local _, presentCC1Val = mu.MIDI_GetCCValueAtTime(take, 0xB0, 0, 1, presentTime)
        local _, presentCPVal = mu.MIDI_GetCCValueAtTime(take, 0xD0, 0, nil, presentTime)
        if chanmsg == 0xB0 and evtValue == 1 then
            local newCC1Val = 0
            if ccValue >= 0 and ccValue <= 63 then
                newCC1Val = math.floor(ccValue - ((63 - presentCPVal) * coefficient / 2))
            elseif ccValue >= 64 and ccValue <= 127 then
                newCC1Val = math.floor(ccValue + ((presentCPVal - 63) * coefficient / 2))
            end
            if newCC1Val > 127 then
                newCC1Val = 127
            elseif newCC1Val < 1 then -- CS libraries are silent at value 0
                newCC1Val = 1
            end
            table.insert(eventTable, {ppqpos = ppqpos, value = newCC1Val, mode = "SET", id=i})
        end
    end

    -- Channel Pressure event type (here, evtValue is channel pressure value)
    for j = 0, totalcnt, 1 do
        local _, _, _, ppqpos, chanmsg, chan, evtValue, ccValue = reaper.MIDI_GetCC(take, j)
        local presentTime = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)
        local _, presentCC1Val = mu.MIDI_GetCCValueAtTime(take, 0xB0, 0, 1, presentTime)
        if chanmsg == 0xD0 then 
            local newCC1Val = 0
            if evtValue >= 0 and evtValue <= 63 then
                newCC1Val = math.floor(presentCC1Val - ((63 - evtValue) * coefficient / 2)) -- REPAIR-addcpval   REPAIR-addcpval   REPAIR-addcpval   REPAIR-addcpval   REPAIR-addcpval   REPAIR-addcpval   
            elseif evtValue >= 64 and evtValue <= 127 then
                newCC1Val = math.floor(presentCC1Val + ((evtValue - 63) * coefficient / 2)) -- REPAIR-addcpval   REPAIR-addcpval   REPAIR-addcpval   REPAIR-addcpval   REPAIR-addcpval   REPAIR-addcpval   
            end
            if newCC1Val > 127 then
                newCC1Val = 127
            elseif newCC1Val < 1 then -- CS libraries are silent at value 0
                newCC1Val = 1
            end
            table.insert(eventTable, {ppqpos = ppqpos, value = newCC1Val, mode = "INSERT", id=0})
        end
    end

    -- Process what is written in the event table
    readEventTable()
end
--End


--Shaper add below
function redrawCC1_addbelow()
    local totalcnt, notecnt, cccnt = reaper.MIDI_CountEvts(take)
    totalcnt = totalcnt * 3 -- Multiplication done because MIDI.CountEvts() function sucks and lies

    -- Already existing CC1 event (here, evtValue is cc number) ; Has to run before pressure event type loop because of IDs of CC events
    for i = 0, totalcnt, 1 do
        local _, _, _, ppqpos, chanmsg, chan, evtValue, ccValue = reaper.MIDI_GetCC(take, i)
        local presentTime = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)
        local _, presentCC1Val = mu.MIDI_GetCCValueAtTime(take, 0xB0, 0, 1, presentTime)
        local _, presentCPVal = mu.MIDI_GetCCValueAtTime(take, 0xD0, 0, nil, presentTime)
        local offset = 127 * coefficient
        if chanmsg == 0xB0 and evtValue == 1 then 
            local newCC1Val = math.floor((presentCPVal * coefficient) + ccValue - offset)
            if newCC1Val > 127 then
                newCC1Val = 127
            elseif newCC1Val < 1 then -- CS libraries are silent at value 0
                newCC1Val = 1
            end
            table.insert(eventTable, {ppqpos = ppqpos, value = newCC1Val, mode = "SET", id=i})
        end
    end

    -- Channel Pressure event type (here, evtValue is channel pressure value)
    for j = 0, totalcnt, 1 do
        local _, _, _, ppqpos, chanmsg, chan, evtValue, ccValue = reaper.MIDI_GetCC(take, j)
        local presentTime = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)
        local _, presentCC1Val = mu.MIDI_GetCCValueAtTime(take, 0xB0, 0, 1, presentTime)
        local offset = 127 * coefficient
        if chanmsg == 0xD0 then 
            local newCC1Val = math.floor((evtValue * coefficient) + presentCC1Val - offset)
            if newCC1Val > 127 then
                newCC1Val = 127
            elseif newCC1Val < 1 then -- CS libraries are silent at value 0
                newCC1Val = 1
            end
            table.insert(eventTable, {ppqpos = ppqpos, value = newCC1Val, mode = "INSERT", id = 0})
        end
    end

    -- Process what is written in the event table
    readEventTable()
end
--End


function Main()
    take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
    if take then
        local check = takeCheck(check)
        if check == true then
    --GUI layout----------------------------------------------------------------
            GUI = require("gui.core")

            window = GUI.createWindow({
                name = "Dynamics Humaniser",
                w = 228,
                h = 460,
            })

            layer = GUI.createLayer({
                name = "MainLayer"
            })
            layer:addElements( GUI.createElements(
                {
                name = "ApplyBtn",
                type = "Button",
                x = 128,
                y = 368,
                w = 64,
                h = 48,
                caption = "Apply",
                func = btnClick
                },
                {
                name = "CoefficientSlider",
                type = "Slider",
                x = 32,
                y = 32,
                w = 384,
                h = 32,
                min = 0,
                max = 0.6,
                inc = 0.01,
                horizontal = false,
                defaults = coefficient,
                showHandles = true,
                showValues = true,
                captionX = 32,
                caption = "Coefficient (0-100%)"
                },
                {
                name = "MethodMenubox",
                type = "Menubox",
                x = 100,
                y = 40,
                w = 108,
                h = 24,
                options = {"Add-Subtract", "Add above", "Add below" },
                caption = ""
                }
            ))

            window:addLayers(layer)
            
            window:open()
            GUI.Main()
            GUI.Val("CoefficientSlider", 40) -- Set 0.2: increment by 0.01, so value has to be 100 times more. Maximum value is 0.6, so: 0.6 - 40/100 = 0.2
    --End-----------------------------------------------------------------------
            reaper.UpdateArrange()
        end
    else 
        --takeError() -- REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR REPAIR 
    end
end

reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Dynamic Humaniser", -1)
reaper.UpdateArrange()