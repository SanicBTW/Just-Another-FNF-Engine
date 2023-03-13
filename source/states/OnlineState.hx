package states;

import base.MusicBeatState;
import base.system.Conductor;
import base.system.Websocket;

// Test state when the socket receives "connection_ID" add a bf at a random position of the screen, if a connection is lost then delete the bf associated with it
class OnlineState extends MusicBeatState
{
	override public function create()
	{
		Conductor.boundSong = bgMusic;
		Conductor.boundState = this;
		Conductor.changeBPM(128);

		bgMusic.audioSource = Paths.music("mainRewrite");
		bgMusic.loopAudio = true;
		bgMusic.play();

		// maybe set the connection id to the content?
		// asign the user a random id when startup
		Websocket.send({type: 'connection', user: 'client', content: []});
		Websocket.onMessage.addOnce(wsListener);
	}

	private function wsListener(x:MessageData) {}
}
