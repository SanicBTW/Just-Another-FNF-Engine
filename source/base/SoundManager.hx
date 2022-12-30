package base;

class SoundManager
{
	private static var soundList:Array<AudioStream> = [];
	public static var globalVolume(default, set):Float = 1;
	private static var oldVolume:Float = 1;
	public static var muted(default, set):Bool = false;

	// public static var onVolumeChanged:lime.app.Event<Void->Void> = new lime.app.Event<Void->Void>();

	private static function set_globalVolume(value:Float):Float
	{
		globalVolume = value;
		if (globalVolume > 1)
			globalVolume = 1;
		if (globalVolume < 0)
			globalVolume = 0;
		// onVolumeChanged.dispatch();
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

	// bitch ass useless function bruh
	public static function clearSoundList()
		soundList = [];

	public static function addSound(sound:AudioStream)
		soundList.push(sound);
}
