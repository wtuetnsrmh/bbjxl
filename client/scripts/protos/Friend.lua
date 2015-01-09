GameProtos["friend"] =
[[
message SearchRoleByName {
	required uint32 roleId = 1;
	optional string namePattern = 2;
}

message SearchRoleList {
	message RoleDigest {
		optional uint32 roleId = 1;
		optional uint32 level = 2;
		optional uint32 pvpRank = 3;
		optional uint32 imageId = 4;
		optional string name = 5;
		optional uint32 lastLoginTime = 6;
		optional uint32 isFriend = 7;
		optional uint32 friendCnt = 8;
		optional uint32 money = 9;
		optional uint32 mainHeroType = 10;
		optional uint32 vipLevel = 11;
		optional uint32 wakeLevel = 12;
		optional uint32 star = 13;
		optional uint32 evolutionCount = 14;
	}
	repeated RoleDigest searchRoles = 1;
}

message FriendList {
	message FriendInfo {
		optional uint32 roleId = 1;
		optional uint32 level = 2;
		optional uint32 pvpRank = 3;
		optional uint32 imageId = 4;
		optional string name = 5;
		optional uint32 canDonate = 6;
		optional uint32 canReceive = 7;
		optional uint32 lastLoginTime = 8;
		optional uint32 friendCnt = 9;
		optional uint32 money = 10;
		optional uint32 mainHeroType = 11;
		optional uint32 vipLevel = 12;
		optional uint32 wakeLevel = 13;
		optional uint32 star = 14;
		optional uint32 evolutionCount = 15;
	}
	repeated FriendInfo friends = 1;
}

message InviteFriendRequest {
	optional uint32 objectId = 1;
	optional string inviteCode = 2;
}

message ChatContent {
	optional uint32 sourceId = 1;
	optional string content = 2;
	optional uint32 timestamp = 3;
}

message ChatContentList {
	repeated ChatContent chats = 1;
}

message ApplicationInfo {
	optional uint32 roleId = 1;
	optional uint32 objectId = 2;	// A申请加B为好友, objectId则为B
	optional uint32 applicationId = 3;
	optional uint32 timestamp = 4;
	optional string content = 5;
	optional uint32 level = 6;
	optional uint32 pvpRank = 7;
	optional uint32 mainHeroType = 8;
	optional string name = 9;
}

message ApplicationList {
	repeated ApplicationInfo applications = 1;
}

message HandleApplication {
	enum HandleCode {
		Agree = 1;
		Deny = 2;
	}
	required uint32 roleId = 1;
	optional uint32 objectId = 2;	// 申请记录Id
	optional HandleCode handleCode = 3;	// 处理结果
}

message DonateHealthToFriend {
	required uint32 roleId = 1;
	optional uint32 objectId = 2;
}

message ReceiveDonatedHealth {
 	required uint32 roleId = 1;
 	optional uint32 objectId = 2;
}

message DeleteFriend {
	required uint32 roleId = 1;
	optional uint32 objectId = 2;
}
]]