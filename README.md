# Hitmarker menu for CSGO

Forum link: https://forums.alliedmods.net/showthread.php?t=330813 <br>

How it works: https://www.youtube.com/watch?v=2ck2jKZY17A&feature=emb_title <br>

### Stuff:
* addons/sourcemod/scripting/.sp - Source code <br>
* addons/sourcemod/plugins/.smx - Compiled plugin<br>
* materials/erasurf/ - Default hitmarkers <br>

### Installation:
Put the .smx file into your server plugins/ folder <br>
Move erasurf/ to your server materials/ folder. *(Make sure your server's fastdl is working)* <br>

### Adding more hitmarkers:
Edit the config files provided using the same format<br>
```
Hitmarkers:
    "Name"
    {
        "path" "path/to/hitmarker" // No .vmt or .vtf
    }

Hitsounds:
    "Name"
    {
        "path" "path/to/sound" // with file ext (.mp3, .wav)
    }
```
