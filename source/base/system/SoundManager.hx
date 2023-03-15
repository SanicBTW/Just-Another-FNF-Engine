package base.system;

import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;

using StringTools;

class SoundManager
{
	private static var sounds:Map<String, AudioStream> = [];

	public static var globalVolume(default, set):Float = 1;
	private static var oldVolume:Float = 1;
	public static var muted(default, set):Bool = false;

	private static function set_globalVolume(value:Float):Float
	{
		globalVolume = value;
		if (globalVolume > 1)
			globalVolume = 1;
		if (globalVolume < 0)
			globalVolume = 0;

		for (name => sound in sounds)
		{
			sound.audioVolume = globalVolume;
		}

		if (Main.volumeTray != null)
			Main.volumeTray.show();

		return globalVolume;
	}

	private static function set_muted(value:Bool):Bool
	{
		if (value)
		{
			oldVolume = globalVolume;
			globalVolume = 0;
		}
		else
		{
			globalVolume = oldVolume;
			oldVolume = 0;
		}
		return muted = value;
	}

	public static function clearSoundList()
	{
		for (name => sound in sounds)
		{
			if (name.contains("PERSIST"))
				return;

			trace("Deleting " + name + " from the sound manager");
			sound.stop();
			sound = null;
			sounds.remove(name);
		}
	}

	public static function setSound(?name:String, ?audio:AudioStream):AudioStream
	{
		if (audio == null)
			audio = new AudioStream();

		if (name != null && !sounds.exists(name))
		{
			audio.tag = name;
			sounds.set(name, audio);
		}

		if (name == null)
		{
			var soundNNumber:Int = 0;
			for (soundName in sounds.keys())
			{
				if (soundName.contains("sound_"))
					soundNNumber = Std.parseInt(soundName.split("_")[1]) + 1;
			}
			name = 'sound_${soundNNumber}';
			audio.tag = name;
			sounds.set(name, audio);
		}

		return sounds.get(name);
	}
}

class AudioStream
{
	// Important shit
	private var sound:Sound;
	private var channel:SoundChannel;

	// Metadata
	public var audioLength:Float = 0;
	public var loopAudio:Bool = false;
	public var audioSource(default, set):Dynamic = null;
	public var tag:String = "";

	// Events
	public var onFinish(default, never):FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	public var onLoop(default, never):FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

	// Playback
	public var isPlaying:Bool = false;
	@:isVar public var playbackTime(get, set):Float = 0;
	public var audioVolume(default, set):Float = 1;

	private var lastTime:Float = 0;

	// public var loopTime:Float = 0;

	public function new()
	{
		sound = new Sound();
	}

	public function play(volume:Float = 1, ?startTime:Float)
	{
		if (channel != null)
			return;
		if (sound == null)
			return;
		if (audioSource == null)
			return;

		channel = sound.play((startTime != null) ? startTime : lastTime);
		channel.addEventListener(Event.SOUND_COMPLETE, audioCompleted);
		isPlaying = true;
		audioVolume = volume;
	}

	public function stop()
	{
		if (channel == null)
			return;

		lastTime = channel.position;
		channel.removeEventListener(Event.SOUND_COMPLETE, audioCompleted);
		channel.stop();
		@:privateAccess channel.__dispose();
		channel = null;
		isPlaying = false;
	}

	private function audioCompleted(?_)
	{
		if (loopAudio)
		{
			playbackTime = 0;
			onLoop.dispatch();
		}
		else
		{
			stop();
			sound.close();
			sound = null;
			onFinish.dispatch();
		}
	}

	private function get_playbackTime():Float
		return (channel != null ? channel.position : playbackTime);

	private function set_playbackTime(newTime:Float):Float
	{
		stop();
		playbackTime = newTime;
		lastTime = (lastTime > audioLength ? 0 : newTime);
		play(audioVolume, newTime);
		return newTime;
	}

	private function set_audioVolume(newVolume:Float):Float
	{
		if (!isPlaying)
			return audioVolume;

		audioVolume = (newVolume > SoundManager.globalVolume) ? SoundManager.globalVolume : newVolume;
		channel.soundTransform = new SoundTransform(audioVolume);

		return audioVolume;
	}

	private function set_audioSource(newSource:Dynamic):Dynamic
	{
		audioSource = newSource;

		if (sound == null)
			return null;

		if (newSource is Sound)
			sound = newSource;

		lastTime = 0;
		audioLength = sound.length;
		isPlaying = false;

		return audioSource;
	}
}
