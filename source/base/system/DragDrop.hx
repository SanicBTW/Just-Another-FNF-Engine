package base.system;

import funkin.ChartLoader;
import funkin.CoolUtil;
import haxe.io.Path;
import lime.app.Application;
import openfl.media.Sound;
import states.PlayTest;

using StringTools;

#if sys
import sys.io.File;
#end
#if js
import js.html.FileList;
#end

class DragDrop
{
	// state can be, waiting for sound, etc
	private static var state:String = "Listening";
	private static var waitTimer:Timer;

	public static function listen()
	{
		Application.current.window.onDropFile.add((filePath:String) -> {
			#if sys
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
										ChartLoader.netInst = Sound.fromFile(filePath);
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
										ChartLoader.netVoices = Sound.fromFile(filePath);
										state = "Listening";
										ScriptableState.switchState(new PlayTest(null));
									}
								}
						}
					}
			}
			#else
			var fileList:FileList = cast(filePath, FileList);
			for (item in fileList)
			{
				trace(item);
			}
			#end
		});
	}
}
