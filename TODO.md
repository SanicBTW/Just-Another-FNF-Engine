Add proper Soloud support
- set an audio handle for soloud on FlxSound?

Transitions between states
- everything on a file and music beat state extends from it
- separated files
- think about a proper name for the state handling (not scriptable state cuz its not scriptable [why did even yoshubs call it like this on fe rewrite])
- uhhhhhhhhh

Controls
- possible script:
```haxe
    var tracking:Actions = UI

    abstract enum Actions
    {
        var NOTES = "noteMap";
        var UI = "uiMap";
    }

    /* on listener get the map specified in the control schema by reflect
     * and force the system actions too
     * and shit like that should be pretty easy - sanco 2023 13/05
     * it isnt bro - sanco 2023 14/05
    */
```
- make it use a custom variable to listen keypress through Reflect or casting state as the state type controls

Paths
- new library system (instead of having one single preloaded, separate the files between libraries and follow a file tree schema)

Add proper network cache
- its hard wtf