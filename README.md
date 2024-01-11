# dynamics-humaniser
Tool for humanising CC1 values by means of Channel pressure values.

This script is made for [Reaper DAW](https://www.reaper.fm/).

This tool should help you archieve more realistic CC1 programming in case you draw CC1 values by mouse or you have them generated by a script (such as my [Musescore_CS_converter.lua](https://github.com/3YY3/musescore4-CS-converter/))

# How to use
You need to have already some CC1 values present, either done by hand or generated by script, as mentioned earlier. Then you need to record Channel pressure values. For this task you can use either pressure sensitive pad of some MIDI keyboard, or even breath controller.

While in the MIDI editor, run the script and select *coeficient* value (how much will CC1 be altered by Channel pressure values) and method:
- *Add-subtract* - If the Channel pressure value is higher than 63, value will be added, otherwise subtracted
- *Add-above* - Adds channel pressure on top of CC1
- *Add-below* - Subtracts the channel pressure from CC1

Which method you use is based on personal prefference and also type of physical controller you use (pressure pad, breath controller, etc.)

In the picture demo.png you can see what will happen upon using the script. Original MIDI events are on the left side of the picture, altered events by the script are on the right.

# Dependencies
In order to use this script, you need to install:
- [Scythe v3](https://jalovatt.github.io/scythe/#/)
- [MIDI Utils](https://forum.cockos.com/showthread.php?p=2630436)
