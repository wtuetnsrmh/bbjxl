GameProtos["store"] =
[[
message ShopItemsResponse {
	message ShopItem {
		optional uint32 storeId = 1;
		optional uint32 todayBuyCount = 2;
		optional uint32 totalBuyCount = 3;
	}

	repeated ShopItem items = 1;
}

message RechargeResponse {
	optional string rechargeNO = 1;
	optional string orderUUID = 2;
	optional uint32 rmbValue = 3;
	optional string productName = 4;
}

message BuyCardPackageRequest {
	required uint32 roleId = 1;
	optional uint32 packageId = 2;
	optional uint32 drawCard = 3;
	optional uint32 guide = 4;
}

message BuyCardPackageResponse {
	repeated ItemInfo awardItems = 1;
	repeated ItemInfo awardOthers = 2;
	optional uint32 threshold = 3;
	optional uint32 isfirstDraw = 4;
}
]]