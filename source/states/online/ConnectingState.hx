package states.online;

import base.MusicBeatState;
import base.ScriptableState;
import base.ui.CircularSprite.CircularSpriteText;
import flixel.FlxG;
import flixel.addons.ui.FlxInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import io.colyseus.Client;
import io.colyseus.Room;
import states.online.schema.VersusRoom;

interface PlayerData
{
	var name:String;
	var ready:Bool;
	var isOpponent:Bool;

	var accuracy:Float;
	var score:Int;
	var misses:Int;
}

class ConnectingState extends MusicBeatState
{
	private var client:Client;

	public function new(type:String, ?code:String)
	{
		super();

		client = new Client('wss://ws.sancopublic.com');
		switch (type)
		{
			case "host":
				{
					var hname:String = 'test${FlxG.random.int(0, 9999)}';
					client.create('versus_room', [], VersusRoom, (error, room) ->
					{
						if (error != null)
						{
							trace("error creating room " + error);
							ScriptableState.switchState(new RewriteMenu());
							return;
						}

						try
						{
							room.send('set_name', {name: hname});

							room.onMessage('create_match', (song:String) ->
							{
								// set the song
								trace(song);
							});

							// it might be an object ({song, p1name}) but only for the other client
							room.onMessage('message', (code:String) ->
							{
								// lobby code?
								trace(code);
							});

							room.onMessage('ready_state', (_:{p1:Bool, p2:Bool}) ->
							{
								// change the ready text lol
								var textIdx:Int = _.p1 ? 0 : 1;
								trace(_.p1);
								trace(_.p2);
								trace(textIdx);
							});

							room.onMessage('game_start', (_) ->
							{
								// change to another state
								trace("Game started");
							});

							room.onMessage('join', (name:String) ->
							{
								trace('p2 name $name');
							});

							room.onMessage('left', (_) ->
							{
								trace('p2 left');
							});

							room.onMessage('ret_stats', (stats:{accuracy:Float, score:Int, misses:Int}) ->
							{
								trace(stats);
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
					var hname:String = 'test${FlxG.random.int(0, 9999)}';
					client.joinById(code, [], VersusRoom, (error, room) ->
					{
						if (error != null)
						{
							trace("error joining room " + error);
							ScriptableState.switchState(new RewriteMenu());
							return;
						}

						room.send('set_name', {name: hname});

						room.onMessage('message', (message:{song:String, p1:PlayerData}) ->
						{
							trace(message.song);
							trace(message.p1);
						});

						room.onMessage('ready_state', (_:{p1:Bool, p2:Bool}) ->
						{
							// change the ready text lol
							var textIdx:Int = _.p1 ? 0 : 1;
							trace(_.p1);
							trace(_.p2);
							trace(textIdx);
						});

						room.onMessage('game_start', (_) ->
						{
							trace("Game started");
						});

						room.onMessage('left', (_) ->
						{
							trace("left");
						});

						room.onMessage('ret_stats', (stats:{accuracy:Float, score:Int, misses:Int}) ->
						{
							trace(stats);
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
