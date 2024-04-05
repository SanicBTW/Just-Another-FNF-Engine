package funkin.states;

import backend.Cache;
import backend.Extensions;
import backend.Save;
import backend.input.Controls;
import backend.io.Path;
import base.MusicBeatState;
import base.TransitionState;
import base.sprites.*;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ChartLoader.VirtSong;
import funkin.SongTools.SongData;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.zip.Entry;
import haxe.zip.Reader;
import lime.math.Vector2;
import lime.media.AudioBuffer;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

// FileSystem selection
class FSSelection extends MusicBeatState
{
	private var grpOptions:FlxTypedGroup<SongEntry>;
	private var curSelected(default, set):Int = 0;

	@:noCompletion
	private function set_curSelected(value:Int):Int
	{
		curSelected += value;

		if (curSelected < 0)
			curSelected = grpOptions.members.length - 1;
		if (curSelected >= grpOptions.members.length)
			curSelected = 0;

		var tf:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = tf - curSelected;
			tf++;

			item.bg.alpha = 0.35;
			item.text.alpha = 0.65;
			item.targetX = 1.5;

			if (item.targetY == 0)
			{
				item.bg.alpha = 0.55;
				item.text.alpha = 0.85;
				item.targetX = 0;
			}
		}

		return curSelected;
	}

	private var canPress:Bool = true;
	private var holdTime:Float = 0;

	private var bg:StateBG;
	private var options:Array<String> = ["Upload Chart", "Upload Inst", "Upload Voices (Optional)", "Done"];
	private var done:Array<Bool> = [];
	private var curState:String = "listing";

	private var chart:SongData = null;
	private var inst:Bytes = null;
	private var voices:Bytes = null;

	override function create()
	{
		bg = new StateBG('menuBG');
		add(bg);

		grpOptions = new FlxTypedGroup<SongEntry>();
		add(grpOptions);

		super.create();

		freshenEntries();
		addTouchControls(DPAD, UP_DOWN, A_B);
	}

	function showDialog()
	{
		var fr:FileReference = new FileReference();
		fr.addEventListener(Event.SELECT, _onSelect, false, 0, true);
		fr.addEventListener(Event.CANCEL, _onCancel, false, 0, true);
		fr.browse();
	}

	function _onSelect(E:Event):Void
	{
		var fr:FileReference = cast(E.target, FileReference);
		fr.addEventListener(Event.COMPLETE, _onLoad, false, 0, true);
		fr.load();
	}

	function _onLoad(E:Event):Void
	{
		var fr:FileReference = cast E.target;
		fr.removeEventListener(Event.COMPLETE, _onLoad);

		var bytes:ByteArray = fr.data;

		// dumbass -mb og
		if (bytes.position > 0 || bytes.length > fr.data.length)
		{
			var copy = new ByteArray(fr.data.length);
			copy.writeBytes(bytes, bytes.position, fr.data.length);
			bytes = copy;
		}

		// TODO: improve this shi lmao
		switch (curState)
		{
			case "upload chart":
				if (Path.extension(fr.name) != "json")
					return;

				chart = SongTools.loadSong(bytes.toString());

			case "upload inst":
				if (chart == null && (Path.extension(fr.name) != "ogg" #if html5 || Path.extension(fr.name) != "mp3" #end))
					return;

				inst = Bytes.ofData(bytes);

			case "upload voices (optional)":
				if ((chart == null && (Path.extension(fr.name) != "ogg" #if html5 || Path.extension(fr.name) != "mp3" #end))
					|| chart != null
					&& !chart.needsVoices)
					return;

				voices = Bytes.ofData(bytes);
		}

		curState = "idle";
		done.push(true);
	}

	function _onCancel(_):Void
	{
		trace("Cancelled");
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_DOWN.state == PRESSED || controls.UI_UP.state == PRESSED)
		{
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
			{
				curSelected = (checkNewHold - checkLastHold) * (controls.UI_UP.state == PRESSED ? -1 : 1);
			}
		}

		super.update(elapsed);
	}

	override function onActionPressed(action:ActionType)
	{
		if (!canPress)
			return;

		switch (action)
		{
			default:
				return;

			case UI_UP:
				curSelected = -1;

			case UI_DOWN:
				curSelected = 1;

			case CONFIRM:
				canPress = false;

				if (curState == "listing" && grpOptions.members[curSelected].text.text != "Add new song")
				{
					ChartLoader.overridenLoad = true;
					SongSelection.songSelected.songName = grpOptions.members[curSelected].text.text;

					// Run first to load chart lmfao
					ChartLoader.loadVFSChart(SongSelection.songSelected.songName, false).then((_) ->
					{
						TransitionState.switchState(new PlayState());
					});
					return;
				}

				if (curState == "listing" && grpOptions.members[curSelected].text.text == "Add new song")
				{
					curState = "idle";
					regenMenu(options);
					return;
				}

				var option:String = options[curSelected].toLowerCase();
				switch (option)
				{
					default:
						curState = option;
						showDialog();

					case "done":
						if (chart != null && chart.needsVoices && done.length != 3 || chart != null && !chart.needsVoices && done.length != 2)
							return;

						// im dumb okay
						var saveStruct:VirtSong = {
							chart: chart,
							inst: inst,
							voices: voices
						};

						Save.database.shouldPreprocess = false;
						Save.database.set(VFS, chart.song, saveStruct).then((r) ->
						{
							if (r)
							{
								freshenEntries();
								chart = null;
								inst = voices = null;
							}
						});
				}

			case BACK:
				if (curState == "idle")
				{
					freshenEntries();
					return;
				}

				if (curState != "listing") // avoid anything complicated
					return;

				canPress = false;
				TransitionState.switchState(new SongSelection());
		}
	}

	override function onActionReleased(action:ActionType)
	{
		canPress = true;
		holdTime = 0;
	}

	function regenMenu(array:Array<String>)
	{
		for (i in 0...grpOptions.members.length)
		{
			grpOptions.remove(grpOptions.members[0], true);
		}

		for (i in 0...array.length)
		{
			var entry:SongEntry = new SongEntry(0, 220, 700, array[i], 28);
			entry.initialPositions.x = (FlxG.width - entry.width) / 2;
			entry.targetY = i;
			entry.text.autoSize = false;
			entry.text.color = FlxColor.WHITE;
			entry.text.font = Paths.font("funkin.otf");
			entry.text.alignment = CENTER;
			grpOptions.add(entry);
		}
		curSelected = grpOptions.length + 1;
	}

	function freshenEntries()
	{
		Save.database.shouldPreprocess = false;
		Save.database.entries(VFS).then((songs) ->
		{
			var regen:Array<String> = [];
			for (sName in songs.keys())
			{
				if (sName == "length")
					continue;

				regen.push(sName);
			}
			regen.push("Add new song");
			regenMenu(regen);
			curState = "listing";
		});
	}
}

// just a copy of BindEntry from RebindingState

@:publicFields
class SongEntry extends FlxSpriteGroup
{
	var bg:PillSprite;
	var text:FlxText;

	var targetX:Float = 0;
	var targetY:Float = 0;
	var initialPositions:Vector2 = new Vector2(0, 0);

	override public function new(X:Float, Y:Float, FieldWidth:Float, Text:String, Size:Int)
	{
		super(X, Y);

		initialPositions.setTo(X, Y);

		text = new FlxText(0, 0, FieldWidth, Text, Size, true);
		bg = new PillSprite(0, 0, Math.floor(text.width + 25), Math.floor(text.height + 25), FlxColor.BLACK);

		text.setPosition((bg.width - text.width) / 2, (bg.height - text.height) / 2);

		add(bg);
		add(text);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = FlxMath.bound(elapsed * 9.6, 0, 1);
		x = FlxMath.lerp(x, (targetX * text.size / 2) + initialPositions.x, lerpVal);
		y = FlxMath.lerp(y, (targetY * 1.3 * height) + initialPositions.y, lerpVal);

		super.update(elapsed);
	}
}
