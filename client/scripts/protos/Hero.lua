GameProtos["hero"] =
[[
message HeroResponse {
	repeated HeroDetail heros = 1;
}

message HeroAllResponse {
	repeated uint32 types = 1;
}

message HeroChooseRequest {
	optional uint32 roleId = 1;
	optional uint32 heroId = 2;
	optional uint32 slot = 3;
}

message HeroActionData {
	optional uint32 roleId = 1;
	optional uint32 mainHeroId = 2;
	repeated uint32 otherHeroIds = 3;
	optional uint32 useYuanbao = 4;
}

message HeroActionResponse {
	optional uint32 result = 1;
	repeated HeroDetail heros = 2;
	optional uint32 money = 3;
	optional uint32 exp = 4;
	repeated ItemDetail items = 5;
}

message HeroUpdateProperty {
	required uint32 id = 1;
	required string key = 2;
	optional string newValue = 3;
	optional string oldValue = 4;
}
]]