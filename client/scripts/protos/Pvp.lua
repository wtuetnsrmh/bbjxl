GameProtos["pvp"] =
[[
message BattleReport {
	optional uint32 roleId = 1;
	optional string roleName = 2;
	optional uint32 opponentRoleId = 3;
	optional uint32 opponentRoleMainHeroType = 4;
	optional string opponentRoleName = 5;
	optional uint32 opponentRoleLevel = 6;
	optional int32 deltaRank = 7;
	optional uint32 createTime = 8;
	optional uint32 zhangong = 9;
}

message ChoosePvpOpponent {
	required uint32 roleId = 1;
	optional uint32 opponentRoleId = 2;
	optional uint32 opponentRank = 3;
}

message MatchRolesResponse {
	optional uint32 roleId = 1;
	optional uint32 pvpRank = 2;
	repeated RoleDetail matchRoles = 3;
	repeated BattleReport reports = 4;
}

message PvpBattleEndResult {
	required uint32 roleId = 1;
	optional uint32 opponentRoleId = 2;
	optional uint32 starNum = 3;
	optional uint32 exp = 4;
	optional uint32 money = 5;
	optional uint32 origLevel = 6;
	optional uint32 zhangong = 7;
	optional uint32 bestRank = 8;
	optional uint32 yuanbao = 9;
	optional uint32 oldBestRank = 10;
}

message PvpGiftAwardRequest {
	optional uint32 roleId = 1;
	optional uint32 floorRank = 2;
}

message HistoryRecord {
	optional uint32 roleId = 1;
	optional uint32 opponentRoleId = 2;
	optional uint32 opponentRoleLevel = 3;
	optional uint32 starNum = 4;
	optional int32 deltaRank = 5;
	optional uint32 recordIndex = 6;
	optional uint32 createTime = 7;
	optional uint32 zhangong = 8;
}

message BattleReportList {
	repeated BattleReport reports = 1;
}

message PvpRankList {
	message PvpRankUnit {
		optional uint32 roleId = 1;
		optional uint32 pvpRank = 2;
		optional string	name = 3;
		optional uint32	level =4;
		optional uint32 mainHeroType = 5;
		optional uint32 mainHeroWakeLevel = 6;
		optional uint32 mainHeroStar = 7;
		optional uint32 mainHeroEvolutionCount = 8;
	}

	repeated PvpRankUnit rankList = 1;
}
]]