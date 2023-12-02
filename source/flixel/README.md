# Modifications from the engine
- Default Sound Tray for mine
- Removed default FlxSave
- Default antialiasing from loaded settings
- Added debug overlay
- Automatically re-scale the camera sizes on game resize
- Hide property methods
- Changed FlxPreloader text font, size and color
- Automatically change stored FlxG on HScript exposure and Modules
- Moved engine state essentials to FlxState and FlxSubState
- FlxText actually reusing graphics and using a custom drawing method
- FlxGraphicsShader added screen vec2 and elapsed float

# Updated (Keeping modifications)
- FlxText -> https://github.com/HaxeFlixel/flixel/pull/2789 & https://github.com/HaxeFlixel/flixel/pull/2846
- FlxSpriteUtil -> https://github.com/HaxeFlixel/flixel/pull/2869
- FlxColor -> Flixel 5.4.0
- FlxAnimationController -> https://github.com/HaxeFlixel/flixel/pull/2913
- FlxSprite -> https://github.com/HaxeFlixel/flixel/pull/2875 & https://github.com/HaxeFlixel/flixel/pull/2881
- FlxColorTransformUtil -> https://github.com/HaxeFlixel/flixel/pull/2875
- FlxSubState -> https://github.com/HaxeFlixel/flixel/pull/2897

# Notice
These modifications of Flixel will be moved to another repo including modifications to another libraries like OpenFL and Lime which will be required in order to compile the engine

# Flixel 4.11.0