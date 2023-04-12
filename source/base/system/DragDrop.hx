package base.system;

import funkin.ChartLoader;
import funkin.CoolUtil;
import haxe.io.Path;
import lime.app.Application;
import openfl.media.Sound;
import states.PlayTest;
import sys.io.File;

using StringTools;

class DragDrop
{
	// state can be, waiting for sound, etc
	private static var state:String = "Listening";
	private static var waitTimer:Timer;

	public static function listen()
	{
		Application.current.window.onDropFile.add((filePath:String) ->
		{
			var fileExtension:String = Path.extension(filePath);
			var fileName:String = Path.withoutDirectory(Path.withoutExtension(filePath));

			trace([fileName, fileExtension]);

			switch (fileExtension)
			{
				case "json":
					{
						state = "Waiting inst";

						// As net charts are only loaded and then passed to a variable that the chart loader parses, this makes things easier
						ChartLoader.netChart = File.getContent(filePath);
					}

				case "ogg":
					{
						switch (state)
						{
							case "Waiting inst":
								{
									if (fileName.toLowerCase().contains("inst"))
									{
										ChartLoader.netInst = Cache.getSound(filePath, true);
										state = "Waiting voices";
										waitTimer = new Timer(5, () ->
										{
											state = "Listening";
											ScriptableState.switchState(new PlayTest(null));
										});
									}
								}

							case "Waiting voices":
								{
									waitTimer.destroy();
									if (fileName.toLowerCase().contains("voices"))
									{
										ChartLoader.netVoices = Cache.getSound(filePath, true);
										state = "Listening";
										ScriptableState.switchState(new PlayTest(null));
									}
								}
						}
					}
			}
		});
	}
}
