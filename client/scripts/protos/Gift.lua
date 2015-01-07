GameProtos["gift"] = 
[[
message GiftDetail {
	required uint32 id = 1;
	optional uint32 itemId = 2;
	optional uint32 createTime = 3;
}

message GiftList {
	optional uint32 totalGiftCnt = 1;
	repeated GiftDetail gifts = 2;
}

message ReceiveGiftReqeust {
	required uint32 roleId = 1;
	optional uint32 giftId = 2;
}

message ReceiveGiftResponse {
	enum ReceiveResult {
		SUCCESS = 0;
		FAIL = 1;
	}
	required ReceiveResult errorCode = 1;
	optional uint32 giftId = 2;
}
]]