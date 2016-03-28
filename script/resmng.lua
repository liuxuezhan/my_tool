module("resmng", package.seeall)


local BasePath = "data/"
do_load("reschk")


--------------------------------------------------------------------------------
do_load(BasePath .. "prop_cron")

do_load(BasePath .. "define_resource")
do_load(BasePath .. "define_arm")
do_load(BasePath .. "define_build")
do_load(BasePath .. "define_world_unit")
do_load(BasePath .. "define_buff")
do_load(BasePath .. "define_skill")
do_load(BasePath .. "define_hero_basic")
do_load(BasePath .. "define_hero_cure")
do_load(BasePath .. "define_hero_lv_exp")
do_load(BasePath .. "define_hero_quality")
do_load(BasePath .. "define_hero_skill_exp")
do_load(BasePath .. "define_hero_star_up")
do_load(BasePath .. "define_union_power")
do_load(BasePath .. "define_item")
do_load(BasePath .. "define_union_tech")
do_load(BasePath .. "define_union_donate")
do_load(BasePath .. "define_union_buildlv")
do_load(BasePath .. "define_resm")
do_load(BasePath .. "define_tech")
do_load(BasePath .. "define_genius")
do_load(BasePath .. "define_task_detail")
do_load(BasePath .. "define_equip")


do_load(BasePath .. "prop_arm")
do_load(BasePath .. "prop_build")
do_load(BasePath .. "prop_world_unit")
do_load(BasePath .. "prop_buff")
do_load(BasePath .. "prop_effect_type")
do_load(BasePath .. "prop_skill")
do_load(BasePath .. "prop_hero_basic")
do_load(BasePath .. "prop_hero_cure")
do_load(BasePath .. "prop_hero_lv_exp")
do_load(BasePath .. "prop_hero_quality")
do_load(BasePath .. "prop_hero_skill_exp")
do_load(BasePath .. "prop_hero_star_up")
do_load(BasePath .. "prop_union_power")
do_load(BasePath .. "prop_item")
do_load(BasePath .. "prop_union_tech")
do_load(BasePath .. "prop_union_donate")
do_load(BasePath .. "prop_union_buildlv")
do_load(BasePath .. "prop_resource")
do_load(BasePath .. "prop_resm")
do_load(BasePath .. "prop_resm_num")
do_load(BasePath .. "prop_respawn_lv")
do_load(BasePath .. "prop_respawn_tm")
do_load(BasePath .. "prop_tech")
do_load(BasePath .. "prop_genius")
do_load(BasePath .. "prop_task_detail")
do_load(BasePath .. "prop_equip")

do_check("prop_arm")
do_check("prop_build")
do_check("prop_buff")
do_check("prop_effect_type")
do_check("prop_skill")
do_check("prop_hero_basic")
do_check("prop_hero_cure")
do_check("prop_hero_lv_exp")
do_check("prop_hero_quality")
do_check("prop_hero_skill_exp")
do_check("prop_hero_star_up")
do_check("prop_union_power")
do_check("prop_item")
do_check("prop_union_tech")
do_check("prop_union_donate")
do_check("prop_tech")
do_check("prop_task_detail")

--------------------------------------------------------------------------------
do_load("common/define")


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Function : 根据 prop_name，index 获取配置
-- Argument : prop_name, index
-- Return   : table or nil
-- Others   : NULL
--------------------------------------------------------------------------------
function get_conf(prop_name, index)
    if not prop_name or not index then
        ERROR("get_conf: prop_name = %s, index = %s", prop_name or "nil", index or -1 .. "")
        return
    end

    local conf = resmng[prop_name] and resmng[prop_name][index]
    if not conf then
        ERROR("get_conf: lost config. prop_name = %s, index = %s", prop_name or "nil", index or -1 .. "")
        return
    else
        return conf
    end
end

