GameProtos["role"] =
[[

message RoleQueryLogin {
	required string uid = 1;
}

message RoleQueryResponse {
	required string ret = 1; //RET_NOT_EXIST,RET_HAS_EXISTED
	optional string name = 2;
}

message RoleCreate {
	required string uid = 1;
	required string name = 2;
	required uint32 heroType = 3;
	optional string uname = 4;
	optional string packageName = 5;
	optional string deviceId = 6;
}

message RoleLoginData {
	required string name = 1;
	optional uint32 heroType = 2;
	optional string pwd = 3;
	optional string packageName = 4;
	optional string deviceId = 5;
}

message RoleLoginRequest {
	required string name = 1;
}

message RoleUpdateProperty {
	required string key = 1;
	optional string newValue = 2;
	optional string oldValue = 3;
	optional uint32 roleId = 4;
}

message RoleUpdateProperties {
	repeated RoleUpdateProperty tab = 1;
}

message RoleCreateResponse {
	enum CreateResult {
		SUCCESS = 0;
		EXIST = 1;
		DB_ERROR = 2;
		ILLEGAL_NAME = 3;
	}
	required CreateResult result = 1;
	optional uint32 roleId = 2;
	optional string roleName = 3;
}

message RoleShopDataResponse {
	message ShopData {
		optional uint32 shopIndex = 1;
		optional uint32 refreshLeftTime = 2;
		optional string shopItemsJson = 3;
	}

	repeated ShopData shopDatas = 1;
}

message RoleLoginResponse {
	enum LoginResult {
		SUCCESS = 0;
		NOT_EXIST = 1;
		HAS_LOGIN = 2;
		DB_ERROR = 3;
	}
	message NoticeData {
		optional uint32 order = 1;
		optional string content = 2;
		optional string title = 3;
	}
	required LoginResult result = 1;
	optional RoleDetail roleInfo = 2;
	repeated BeautyDetail beauties = 3;
	repeated CarbonInfo carbons = 4;
	repeated FragmentUnit fragments = 5;
	repeated KeyValuePair dailyData = 6;
	repeated MapInfo maps = 7;
	repeated ItemDetail items = 8;
	repeated KeyValuePair timestamps = 9;
	optional uint32 serverTime = 10;
	repeated EquipDetail equips = 11;
	repeated FragmentUnit equipFragments = 12;
	repeated HeroDetail heros = 13;
	repeated NoticeData notices = 14;
	repeated HeroDetail assisoldier=15;
	repeated HeroDetail partners = 16;
	optional BeautyDetail beauty = 17;
	optional uint32 isFriend = 18;
}

message RoleLoadHeroPost {
	repeated HeroDetail heros = 1;
}

message RoleBornRequest {
	required uint32 roleId = 1;
	optional uint32 heroType = 2;	// 选择的武将类型
}

message RoleBornResponse {
	enum BornResult {
		SUCCESS = 0;
	}
	required BornResult result = 1;
}

message EmailList {
	repeated EmaiDetail emails = 1;
}

message FragmentList {
	repeated FragmentUnit fragments = 1;
}

message DecomposeFragment {
	optional uint32 roleId = 1;
	repeated uint32 stars = 2;
	repeated uint32 fragmentIds = 3;
	repeated uint32 numbers = 4;
}

message NewMessageNotify {
	repeated KeyValuePair newEvents = 1;
}

message BuyMoneyResult {
	message ResultUnit {
		optional uint32 yuanbao = 1;
		optional uint32 money = 2;
		optional uint32 critFactor = 3;
	}

	repeated ResultUnit results = 1;
}

message RankList {
	message RankUnit {
		optional uint32 roleId = 1;
		optional uint32 rank = 2;
		optional string	name = 3;
		optional uint32	level = 4;
		optional uint32 mainHeroType = 5;
		optional uint32 mainHeroWakeLevel = 6;
		optional uint32	extraParam1 = 7;
		optional uint32 extraParam2 = 8;
		optional uint32 extraParam3 = 9;
		optional uint32 mainHeroStar = 10;
		optional uint32 mainHeroEvolutionCount = 11;
	}

	repeated RankUnit rankList = 1;
}

]]