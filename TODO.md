Add proper Soloud support
- set an audio handle for soloud on FlxSound?

Transitions between states
- everything on a file and music beat state extends from it
- separated files
- think about a proper name for the state handling (not scriptable state cuz its not scriptable [why did even yoshubs call it like this on fe rewrite])
- uhhhhhhhhh

Paths
- new library system (instead of having one single preloaded, separate the files between libraries and follow a file tree schema)

Add proper network cache
- its hard wtf

Improve Filesystem operations (IO) and the temp shit lol (it keeps throwing null on closing and cleanin files bru)

Fix the fucking cache

FlxText keeps crashing the game when FlxGraphic.defaultPersist = true