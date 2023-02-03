package base;

import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import openfl.utils.Assets;

using StringTools;

// FIX: Trying to turn down the volume while fading in will result on the audio applying the global volume after it ends
class SoundManager
{
	private static var soundList:Array<AudioStream> = [];
	public static var backgroundMusic:AudioStream;
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
			sound.audioVolume = globalVolume;
		if (backgroundMusic != null)
			backgroundMusic.audioVolume = globalVolume;
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
	{
		for (sound in soundList)
		{
			sound.stop();
			sound = null;
		}
		soundList = [];
	}

	public static function addSound(sound:AudioStream)
		soundList.push(sound);
}

class AudioStream
{
	// Important shit
	private var sound:Sound;
	private var channel:SoundChannel;

	// Metadata
	public var audioLength:Float = 0;
	public var loopAudio:Bool = false;
	public var onFinish(default, never):FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	public var audioSource(default, set):Dynamic = null;

	private var lastTime:Float = 0;

	// public var loopTime:Float = 0;
	// Playback
	public var isPlaying:Bool = false;
	@:isVar public var playbackTime(get, set):Float = 0;
	public var audioVolume(default, set):Float = 1;

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
		channel = null;
		isPlaying = false;
	}

	private function audioCompleted(?_)
	{
		if (loopAudio)
			playbackTime = 0;
		else
		{
			stop();
			sound = null;
			onFinish.dispatch();
		}
	}

	private function get_playbackTime():Float
	{
		if (channel != null)
			return channel.position;
		else
			return playbackTime;
	}

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

		// netowkr shit
		if (newSource is String)
		{
			var sourceString:String = Std.string(newSource);
		}

		lastTime = 0;
		audioLength = sound.length;
		isPlaying = false;

		return audioSource;
	}
}
