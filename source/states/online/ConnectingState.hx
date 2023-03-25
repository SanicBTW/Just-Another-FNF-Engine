package states.online;

import base.MusicBeatState;
import base.ScriptableState;
import base.pocketbase.Collections.PocketBaseObject;
import base.system.Conductor;
import base.ui.CircularSprite;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import haxe.Json;
import io.colyseus.Client;
import states.online.schema.VersusRoom;
import substates.online.OnlineLoadingState;

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

	/*
		private var rooms:FlxTypedGroup<CircularSpriteText>;
		private var roomArray:Array<CircularSpriteText> = [];

		override public function create()
		{
			rooms = new FlxTypedGroup<CircularSpriteText>();
			add(rooms);

			for (room in roomArray)
			{
				rooms.add(room);
				roomArray.remove(room);
			}

			super.create();
		}

		override public function update(elapsed:Float)
		{
			if (rooms != null)
			{
				for (room in rooms)
				{
					room.selected = (FlxG.mouse.overlaps(room));

					if (FlxG.mouse.justPressed && room.selected)
					{
						trace('Room ${room.bitmapText.text} selected');
					}
				}
			}

			super.update(elapsed);
		}
	 */
	public function new(type:String, ?code:String)
	{
		super();

		p2name = '';
		client = new Client(#if html5 'wss://ws.sancopublic.com' #else 'ws://ws.sancopublic.com' #end);

		switch (type)
		{
			/*
				case "room_listing":
					{
						client.getAvailableRooms("versus_room", (error, openRooms) ->
						{
							if (error != null)
							{
								trace('Error getting rooms $error');
								ScriptableState.switchState(new AlphabetMenu());
								return;
							}

							try
							{
								if (openRooms.length <= 0)
								{
									trace('Not enough rooms to show');
									FlxG.switchState(new AlphabetMenu());
									return;
								}

								for (i in 0...openRooms.length)
								{
									var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 350, 50, FlxColor.GRAY, openRooms[i].roomId);
									roomArray.push(item);
								}
							}
							catch (ex)
							{
								trace('Error listing rooms $ex');
								FlxG.switchState(new AlphabetMenu());
								return;
							}
						});
			}*/

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
							trace('Error creating room $error');
							ScriptableState.switchState(new AlphabetMenu());
							return;
						}

						OnlinePlayState.room = room;
						SongSelection.room = room;
						OnlineLoadingState.room = room;
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

							room.onMessage('ret_rateMode', (rateMode:String) ->
							{
								LobbyState.rateMode = rateMode;
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
									return;
								}

								if (OnlinePlayState.onlineHUD != null)
									OnlinePlayState.onlineHUD.player2Info.changeText("Left", "Player left the room");
							});

							room.onMessage('ret_stats', (stats:{p1:PlayerData, p2:PlayerData}) ->
							{
								if (OnlinePlayState.onlineHUD != null)
									OnlinePlayState.onlineHUD.updateStats(stats.p1, stats.p2);
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
								trace('An error ocurred on room (host) $code $message');
								ScriptableState.switchState(new AlphabetMenu());
								return;
							};
						}
						catch (ex)
						{
							trace('Error connecting to the server $ex');
							ScriptableState.switchState(new AlphabetMenu());
							return;
						}
					});
				}
			case "join":
				{
					mode = "join";
					p2name = 'test${FlxG.random.int(0, 9999)}';

					try
					{
						client.joinById(code, [], VersusRoom, (error, room) ->
						{
							if (error != null)
							{
								trace("Error joining room " + error);
								ScriptableState.switchState(new AlphabetMenu());
								return;
							}

							OnlinePlayState.room = room;
							SongSelection.room = room;
							OnlineLoadingState.room = room;
							LobbyState.room = room;

							LobbyState.roomCode = room.id;

							room.send('set_name', {name: p2name});

							room.onMessage('message', (message:
								{
									song:
										{
											id:String,
											song:String,
											chart:String,
											inst:String,
											voices:String
										},
									p1name:String,
									mode:String
								}) ->
							{
								p1name = message.p1name;
								LobbyState.rateMode = mode;
								var pbObject:PocketBaseObject = new PocketBaseObject(message.song.id, message.song.song, message.song.chart,
									message.song.inst, message.song.voices);
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

							room.onMessage('ret_rateMode', (rateMode:String) ->
							{
								LobbyState.rateMode = rateMode;
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

							room.onMessage('join', (_) ->
							{
								trace("join message");
							});

							// make it return to the main state
							room.onMessage('left', (_) ->
							{
								LobbyState.p2.alpha = 0.4;
								trace("left");
							});

							room.onMessage('ret_stats', (stats:{p1:PlayerData, p2:PlayerData}) ->
							{
								if (OnlinePlayState.onlineHUD != null)
									OnlinePlayState.onlineHUD.updateStats(stats.p1, stats.p2);
							});

							room.onMessage('status_report', (status:{p1status:String, p2status:String}) ->
							{
								if (!OnlinePlayState.startedMatch)
									return;
							});

							room.onError += (code:Int, message:String) ->
							{
								trace('An error ocurred on room (client) $code $message');
								ScriptableState.switchState(new AlphabetMenu());
								return;
							};
						});
					}
					catch (ex)
					{
						trace('Error joining to room ${code}: $ex');
						FlxG.switchState(new AlphabetMenu());
						return;
					}
				}
		}
	}
}
