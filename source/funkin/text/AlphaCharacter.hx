package funkin.text;

import flixel.FlxSprite;
import flixel.math.FlxPoint;

using StringTools;

///////////////////////////////////////////
// ALPHABET LETTERS, SYMBOLS AND NUMBERS //
///////////////////////////////////////////

typedef Letter =
{
	?anim:Null<String>,
	?offsets:Array<Float>,
	?offsetsBold:Array<Float>
}

class AlphaCharacter extends FlxSprite
{
	public var image(default, set):String;

	public static var allLetters:Map<String, Null<Letter>> = [
		// alphabet
		'a' => null,
		'b' => null,
		'c' => null,
		'd' => null,
		'e' => null,
		'f' => null,
		'g' => null,
		'h' => null,
		'i' => null,
		'j' => null,
		'k' => null,
		'l' => null,
		'm' => null,
		'n' => null,
		'o' => null,
		'p' => null,
		'q' => null,
		'r' => null,
		's' => null,
		't' => null,
		'u' => null,
		'v' => null,
		'w' => null,
		'x' => null,
		'y' => null,
		'z' => null,
		// numbers
		'0' => null,
		'1' => null,
		'2' => null,
		'3' => null,
		'4' => null,
		'5' => null,
		'6' => null,
		'7' => null,
		'8' => null,
		'9' => null,
		// symbols
		'&' => {offsetsBold: [0, 2]},
		'(' => {offsetsBold: [0, 5]},
		')' => {offsetsBold: [0, 5]},
		'*' => {offsets: [0, 28]},
		'+' => {offsets: [0, 7], offsetsBold: [0, -12]},
		'-' => {offsets: [0, 16], offsetsBold: [0, -30]},
		'<' => {offsetsBold: [0, 4]},
		'>' => {offsetsBold: [0, 4]},
		'\'' => {anim: 'apostrophe', offsets: [0, 32]},
		'"' => {anim: 'quote', offsets: [0, 32], offsetsBold: [0, 0]},
		'!' => {anim: 'exclamation', offsetsBold: [0, 10]},
		'?' => {anim: 'question', offsetsBold: [0, 4]}, // also used for "unknown"
		'.' => {anim: 'period', offsetsBold: [0, -44]},
		'❝' => {anim: 'start quote', offsets: [0, 24], offsetsBold: [0, -5]},
		'❞' => {anim: 'end quote', offsets: [0, 24], offsetsBold: [0, -5]},
		// symbols with no bold
		'_' => null,
		'#' => null,
		'$' => null,
		'%' => null,
		':' => {offsets: [0, 2]},
		';' => {offsets: [0, -2]},
		'@' => null,
		'[' => null,
		']' => {offsets: [0, -1]},
		'^' => {offsets: [0, 28]},
		',' => {anim: 'comma', offsets: [0, -6]},
		'\\' => {anim: 'back slash', offsets: [0, 0]},
		'/' => {anim: 'forward slash', offsets: [0, 0]},
		'|' => null,
		'~' => {offsets: [0, 16]}
	];

	var parent:Alphabet;

	public var alignOffset:Float = 0; // Don't change this
	public var letterOffset:Array<Float> = [0, 0];
	public var spawnPos:FlxPoint = new FlxPoint();
	public var spawnScale:FlxPoint = new FlxPoint();

	public var row:Int = 0;
	public var rowWidth:Float = 0;

	public function new(x:Float, y:Float, character:String, bold:Bool, parent:Alphabet)
	{
		super(x, y);
		this.parent = parent;
		image = 'alphabet';
		antialiasing = true;

		var curLetter:Letter = allLetters.get('?');
		var lowercase = character.toLowerCase();
		if (allLetters.exists(lowercase))
			curLetter = allLetters.get(lowercase);

		var suffix:String = '';
		if (!bold)
		{
			if (isTypeAlphabet(lowercase))
			{
				if (lowercase != character)
					suffix = ' uppercase';
				else
					suffix = ' lowercase';
			}
			else
			{
				suffix = ' normal';
				if (curLetter != null && curLetter.offsets != null)
				{
					letterOffset[0] = curLetter.offsets[0];
					letterOffset[1] = curLetter.offsets[1];
				}
			}
		}
		else
		{
			suffix = ' bold';
			if (curLetter != null && curLetter.offsetsBold != null)
			{
				letterOffset[0] = curLetter.offsetsBold[0];
				letterOffset[1] = curLetter.offsetsBold[1];
			}
		}

		var alphaAnim:String = lowercase;
		if (curLetter != null && curLetter.anim != null)
			alphaAnim = curLetter.anim;

		var anim:String = alphaAnim + suffix;
		animation.addByPrefix(anim, anim, 24);
		animation.play(anim, true);
		if (animation.curAnim == null)
		{
			if (suffix != ' bold')
				suffix = ' normal';
			anim = 'question' + suffix;
			animation.addByPrefix(anim, anim, 24);
			animation.play(anim, true);
		}
		updateHitbox();
		updateLetterOffset();
	}

	public static function isTypeAlphabet(c:String) // thanks kade
	{
		var ascii = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122);
	}

	private function set_image(name:String)
	{
		var lastAnim:String = null;
		if (animation != null)
		{
			lastAnim = animation.name;
		}
		image = name;
		frames = Paths.getSparrowAtlas(name);
		this.scale.x = parent.scaleX;
		this.scale.y = parent.scaleY;
		alignOffset = 0;

		if (lastAnim != null)
		{
			animation.addByPrefix(lastAnim, lastAnim, 24);
			animation.play(lastAnim, true);

			updateHitbox();
			updateLetterOffset();
		}
		return name;
	}

	public function updateLetterOffset()
	{
		if (animation.curAnim == null)
			return;

		if (!animation.curAnim.name.endsWith('bold'))
		{
			offset.y += -(110 - height);
		}
	}
}
