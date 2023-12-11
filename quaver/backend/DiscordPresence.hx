package backend;

#if DISCORD_PRESENCE
import discord_rpc.DiscordRpc;
import lime.app.Application;

using StringTools;

// Copy paste from old code
class DiscordPresence
{
	// I'm so fucking addicted to Kana Arima, I love her sm
	private static final rpcImages:Array<String> = ['kanapvpomiedo'];

	public static var largeImageKey:String = rpcImages[Std.int(Math.random() * rpcImages.length)];

	public function new()
	{
		DiscordRpc.start({
			clientID: "1089328716154404885",
			onReady: onReady,
			onError: (_code:Int, _message:String) ->
			{
				trace('Discord Presence Error: $_code, $_message');
			},
			onDisconnected: (_code:Int, _message:String) ->
			{
				trace('Discord Presence Disconnected: $_code, $_message');
			}
		});

		trace("Discord Presence Started");

		// Its actually kind of dumb to create a thread if we only want to process callbacks, just process them while the app is updated, what is the need for sleeping the thread tho
		Application.current.onUpdate.add((_) ->
		{
			DiscordRpc.process();
		});
	}

	private static function onReady()
	{
		DiscordRpc.presence({
			details: 'PvP o miedo',
			state: null,
			largeImageKey: largeImageKey,
			largeImageText: 'Beta ${Application.current.meta.get("version")}'
		});
	}

	public static function Initialize()
	{
		new DiscordPresence();
		Application.current.onExit.add((_) ->
		{
			shutdownPresence();
		});
	}

	public static function changePresence(details:String = '', ?state:String, ?smallImageKey:String, hasStartTimestamp:Bool = false, endTimestamp:Float = 0)
	{
		var startTimestamp:Float = (hasStartTimestamp) ? Date.now().getTime() : 0;

		if (endTimestamp > 0)
			endTimestamp = startTimestamp + endTimestamp;

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: largeImageKey,
			largeImageText: 'Beta ${Application.current.meta.get("version")}',
			smallImageKey: smallImageKey,
			startTimestamp: Std.int(startTimestamp / 1000),
			endTimestamp: Std.int(endTimestamp / 1000)
		});
	}

	public static function shutdownPresence()
	{
		trace("Shutting down Presence");
		DiscordRpc.shutdown();
	}
}
#else
// In order to avoid having to fill the code with compiler conditionals everywhere the presence is in, I'll just write an empty class that contains all the functions the working class has
class DiscordPresence
{
	private static final rpcImages:Array<String> = [];

	public static var largeImageKey:String = "";

	public function new() {}

	private static function onReady() {}

	public static function Initialize() {}

	public static function changePresence(details:String = '', ?state:String, ?smallImageKey:String, hasStartTimestamp:Bool = false, endTimeStamp:Float = 0) {}

	public static function shutdownPresence() {}
}
#end
