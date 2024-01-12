package funkin.states.start;

import backend.io.CacheFile;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.Prompt;
import haxe.ds.DynamicMap;

// im cumming with this code omg
// https://github.com/SanicBTW/FNF-PsychEngine-0.3.2h/blob/master/source/features/PermissionsPrompt.hx
class PermissionsSubstate extends FlxSubState
{
	final promptData:Array<{name:String, description:String, saveIndex:String}> = [
		{
			name: "Online Fetching",
			description: "Do you want to allow the engine to make online requests?\nAllowing this will give you access to:\n- Online songs fetching\n- Multiplayer services\n- and more...",
			saveIndex: "netAllowed"
		},
		{
			name: 'FileSystem Access',
			description: "Do you want to allow the engine to access the FileSystem?\nAllowing this will let the engine do the following:\n- Saving downloaded songs\n- Mod support\n- and more...",
			saveIndex: "fsAllowed"
		},
		{
			name: 'DiscordRPC and your Token',
			description: "This engine does not use native RPC bindings and\ninstead it uses a connection to the\nDiscord Gateway WebSocket requiring your auth token.\nIf allowed, the token will be requested after this screen",
			saveIndex: "discrpcAllowed"
		}
	];

	private var prompts:DynamicMap<String, Prompt> = new DynamicMap<String, Prompt>();

	private var bg:FlxSprite;
	private var fw:Float = 0;
	private var margin:Float = 20;

	public function new()
	{
		super();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		FlxTween.tween(bg, {alpha: 0.6}, 1, {ease: FlxEase.quartInOut});

		var pre:Prompt = new Prompt("", "", OK_CANCEL);
		var tw:Float = promptData.length * (pre.width + margin) - margin;
		var sx:Float = (FlxG.width - tw) / 2;
		fw = (pre.width + margin);

		var idx:Int = 0;
		for (data in promptData)
		{
			prompts[data.name] = new Prompt(data.name, data.description, OK_CANCEL);
			prompts[data.name].screenCenter(Y);
			prompts[data.name].alpha = 0;

			if (idx == promptData.length / 2)
				prompts[data.name].x = (FlxG.width / 2);
			else
				prompts[data.name].x = sx + idx * fw;

			prompts[data.name].button1.onUp.callback = () ->
			{
				promptSwag(data.name, data.saveIndex, true);
			};

			prompts[data.name].button2.onUp.callback = () ->
			{
				promptSwag(data.name, data.saveIndex, false);
			};

			add(prompts[data.name]);
			FlxTween.tween(prompts[data.name], {alpha: 1}, 1.5, {ease: FlxEase.quartInOut, startDelay: 0.5 * (idx + 1)});
			idx++;
		}

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	private function promptSwag(prompt:String, saveOn:String, state:Bool)
	{
		FlxTween.tween(prompts[prompt], {alpha: 0}, 1, {
			onComplete: (_) ->
			{
				remove(prompts[prompt]);
				prompts.remove(prompt);
				CacheFile.data[saveOn] = state;

				if (prompts.length() == 0)
				{
					FlxTween.tween(bg, {alpha: 0}, 1, {
						ease: FlxEase.quartInOut,
						onComplete: (_) ->
						{
							CacheFile.data.gavePerms = true;
							CacheFile.Save();
							close();
						}
					});
					return;
				}

				var newPositions:Array<Float> = getPositions();
				var idx:Int = 0;
				for (p in prompts)
				{
					FlxTween.tween(p, {x: newPositions[idx]}, 1, {ease: FlxEase.smoothStepInOut});

					idx++;
				}
			}
		});
	}

	private function getPositions():Array<Float>
	{
		var newPositions:Array<Float> = [];

		var length:Int = prompts.length();
		var tw:Float = length * fw - margin;
		var sx:Float = (FlxG.width - tw) / 2;

		var idx:Int = 0;
		for (p in prompts)
		{
			newPositions[idx] = sx + idx * fw;

			idx++;
		}

		return newPositions;
	}
}
