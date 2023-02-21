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

#if js
import js.html.audio.ChannelMergerNode;
import js.html.audio.ChannelSplitterNode;
import js.html.audio.GainNode;
import lime.media.howlerjs.Howler;
#end

// FIX: Trying to turn down the volume while fading in will result on the audio applying the global volume after it ends
class SoundManager
{
	private static var sounds:Map<String, AudioStream> = [];
	public static var music:AudioStream;

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
			trace("Setting " + name + " volume to " + globalVolume);
			sound.audioVolume = globalVolume;
		}
		if (music != null)
			music.audioVolume = globalVolume;
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
			trace("Deleting " + name + " from the sound manager");
			sound.stop();
			sound = null;
		}
		sounds = [];
	}

	public static function setSound(?name:String, ?audio:AudioStream):AudioStream
	{
		if (audio == null)
			audio = new AudioStream();

		if (name != null && !sounds.exists(name))
			sounds.set(name, audio);

		if (name == null)
		{
			var soundNNumber:Int = 0;
			for (soundName in sounds.keys())
			{
				if (soundName.contains("sound_"))
					soundNNumber = Std.parseInt(soundName.split("_")[1]) + 1;
			}
			name = 'sound_${soundNNumber}';
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

		/*
			@:privateAccess
			lime.media.howlerjs.Howler.ctx.
			/*
				@:privateAccess
				lime.media.openal.AL.(this.channel.__source.__backend.handle, lime.media.openal.AL.CHANNELS, ) */
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
			playbackTime = 0;
		else
		{
			stop();
			sound.close();
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

#if js
class PlaybackGraph
{
	private var channelSplitter:ChannelSplitterNode;
	private var channelMerger:ChannelMergerNode;

	private var vibroGain:GainNode;
	private var musicGain:GainNode;

	public function new()
	{
		channelSplitter = new ChannelSplitterNode(Howler.ctx, {numberOfOutputs: 2});
		channelMerger = new ChannelMergerNode(Howler.ctx, {numberOfInputs: 2});

		vibroGain = new GainNode(Howler.ctx, {gain: SoundManager.globalVolume});
		musicGain = new GainNode(Howler.ctx, {gain: SoundManager.globalVolume});

		Howler.masterGain.disconnect(Howler.ctx.destination);

		Howler.masterGain.connect(channelSplitter, 0);
		channelSplitter.connect(vibroGain, 0);
		channelSplitter.connect(musicGain, 1);

		vibroGain.connect(channelMerger, 0, 0);
		musicGain.connect(channelMerger, 0, 1);

		musicGain.context.createBufferSource().buffer.getChannelData(0);

		channelMerger.connect(Howler.ctx.destination);
	}
}
#end
