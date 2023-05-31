package network.quaver;

typedef Map =
{
	var id:Int;
	var mapset_id:Int;
	var md5:String;
	var alternative_md5:Null<String>;
	var creator_id:Int;
	var creator_username:String;
	var game_mode:Int;
	var ranked_status:Int;
	var artist:String;
	var title:String;
	var source:String;
	var tags:String;
	var description:String;
	var difficulty_name:String;
	var length:Int;
	var bpm:Int;
	var difficulty_rating:Float;
	var count_hitobject_normal:Int;
	var count_hitobject_long:Int;
	var play_count:Int;
	var fail_count:Int;
	var mods_pending:Int;
	var mods_accepted:Int;
	var mods_denied:Int;
	var mods_ignored:Int;
	var online_offset:Float;
	var clan_ranked:Int;
	var date_submitted:String;
	var date_last_updated:String;
}
