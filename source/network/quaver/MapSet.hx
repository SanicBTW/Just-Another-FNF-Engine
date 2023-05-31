package network.quaver;

import network.quaver.Map;

typedef MapSet =
{
	var id:Int;
	var creator_id:Int;
	var creator_username:String;
	var creator_avatar_url:String;
	var artist:String;
	var title:String;
	var source:String;
	var tags:String;
	var description:Null<String>;
	var date_submitted:String;
	var date_last_updated:String;
	var ranking_queue_status:Int;
	var ranking_queue_last_updated:String;
	var ranking_queue_vote_count:Int;
	var mapset_ranking_queue_id:Int;
	var maps:Array<Map>;
}
