GameProtos["equip"] =
[[
message EquipActionData {
	repeated uint32 equipIds = 1;
	optional uint32 money = 2;
}

message EquipLevelUpData {
	optional uint32 level = 1;
	optional uint32 count = 2;
	repeated uint32	crit = 3;
}

message EquipEvolData {
	optional uint32 equipId = 1;
	repeated uint32	materialEquipIds = 3;
	repeated uint32	materialFragmentIds = 4;
}

message EquipUpdateProperty {
	required uint32 id = 1;
	required string key = 2;
	optional uint32 newValue = 3;
	optional uint32 oldValue = 4;
}

]]