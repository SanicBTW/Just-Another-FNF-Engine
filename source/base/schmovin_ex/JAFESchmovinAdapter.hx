package base.schmovin_ex;

import backend.Conductor;
import schmovin.SchmovinAdapter;
import schmovin.SchmovinStandalone;

class JAFESchmovinAdapter extends SchmovinAdapter
{
	override function forEveryMod(param:Array<Dynamic>)
	{
		trace(param);
	}

	// TODO
	override function getCrotchetAtTime(time:Float):Float
	{
		return 2.0;
	}

	override function grabScrollSpeed():Float
	{
		return Conductor.speed;
	}

	// TODO
	override function grabReverse():Bool
	{
		return false;
	}

	override function getCrotchetNow():Float
	{
		return Conductor.crochet;
	}

	override function getSongPosition():Float
	{
		return Conductor.time;
	}

	// TODO
	override function grabGlobalVisualOffset():Float
	{
		return 0.0;
	}

	// TODO
	override function shouldCacheNoteBitmap(note:Dynamic):Bool
	{
		return true;
	}

	override function getCurrentBeat():Float
	{
		return getSongPosition() / getCrotchetNow();
	}

	override function getHoldNoteSubdivisions():Int
	{
		return SchmovinStandalone.holdNoteSubdivisions;
	}

	override function getArrowPathSubdivisions():Int
	{
		return SchmovinStandalone.arrowPathSubdivisions;
	}

	// TODO
	override function getDefaultNoteX(column:Int, player:Int):Float
	{
		return 0;
	}

	override function getOptimizeHoldNotes():Bool
	{
		return SchmovinStandalone.optimizeHoldNotes;
	}

	override function log(string:Dynamic)
	{
		trace('[Schmovin\' JAFE Adapter] $string');
	}
}
