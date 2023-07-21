Paths
- fix new library system

Add a compilation flag to disable counters completely or make them basic, like old times

properly parse paths and fallbacks, splashes and shit

move to custom library support using ini files (crazy hard i guess) [basically do like support native libraries but build the manifest on runtime and save it on the device local storage (html5 save it on local storage or idb??) they are just file path references anyways, what about the preloader tho]
https://lime.openfl.org/api/lime/utils/AssetManifest.html
https://lime.openfl.org/api/lime/utils/Preloader.html

https://haxe.org/manual/std-Lambda.html
https://github.com/SanicBTW/Just-Another-FNF-Engine/blob/935478c4706f6f1d15788c281e1e6a0c196f5b1a/source/base/system/SqliteKeyValue.hx

fix bullshit io bruhh

add Vanilla Paths filesystem support

fix controls crashing upon pressing on state creation

make it that when a character changes change the reference on modules

change player to boyfriend and opponent to dad on module vars

im so lame with fucking defines (fix FLX_DEFAULT_ASSETS and beep shit)

add note clipping on sustains, events

MOD MANAGER (C# WPF NET 7.0) - gonna try to add them ingame and shit (maybe just download necessary events by the song and after finishing it delete them???)
WILL BE USED FOR DOWNLOADING MOD ASSETS INSTEAD OF BUNDLING THEM WITH THE ENGINE
WILL BE ALSO USED TO DOWNLOAD ALL THE EVENT FILES AND SHIT

add volume panel to flxgame

fix embedding