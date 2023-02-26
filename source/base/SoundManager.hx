package base;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import openfl.utils.Assets;

using StringTools;

#if js
import js.html.audio.AnalyserNode;
import js.html.audio.ChannelMergerNode;
import js.html.audio.ChannelSplitterNode;
import js.html.audio.GainNode;
import js.lib.Float32Array;
import js.lib.Uint8Array;
import lime.media.howlerjs.Howler;
#end

// TODO: dispatch and event when the music is changed and show a notification )?
// FIX: Trying to turn down the volume while fading in will result on the audio applying the global volume after it ends
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
// TODO: Make it get the spaces that a bar can be on the whole width of the screen
// TODO: Make it bind the max height with an offset
class PlaybackGraph extends FlxSpriteGroup
{
	private var ana:AnalyserNode;

	private var SampleData:Uint8Array;
	private var buflength:Int;

	private var barWidth:Int = 25;
	private var barIterator:Int;

	override public function new()
	{
		super();

		ana = Howler.ctx.createAnalyser();
		ana.fftSize = 256;
		Howler.masterGain.connect(ana);
		ana.connect(Howler.ctx.destination);

		buflength = ana.frequencyBinCount;
		SampleData = new Uint8Array(ana.frequencyBinCount);

		barIterator = Std.int(flixel.FlxG.width / buflength * 5);

		for (i in 0...barIterator)
		{
			var sprite:FlxSprite = new FlxSprite(i * barWidth, 0).makeGraphic(barWidth - 5, 120, FlxColor.WHITE);
			sprite.alpha = 0.45;
			add(sprite);
		}
		screenCenter();
	}

	override public function update(elapsed:Float)
	{
		ana.getByteFrequencyData(SampleData);

		for (i in 0...barIterator)
		{
			members[i].scale.y = SampleData[i] / flixel.FlxG.height * 15;
		}
	}
}
#end
