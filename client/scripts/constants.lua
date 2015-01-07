-- 万能进化卡
UniversalEvolutionHeroIds = {
	[997] = true,
	[998] = true,
	[999] = true,
}

-- 角色状态
RoleStatus = {
    Idle = 0,
    Battle = 1,
    PvP = 2,
}

BattleType = { PvE = 1, PvP = 2, Tower = 3, Legend = 4, Start = 5, Money = 6, Exp = 7,Exped=8, Trial = 9}--Exped:远征

-- PVP的常量值
PVP_OPEN_LEVEL = 1
PVP_BUY_LIMIT = 10
PVP_CD_TIME = 600
PVP_HISTORY_LIMIT = 50

-- 好友常量
FRIEND_RANDOM_SEARCH_LIMIT = 10
FRIEND_DONATE_HEALTH_TIMES = 20
FRIEND_DONATE_HEALTH_UNIT = 1

FRIEND_RECEIVE_HEALTH_TIMES = 20

-- 聊天常量
CHAT_WORLD_RECORD_MAX = 50
CHAT_GUILD_RECORD_MAX = 50
CHAT_PERSON_RECORD_MAX = 50

-- 邮件过期时间
MAIL_EXPIRE_TIME = 7*24*3600

--最大星级
HERO_MAX_STAR = 5 
--最大装备进化等级
EQUIP_MAX_EVOL = 10
-- 物品类型ID
ItemTypeId = {
	--[[ 1=礼包，2=金币，3=元宝，4=体力，5=战场次数，6=精英副本次数，7=武将卡牌，8=武将碎片，9=技能
	10=令牌, 11=星魂, 12=将魂, 13=胭脂, 14=武将进化材料，15=美人宠幸材料 ]]
	Gift = 1,
	GoldCoin = 2,
	Yuanbao = 3,
	Health = 4,
	PvpCount = 5,
	SpecialBattleCount = 6,
	Hero = 7,
	HeroFragment = 8,
	Skill = 9,
	Lingpai = 10,
	StarSoul = 11,
	HeroSoul = 12,
	HeroEvolution = 14,
	Beauty = 15,
	Package = 19,
	RandomFragmentBox = 20,
	RandomItemBox = 21,
	ZhanGong = 22,
	SkillLevel = 23,
	Equip = 24,
	EquipFragment = 25,
	Reputation = 26,	-- 声望
	HeroExp = 27,		--英雄exp
	Useless = 28,		--无用物品，用于出售
}

StoreType = {
	Shop1 = 1, -- 商店1
	Shop2 = 2, -- 商店2
	Shop3 = 3, -- 商店3
	Shop4 = 4, -- 商店4
	PvpShop = 5, -- 战功商店
	Mall = 6, -- 商城
}

YzDrawType = {
	HasNotDraw = 1,
	HasDraw = 2,
	CantDraw = 3,
}