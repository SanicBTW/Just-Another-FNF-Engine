
legend

```
    * : will work on it
    ? : dunno
    - next : next commit will have these changes hopefully
    nothing : someday
```

# counters

Add a compilation flag to disable counters completely or make them basic, like old times ?

# parsing

properly parse paths and fallbacks, splashes and shit

# new library system (currently 20/80 chances to actually work on it, if i dont work on this i will end up doing it for the mod system)

move to custom library support using ini files (crazy hard i guess) [basically do like support native libraries but build the manifest on runtime and save it on the device local storage (html5 save it on local storage or idb??) they are just file path references anyways, what about the preloader tho]

https://lime.openfl.org/api/lime/utils/AssetManifest.html

https://lime.openfl.org/api/lime/utils/Preloader.html

# old experimental shit (from scrolling&backend-rewrite)

use new conductor (see new-condcutor branch)

add Vanilla Paths filesystem support (not using IsolatedPaths rn)

# hxs

make it that when a character changes change the reference on modules - next

change player to boyfriend and opponent to dad on module vars - next

# async 

fix network requests on sys with background thread, make it look more alike js fetch ?

# saving

base classes for different management
- for example: SQLTable manages tables inheriting from a SQL Class that contains the connections and stuff (most likely to get removed)

it should be easier to rewrite and format with that type of schema

extend table management on system (cuz idb sucks ass and i cannot create tables on runtime) (most likely to get removed)

encryption options, i gotta use Haxe serializers as a base and then encrypt the given string on given format, maybe i will let the user choose encryption although its kinda useless since its just saving data *

THE CODE COMPATIBILITY HAS GONE TO ANOTHER PATH FROM WHAT I HAD PLANNED SO I WILL TRY TO RECOVER IT
- make it promise based on both ends *

# splashes

fix splashes (null function pointer bruh, dunno what its causing it)

# states

settings states *
main menu state *
title state *