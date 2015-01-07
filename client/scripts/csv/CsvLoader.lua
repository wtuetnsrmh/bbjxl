local CsvLoader = {
	configs = {
		-- client/server common
		["roleInfoCsv"] = { parser = "RoleInfoCsv", file = "csv/role_info.csv"},
		["pvpGiftCsv"] = { parser = "PvpGiftCsv", file = "csv/pvp_gift.csv"},
		["itemCsv"] = { parser = "ItemCsv", file = "csv/item.csv",},
		["activitySignCsv"] = { parser = "ActivitySignCsv", file = "csv/activity_qiandao.csv"},
		["battleResultCsv"] = { parser = "BattleResultCsv", file = "csv/battle_result.csv"},
		["storeCsv"] = { parser = "StoreCsv", file = "csv/store.csv"},
		["rechargeCsv"] = { parser = "ReChargeCsv", file = "csv/recharge.csv"},
		["towerDiffCsv"] = { parser = "TowerDiffCsv", file = "csv/tower_diff.csv"},
		["towerBattleCsv"] = { parser = "TowerBattleCsv", file = "csv/tower_battle.csv"},
		["towerAttrCsv"] = { parser = "TowerAttrCsv", file = "csv/tower_attr.csv" },
		["legendBattleCsv"] = { parser = "LegendBattleCsv", file = "csv/legend_battle.csv" },
		["professionPhaseCsv"] = { parser = "ProfessionPhaseCsv", file = "csv/career_class.csv" },
		["professionLevelCsv"] = { parser = "ProfessionLevelCsv", file = "csv/career_level.csv" },
		["heroStarInfoCsv"] = { parser = "HeroStarInfoCsv", file = "csv/herostar_info.csv" },
		["heroStarAttrCsv"] = { parser = "HeroStarAttrCsv", file = "csv/herostar_attr.csv" },
		["towerSceneCsv"] = { parser = "TowerSceneCsv", file = "csv/tower_scene.csv" },
		["beautyListCsv"] = { parser = "BeautyListCsv", file = "csv/beauty_list.csv"},
		["beautyTrainCsv"] = { parser = "BeautyTrainCsv", file = "csv/beauty_train.csv"},
		["beautyEvolutionCsv"] = { parser = "BeautyEvolutionCsv", file = "csv/beauty_evolution.csv"},
		["beautyPotentialCsv"] = { parser = "BeautyPotentialCsv", file = "csv/beauty_potential.csv"},
		["vipCsv"] = { parser = "VipCsv", file = "csv/vip.csv" },
		["zhaoCaiCsv"] = { parser = "ZhaoCaiCsv", file = "csv/zhaocai.csv" },
		["levelGiftCsv"] = { parser = "LevelGiftCsv", file = "csv/level_gift.csv" },
		["newServerCsv"] = { parser = "NewServerCsv", file = "csv/login_gift.csv" },
		["vipCostCsv"] = { parser = "VipCostCsv", file = "csv/function_cost.csv" },
		["dropCsv"] = { parser = "DropCsv", file = "csv/drop.csv" },
		["techItemCsv"] = { parser = "TechItemCsv", file = "csv/tech_item.csv" },
		["functionCostCsv"] = { parser = "FunctionCostCsv", file = "csv/function_cost.csv" },
		["dailyTaskCsv"] = { parser = "DailyTaskCsv", file = "csv/daily_task.csv" },
		["moneyBattleCsv"] = { parser = "MoneyBattleCsv", file = "csv/money_battle.csv" },
		["expBattleCsv"] = { parser = "ExpBattleCsv", file = "csv/exp_battle.csv" },
		["healthCsv"] = { parser = "HealthCsv", file = "csv/daily_gift.csv" },
		["skillLevelCsv"] = { parser = "SkillLevelCsv", file = "csv/skill_level.csv",},
		["skillPassiveLevelCsv"] = { parser = "SkillPassiveLevelCsv", file = "csv/skill_passive_level.csv" },
		["buffCsv"] = { parser = "BuffCsv", file = "csv/buff.csv"},
		["restraintCsv"] = { parser = "RestraintCsv", file = "csv/restraint.csv"},
		["globalCsv"] = { parser = "GlobalCsv", file = "csv/global.csv"},
		["evolutionModifyCsv"] = { parser = "EvolutionModifyCsv", file = "csv/evolution.csv"},
		["heroProfessionCsv"] = { parser = "HeroProfessionCsv", file = "csv/role_profession.csv"},
		["sysMsgCsv"] = { parser = "SysMsgCsv", file = "csv/hint.csv"},
		["plotTalkCsv"] = { parser = "PlotTalkCsv", file = "csv/talk.csv"},
		["musicCsv"] = { parser = "MusicCsv", file = "csv/music.csv"},
		["unitCsv"] = { parser = "UnitCsv", file = "csv/unit.csv", flag = true },
		["guideCsv"] = { parser = "GuideCsv", file = "csv/user_guide.csv" },
		["skillCsv"] = { parser = "SkillCsv", file = "csv/skill.csv", },
		["bulletCsv"] = { parser = "BulletCsv", file = "csv/bullet.csv"},
		["loadingCsv"] = { parser = "LoadingCsv", file = "csv/loading.csv"},
		["equipCsv"] = { parser = "EquipCsv", file = "csv/equip.csv" },	
		["equipSetCsv"] = { parser = "EquipSetCsv", file = "csv/equip_set.csv" },
		["equipLevelCostCsv"] = { parser = "EquipLevelCostCsv", file = "csv/equip_level_cost.csv" },
		["trialBattleCsv"] = { parser = "TrialBattleCsv", file = "csv/shilian_battle.csv" },
		["heroExpCsv"] = { parser = "HeroExpCsv", file = "csv/hero_exp.csv" },
		["ljczCsv"] = { parser = "LjczCsv", file = "csv/ljcz.csv" },
		["fundCsv"] = { parser = "FundCsv", file = "csv/fund.csv" },
		["battleSoulCsv"] = { parser = "BattleSoulCsv", file = "csv/zhanhun.csv" },
		-- client
		["skillPassiveCsv"] = {parser = "SkillPassiveCsv", file = "csv/skill_passive.csv",},

		["shopOpenCsv"] = { parser = "ShopOpenCsv", file = "csv/shop_opening.csv" },
		["shopCsv"] = { parser = "ShopCsv", file = "csv/shop.csv" },

		["forceMatchCsv"] = { parser = "ForceMatchCsv", file = "csv/force_match.csv" },

		["activityTipsCsv"] = { parser = "ActivityTipsCsv", file = "csv/shilian_info.csv" },
	},
}

local function loadWhileUse(t, f)
	local m = {}
	t.__index = function (self, key)
		if t.m_data and  next(t.m_data) then
			return t[key]
		else
			f(t)
			return t[key]
		end
	end

	return setmetatable(m, t)
end

function CsvLoader.loadCsv()
	mapInfoCsv = loadWhileUse(require("csv.MapInfoCsv"), function (self)
			self:load({ "csv/chapter_info.csv", "csv/challenge_info.csv", })
		end)

	mapBattleCsv = loadWhileUse(require("csv.MapBattleCsv"), function (self)
			self:load({ "csv/chapter_battle.csv", "csv/challenge_battle.csv" })
		end)

	for name, data in pairs(CsvLoader.configs) do
		if data.flag then
			_G[name] = require("csv." .. data.parser)
			_G[name]:load(data.file)
		else
			_G[name] = loadWhileUse(require("csv." .. data.parser), function (self)
				self:load(data.file)
			end)
		end
	end
end

return CsvLoader


