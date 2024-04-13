package funkin.states.start;

import backend.Conductor;
import backend.input.Controls.ActionType;
import backend.scripting.*;
import base.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.ds.StringMap;

// Ok when I said "modular" I didn't say let the user cook its own title screen without any help :sob:
class TitleState extends MusicBeatState
{
	private var module:ForeverModule;

	override public function create()
	{
		Conductor.reset();

		var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
		exposure.set('title', this);
		exposure.set('add', add);
		exposure.set('remove', remove);

		module = ScriptHandler.loadModule("TitleState", "scripts", exposure);
		if (module != null)
		{
			module.set("introText", FlxG.random.getObject(getIntroText()));
			module.set("onEnded", () ->
			{
				TransitionState.switchState(new SongSelection());
			});
		}

		super.create();

		new FlxTimer().start(1, (_) ->
		{
			init();
		});
	}

	private function init()
	{
		if (FlxG.sound.music == null)
		{
			var meta:{music:String, bpm:Float} = (module != null) ? module.get("MusicMeta")() : {
				music: "freakyMenuOG",
				bpm: 102,
			};

			// precaching hehe
			FlxG.sound.playMusic(Paths.music(meta.music));
			FlxG.sound.music.pause();

			Conductor.changeBPM(meta.bpm, false);

			#if debug
			trace(meta);
			#end
		}

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alive = false;
		add(bg);

		if (module != null)
			module.get("onStartIntro")();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (module != null)
			module.get("onUpdate")(elapsed);
	}

	override function onActionPressed(action:ActionType)
	{
		if (action == CONFIRM && module != null)
			module.get("onConfirm")();
	}

	private function getIntroText():Array<Array<String>>
	{
		var text:String = Paths.txt("introText");
		var lines:Array<String> = text.split("\n");
		var ret:Array<Array<String>> = [];

		for (line in lines)
		{
			ret.push(line.split("--"));
		}

		return ret;
	}
}
