package funkin.substates.vfs;

import backend.Save;
import backend.input.Controls.ActionType;
import backend.io.Path;
import base.MusicBeatState.MusicBeatSubState;
import base.TransitionState;
import base.sprites.OffsettedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.Character.VirtCharact;
import funkin.ChartLoader.VirtSong;
import funkin.SongTools.SongData;
import funkin.states.*;
import funkin.states.VFSManagement.SongEntry;
import haxe.io.Bytes;
import lime.graphics.Image;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

class CharacterUpload extends MusicBeatSubState
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

	private var options:Array<String> = ["Upload PNG", "Upload XML", "Upload JSON", "Done"];
	private var done:Array<Bool> = [];
	private var curState:String = "idle";

	private var name:String = "";
	private var image:Bytes = null;
	private var xml:String = "";
	private var json:String = "";

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
			case "upload png":
				if (Path.extension(fr.name) != "png")
					return;

				image = Bytes.ofData(bytes);

			case "upload xml":
				if (Path.extension(fr.name) != "xml")
					return;

				xml = Bytes.ofData(bytes).toString();

			case "upload json":
				if (Path.extension(fr.name) != "json")
					return;

				name = Path.withoutExtension(fr.name);
				trace(name);
				json = Bytes.ofData(bytes).toString();
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
					default:
						curState = option;
						showDialog();

					case "done":
						// im dumb okay
						var saveStruct:VirtCharact = {
							image: image,
							xml: xml,
							json: json
						};

						Save.database.shouldPreprocess = false;
						Save.database.set(VFS, 'character:$name', saveStruct).then((r) ->
						{
							if (r)
							{
								@:privateAccess
								{
									cast(FlxG.state, VFSManagement).canPress = true;
									cast(FlxG.state, VFSManagement).onActionPressed(BACK);
								}
								image = null;
								xml = json = null;
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
				image = null;
				xml = json = null;
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
