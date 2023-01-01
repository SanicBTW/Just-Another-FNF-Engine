package base;

import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import openfl.utils.Assets;

using StringTools;

class SoundManager
{
	private static var soundList:Array<AudioStream> = [];
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
		for (sound in soundList)
			sound.volume = globalVolume;
		return value;
	}

	private static function set_muted(value:Bool):Bool
	{
		muted = value;
		// so sorry for this if cond :skull:
		if (muted)
		{
			oldVolume = globalVolume;
			globalVolume = 0;
		}
		else
		{
			globalVolume = oldVolume;
			oldVolume = 0;
		}
		return value;
	}

	public static function clearSoundList()
		soundList = [];

	public static function addSound(sound:AudioStream)
		soundList.push(sound);
}

class AudioStream
{
	var sound:Sound;
	var channel:SoundChannel;

	public var playing:Bool = false;
	@:isVar public var time(get, set):Float = 0;
	public var volume(default, set):Float = 1;
	public var length:Float = 0;
	public var lastTime:Float = 0;
	public var onComplete:Void->Void;
	public var source(default, set):Dynamic = null;

	public function new()
	{
		sound = new Sound();
	}

	public function play()
	{
		if (channel == null)
		{
			channel = sound.play(lastTime);
			channel.soundTransform = new SoundTransform(SoundManager.globalVolume);
			channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			playing = true;
		}
	}

	public function stop()
	{
		if (channel != null)
		{
			lastTime = channel.position;
			channel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			channel.stop();
			channel = null;
			playing = false;
		}
	}

	private function onSoundComplete(?_)
	{
		stop();
		if (onComplete != null)
			onComplete();
	}

	function set_volume(value:Float):Float
	{
		if (channel != null)
		{
			if (channel.soundTransform.volume == value)
				return value;
			channel.soundTransform = new SoundTransform(value);
			return value;
		}
		return 0;
	}

	function get_time():Float
	{
		if (channel != null)
			return channel.position;
		else
			return lastTime;
	}

	function set_time(value:Float):Float
	{
		stop();
		lastTime = value;
		if (lastTime > length)
			lastTime = 0;
		play();
		return lastTime;
	}

	function set_source(value:Dynamic):Dynamic
	{
		if (sound == null)
			return null;

		if (value is Sound)
			sound = value;

		if (value is String)
		{
			var shitString = Std.string(value);
			if (shitString.contains("assets"))
				sound = Assets.getSound(value);
			if (shitString.contains("http://"))
				sound = new Sound(new URLRequest(value));
		}

		lastTime = 0;
		length = sound.length;
		playing = false;

		return value;
	}
}
