package funkin.substates.vfs;

import backend.Save;
import backend.input.Controls.ActionType;
import backend.io.Path;
import base.MusicBeatState.MusicBeatSubState;
import base.TransitionState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.ChartLoader.VirtSong;
import funkin.SongTools.SongData;
import funkin.states.*;
import funkin.states.VFSManagement.SongEntry;
import haxe.io.Bytes;
import openfl.events.Event;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

class SongUpload extends MusicBeatSubState
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

	private var options:Array<String> = ["Upload Chart", "Upload Inst", "Upload Voices (Optional)", "Done"];
	private var done:Array<Bool> = [];
	private var curState:String = "idle";

	private var chart:SongData = null;
	private var inst:Bytes = null;
	private var voices:Bytes = null;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		grpOptions = new FlxTypedGroup<SongEntry>();
		add(grpOptions);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		regenMenu(options);

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
				if (chart == null && (Path.extension(fr.name) != "ogg" #if html5 || Path.extension(fr.name) != "mp3" #end))
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

				var option:String = options[curSelected].toLowerCase();
				switch (option)
				{
					case "upload chart" | "upload inst":
						curState = option;
						showDialog();

					case "upload voices (optional)":
						if (chart != null && !chart.needsVoices)
							return;

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
								@:privateAccess
								{
									cast(FlxG.state, VFSManagement).canPress = true;
									cast(FlxG.state, VFSManagement).onActionPressed(BACK);
								}
								chart = null;
								inst = voices = null;
								close();
							}
						});
				}

			case BACK:
				@:privateAccess
				{
					cast(FlxG.state, VFSManagement).canPress = true;
					cast(FlxG.state, VFSManagement).onActionPressed(action);
				}
				chart = null;
				inst = voices = null;
				close();
		}
	}

	override function onActionReleased(action:ActionType)
	{
		canPress = true;
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
}
