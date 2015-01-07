GameProtos["expedition"] =
[[
message YZHeroDtl {
	optional uint32 id = 1;
	optional uint32 level = 2;
	optional uint32 evolutionCount = 3;
	optional string skillLevelJson = 4;
	optional uint32 wakeLevel = 5;
	optional uint32 blood = 6;
	optional uint32 slot = 7;
	optional string attrsJson=8;//所有属性
	optional uint32 star = 9;
}

message JoinedHero {
	required uint32 heroId = 1; // 自己的英雄是数据库id，关卡的是配置id
	required uint32 blood = 2;
	required uint32 isOn = 3; // 是否正在上阵,1上阵,2没上阵
}

message YZFighter {
	optional string name = 1;
	optional uint32 level = 2;
	optional uint32 id = 3; // 1-15
	repeated uint32 passiveSkills=4;//美人被动技
	repeated BeautyDetail beauties=5;//美人
	required uint32 angryCD = 6; // 这里的值=怒气值*10
	repeated YZHeroDtl heroList = 7;
}

message ExpeditionResponse {
	optional uint32 errCode = 1;
	repeated YZFighter fightList = 2;
	repeated uint32 drawStatus = 3; // 1未领取, 2已领取, 3不能领取
	optional uint32 leftCnt = 4;
}

message EnterExpeditionRequest {
	required uint32 id = 1; // 1-15
	repeated uint32 heroList = 2;
}

message DrawExpeditionResponse {
	optional uint32 errCode = 1;
	repeated ItemInfo items = 2;
}

// 远征挑战发送
message UpdateYzFormationReq {
	required string yzFormationJson = 1; 
} 

message ExpeditionJoinResponse {
	repeated JoinedHero joinHeros = 1;
	required uint32 angryCD = 2; // 这里的值=怒气值*10
}

message EndExpeditionRequest {
	required uint32 id = 1; // 1-15
	required uint32 result = 2; // 1胜利,2失败 平局也是失败
	required YZFighter myself = 3;
	required YZFighter other = 4;
	repeated HeroDetail joinHeros = 5;
}
]]