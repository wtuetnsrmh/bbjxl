GameProtos["carbon"] =
[[
message CarbonEnterAction {
	required uint32 roleId = 1;
	required uint32 carbonId = 2;
	optional uint32 result = 3;
}

message BattleStartCmd {
	required uint32 roleId = 1;
	required uint32 carbonId = 2;
	optional uint32 result = 3;
}

message CarbonResponse {
	repeated CarbonInfo carbons = 1;
	repeated MapInfo maps = 2;
}

message TowerData {
	optional uint32 roleId = 1;
	optional uint32 count = 2;
	optional uint32 carbonId = 4;
	optional uint32 totalStarNum = 5;
	optional uint32 preTotalStarNum = 6;
	optional uint32 maxTotalStarNum = 7;
	optional uint32 curStarNum = 8;
	optional uint32 hpModify = 9;
	optional uint32 atkModify = 10;
	optional uint32 defModify = 11;
	optional uint32 sceneId1 = 12;
	optional uint32 sceneId2 = 13;
	optional uint32 sceneId3 = 14;
	optional uint32 opendBoxNum = 15;
}

message TowerAwardData {
	optional TowerData towerData = 1;
	repeated ItemInfo awardItems = 2;
}

message ActCarbonDataResponse {
	optional TowerData towerData = 1;
}

message AssistInfo {
	optional uint32 roleId = 1;
	optional string name = 2;
	optional uint32 level = 3;
	optional uint32 heroId = 4;
	optional uint32 heroType = 5;
	optional uint32 heroLevel = 6;
	optional string heroSkillLevelsJson = 7;
	optional uint32 heroEvolutionCount = 8;
	optional uint32 source = 9;
	optional uint32 first = 10;
	optional uint32 heroWakeLevel = 11;
	optional uint32 heroStar = 12;
}

message AssistFriendListResponse {
	repeated AssistInfo assistList = 1;
	optional uint32 carbonId = 2;
}

message AssistChooseAction {
	required uint32 roleId = 1;
	optional uint32 chosenRoleId = 2;
	optional uint32 mainHeroId = 3;
	optional uint32 carbonId = 4;
	optional uint32 source = 5;
}

message BattleEndResult {
	optional uint32 roleId = 1;
	optional uint32 carbonId = 2;
	optional uint32 starNum = 3;
	optional uint32 exp = 4;
	optional uint32 money = 5;
	optional uint32 openNewCarbon = 6;
	repeated ItemInfo dropItems = 7;
	optional AssistInfo assistInfo = 8;
	optional uint32 origLevel = 9;
	optional uint32 origExp = 10;
	optional uint32 battleType = 11;
	repeated HeroDetail joinHeros = 12;
	optional uint32 diffIndex = 13;
}

message CarbonSweepResult {
	repeated BattleEndResult result = 1;
}

message TowerEndData {
	optional uint32 roleId = 1;
	optional uint32 mapId = 2;
	optional uint32 carbonId = 3;
	optional uint32 difficult = 4;
	optional uint32 starNum = 5;
}

message TowerRankData {
	message RankRecord {
		optional uint32 roleId = 1;
		optional string name = 2;
		optional uint32 level = 3;
		optional uint32 mainHeroType = 4;
		optional uint32 carbonNum = 5;
		optional uint32 totalStarNum = 6;
		optional uint32 index = 7;
		optional uint32 mainHeroWakeLevel = 8;
		optional uint32 mainHeroStar = 9;
		optional uint32 mainHeroEvolutionCount = 10;
	}
	repeated RankRecord rankDatas = 1;
}

message ExpBattleEndResposeData {
	repeated ItemInfo awardItems = 1;
	repeated ItemInfo awardOthers = 2;
	optional uint32 addHeroExp=3;
}
]]