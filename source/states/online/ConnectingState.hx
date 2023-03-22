package states.online;

import base.MusicBeatState;
import base.ScriptableState;
import base.pocketbase.Collections.PocketBaseObject;
import base.system.Conductor;
import flixel.FlxG;
import flixel.util.FlxColor;
import haxe.Json;
import io.colyseus.Client;
import states.online.schema.VersusRoom;

interface PlayerData
{
	var name:String;
	var ready:Bool;
	var isOpponent:Bool;
	var status:String;

	var accuracy:Float;
	var score:Int;
	var misses:Int;
}

class ConnectingState extends MusicBeatState
{
	public static var client:Client;

	public static var mode:String;
	public static var p1name:String;
	public static var p2name:String;

	// The alpha value for the other player status
	private var statusAlphas:Map<String, Float> = [
		"Loading chart" => 0.6,
		"Loading inst" => 0.7,
		"Checking voices" => 0.8,
		"Loading voices" => 0.9,
		"Waiting" => 1
	];

	public function new(type:String, ?code:String)
	{
		super();

		p2name = '';
		client = new Client(#if html5 'wss://ws.sancopublic.com' #else 'ws://ws.sancopublic.com' #end);

		switch (type)
		{
			case "host":
				{
					mode = 'host';
					p1name = 'test${FlxG.random.int(0, 9999)}';
					p2name = '';
					FlxG.switchState(new SongSelection());
					client.create('versus_room', [], VersusRoom, (error, room) ->
					{
						if (error != null)
						{
							trace("error creating room " + error);
							ScriptableState.switchState(new RewriteMenu());
							return;
						}

						OnlinePlayState.room = room;
						SongSelection.room = room;
						LobbyState.room = room;
						try
						{
							room.send('set_name', {name: p1name});

							room.onMessage('message', (message:{id:String}) ->
							{
								// lobby code?
								LobbyState.roomCode = message.id;
							});

							room.onMessage('ready_state', (_:{p1:Bool, p2:Bool}) ->
							{
								// change the ready text lol
								LobbyState.readyTxt.members[0].color = (_.p1 ? FlxColor.GREEN : FlxColor.RED);
								LobbyState.readyTxt.members[0].text = (_.p1 ? "Ready" : "Not ready");
								LobbyState.readyTxt.members[1].color = (_.p2 ? FlxColor.GREEN : FlxColor.RED);
								LobbyState.readyTxt.members[1].text = (_.p2 ? "Ready" : "Not ready");
							});

							room.onMessage('game_start', (_) ->
							{
								trace("Game started");
								OnlinePlayState.startedMatch = true;
								ScriptableState.switchState(new OnlinePlayState());
							});

							room.onMessage('song_start', (_) ->
							{
								OnlinePlayState.canStart = true;
								Conductor.resyncTime();
							});

							room.onMessage('join', (name:String) ->
							{
								LobbyState.p2.alpha = 0.5;
								p2name = name;
							});

							room.onMessage('left', (_) ->
							{
								if (!OnlinePlayState.startedMatch)
								{
									LobbyState.p2.alpha = 0.4;
									p2name = '';
									LobbyState.readyTxt.members[1].color = FlxColor.RED;
									LobbyState.readyTxt.members[1].text = 'Not ready';
								}
							});

							room.onMessage('ret_stats', (stats:{p1:PlayerData, p2:PlayerData}) ->
							{
								if (OnlinePlayState.dualHUD != null)
									OnlinePlayState.dualHUD.updateStats(stats.p1, stats.p2);
							});

							room.onMessage('status_report', (status:{p1status:String, p2status:String}) ->
							{
								if (!OnlinePlayState.startedMatch)
								{
									if (LobbyState.p2 != null)
										LobbyState.p2.alpha = statusAlphas[status.p2status];
									return;
								}
							});

							room.onError += (code:Int, message:String) ->
							{
								trace('An error ocurred $code $message');
								ScriptableState.switchState(new RewriteMenu());
							};
						}
						catch (ex)
						{
							trace('error connecting to the server $ex');
						}
					});
				}
			case "join":
				{
					mode = "join";
					p2name = 'test${FlxG.random.int(0, 9999)}';
					client.joinById(code, [], VersusRoom, (error, room) ->
					{
						if (error != null)
						{
							trace("error joining room " + error);
							ScriptableState.switchState(new RewriteMenu());
							return;
						}

						OnlinePlayState.room = room;
						SongSelection.room = room;
						LobbyState.room = room;

						room.send('set_name', {name: p2name});

						room.onMessage('message', (message:{song:String, player1:PlayerData}) ->
						{
							p1name = message.player1.name;
							LobbyState.roomCode = room.id;
							var pbObject:PocketBaseObject = cast Json.parse(message.song);
							FlxG.switchState(new SongSelection(pbObject));
						});

						room.onMessage('ready_state', (_:{p1:Bool, p2:Bool}) ->
						{
							// change the ready text lol
							LobbyState.readyTxt.members[0].color = (_.p1 ? FlxColor.GREEN : FlxColor.RED);
							LobbyState.readyTxt.members[0].text = (_.p1 ? "Ready" : "Not ready");
							LobbyState.readyTxt.members[1].color = (_.p2 ? FlxColor.GREEN : FlxColor.RED);
							LobbyState.readyTxt.members[1].text = (_.p2 ? "Ready" : "Not ready");
						});

						room.onMessage('game_start', (_) ->
						{
							trace("Game started");
							OnlinePlayState.startedMatch = true;
							ScriptableState.switchState(new OnlinePlayState());
						});

						room.onMessage('song_start', (_) ->
						{
							OnlinePlayState.canStart = true;
							Conductor.resyncTime();
						});

						// make it return to the main state
						room.onMessage('left', (_) ->
						{
							LobbyState.p2.alpha = 0.4;
							trace("left");
						});

						room.onMessage('ret_stats', (stats:{p1:PlayerData, p2:PlayerData}) ->
						{
							if (OnlinePlayState.dualHUD != null)
								OnlinePlayState.dualHUD.updateStats(stats.p1, stats.p2);
						});

						room.onMessage('status_report', (status:{p1status:String, p2status:String}) ->
						{
							if (!OnlinePlayState.startedMatch)
								return;
						});

						room.onError += (code:Int, message:String) ->
						{
							trace('An error ocurred $code $message');
							ScriptableState.switchState(new RewriteMenu());
						};
					});
				}
		}
	}
}
