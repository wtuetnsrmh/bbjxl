GameProtos["common"] = 
[[
message RoleDetail {
	required uint32 id = 1;
	optional string name = 2;
	optional uint32 level = 3;
	optional uint32 exp = 4;
	optional uint32 health = 5;
	optional uint32 money = 6;
	optional uint32 yuanbao = 7;
	optional uint32 pvpRank = 8;
	optional uint32 friendCnt = 9;
	optional string monthSignDay = 10;
	optional uint32 lastLoginTime = 11;
	optional string pveFormationJson = 12;
	optional uint32 mainHeroId = 13;
	optional uint32 mainHeroType = 14;
	optional uint32 friendValue = 15;
	optional uint32 heroSoulNum = 16;
	optional uint32 lingpaiNum = 17;
	optional string professionData = 18;
	optional uint32 starSoulNum = 19;
	optional uint32 starPoint = 20;
	optional uint32 rechargeRMB = 21;
	optional uint32 vipLevel = 22;
	optional uint32 sweepCarbonId = 23;
	optional uint32 sweepCount = 24;
	optional string sweepResult = 25;
	optional uint32 guideStep = 27;
	optional uint32 zhangongNum = 28;
	optional uint32 reputation = 29;
	optional string levelGiftsJson = 30;
	optional string serverGiftsJson = 31;
	optional int32 moneybuytimes = 32;
	optional uint32 loginDays = 33;
	optional string slotsJson = 34;
	optional int32 store2DailyCount = 35;
	optional int32 store3DailyCount = 36;
	optional int32 canSweep = 37;
	optional int32 bagHeroBuyCount = 38;
	optional string activedGuide = 39;
	optional uint32 mainHeroWakeLevel = 40;
	optional string firstRechargeJson = 41;
	optional string yzFormationJson = 42;
	optional uint32 battleSpeed = 43;
	optional uint32 mainHeroStar = 44;
	optional string partnersJson = 45;
	optional uint32 mainHeroEvolutionCount = 46;
	optional uint32 firstRechargeAwardState = 47;
	optional string rechargeGiftsJson = 48;
	optional string skillOrderJson = 49;
	optional string fundJson = 50;
	optional uint32 legendCardonIdIndex = 51;
	optional uint32 renameCount = 52;
}

message HeroDetail {
	required uint32 id = 1;
	optional uint32 roleId = 2;
	optional uint32 type = 3;
	optional uint32 level = 4;
	optional uint32 exp = 5;
	optional uint32 choose = 6;
	optional uint32 createTime = 7;
	optional uint32 evolutionCount = 8;
	optional uint32 master = 9;
	optional string skillLevelJson = 10;
	optional uint32 wakeLevel = 11;
	optional string attrsJson=12;
	optional uint32 star = 13;
	optional string battleSoulJson = 14;
}

message BeautyDetail {
	required uint32 id = 1;
	optional uint32 beautyId = 2;
	optional uint32 level = 3;
	optional uint32 exp = 4;
	optional uint32 evolutionCount = 5;
	optional uint32 status = 6;
	optional uint32 potentialHp = 7;
	optional uint32 potentialAtk = 8;
	optional uint32 potentialDef = 9;
}

message BeautyTrain {
	optional BeautyDetail detail = 1;
	optional uint32 expAdd = 2;
	optional uint32 multiple = 3;
}

message ItemDetail {
	required uint32 id = 1;
	optional uint32 count = 2;
}

message EquipDetail {
	required uint32 id = 1;
	optional uint32 type = 2;
	optional uint32 level = 3;
	optional uint32 evolCount = 4;
	optional uint32 evolExp = 5;

}

message MapInfo {
	required uint32 mapId = 1;
	optional uint32 award1Status = 2;
	optional uint32 award2Status = 3;
	optional uint32 award3Status = 4;
}

message CarbonInfo {
	required uint32 carbonId = 1;
	optional uint32 starNum = 2;
	optional uint32 status = 3;
	optional uint32 playCnt = 4;
	optional uint32 buyCnt = 5;
}

message EmaiDetail {
	required uint32 id = 1;
	optional uint32 status = 2;
	optional uint32 createtime = 3;
	optional string title = 4;
	optional string content = 5;
	optional string attachments = 6;
}

message FormationUnit {
	optional uint32 index = 1;		// 从左到右, 从下到上
	optional HeroDetail heroInfo = 2;
}

message ItemInfo {
	optional uint32 id = 1;
	optional uint32 itemTypeId = 2;
	optional uint32 itemId = 3;
	optional uint32 num = 4;
	optional uint32 heroTrunFrag = 5;
}

message ItemList {
	repeated ItemInfo items = 1;
}

message FragmentUnit {
	optional uint32 fragmentId = 1;
	optional int32 num = 2;
}

message PveFormations {
	required uint32 roleId = 1;
	repeated FormationUnit units = 2;
}

message PvpFormations {
	required uint32 roleId = 1;
	repeated FormationUnit units = 2;
}

message BattleHeroInfo {
	optional uint32 id = 1;
	optional uint32 type = 2;	
	optional uint32 index = 3;
	optional string attrsJson = 4;
	optional uint32 level = 5;
	optional uint32 evolutionCount = 6;
	optional string skillLevelJson = 7;
	optional uint32 skillOrder = 8;
}

message BattleData {
	required uint32 roleId = 1;
	repeated BeautyDetail beauties = 2;
	repeated uint32 passiveSkills = 3;
	repeated BattleHeroInfo heros = 4;
}

message KeyValuePair {
	optional string key = 1;
	optional int32 value = 2;
}

message SysErrMsg {
	required uint32 errCode = 1;
	optional uint32 param1 = 2;
	optional uint32 param2 = 3;
	optional uint32 param3 = 4;
	optional uint32 param4 = 5;
}

message SimpleEvent {
	optional uint32 roleId = 1;
	optional int32 param1 = 2;
	optional int32 param2 = 3;
	optional int32 param3 = 4;
	optional int32 param4 = 5;
	optional string param5 = 6;
}

message GmEvent {
	optional string cmd = 1;
	optional int32 pm1 = 2;
	optional int32 pm2 = 3;
	optional int32 pm3 = 4;
}

message RenameEvent {
	optional uint32 roleId = 1;
	optional string param1 = 2;
	optional uint32 param2 = 3;
}

message ChatPlayer {
	optional string name = 1;
	optional uint32 vipLevel = 2;
	optional uint32 mainId = 3;
	optional uint32 level = 4;
	optional uint32 roleId = 5;
}

message ChatMsg {
	optional uint32 err = 1;
	optional uint32 chatType = 2; // 1 世界聊天; 2 公会聊天; 3 私聊 
	optional ChatPlayer player = 3; // 私聊 c2s 发送player(to).name; s2c 发送player(from)所有信息
	optional string content = 5;
	optional uint32 tstamp = 6; // 时间戳
	optional uint32 gold = 7; // 使用元宝  gold == 1 表示使用元宝
}
]]