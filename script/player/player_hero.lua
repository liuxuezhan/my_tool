--------------------------------------------------------------------------------
-- Desc     : player hero.
-- Author   : Yang Cong
-- History  :
--     2016-1-25 19:43:18 Created
-- Copyright: Chengdu Tapenjoy Tech Co.,Ltd
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
module("player_t")


--------------------------------------------------------------------------------
function make_hero(self, propid)
    local hs = self:get_hero()
    for idx = 1, 100, 1 do
        if not hs[idx] then
            local h = hero_t.new(idx, self.pid, propid)
            if h then
                self._hero[ idx ] = h
            end
            return
        end
    end
end


function get_hero(self, idx)
    if not self._hero then self._hero = {} end
    if idx then
        if type(idx) == "string" then idx = tonumber(idx) end
        if self._hero then return self._hero[ idx ] end
    else
        return self._hero
    end
end


--------------------------------------------------------------------------------
-- Function : 根据 propid 获取 hero
-- Argument : self, propid
-- Return   : hero / false
-- Others   : NULL
--------------------------------------------------------------------------------
function get_hero_by_propid(self, propid)
    if not propid then
        ERROR("is_have_hero: pid = %d, propid = %d", self.pid or -1, propid or -1)
        return false
    end

    for idx, hero in pairs(self:get_hero()) do
        if hero.propid == propid then
            return hero
        end
    end

    return false
end


--------------------------------------------------------------------------------
-- Function : 使用碎片召唤英雄
-- Argument : self, piece_item_id
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function call_hero_by_piece(self, hero_propid)
    if not hero_propid then
        ERROR("call_hero_by_piece: hero_propid = %d.", hero_propid or -1)
        return
    end

    local hero = self:get_hero_by_propid(hero_propid)
    if not hero then
        local conf = resmng.get_conf("prop_hero_basic", hero_propid)
        if not conf then
            return
        end

        if self:dec_item_by_item_id(conf.PieceID, conf.CallPrice, VALUE_CHANGE_REASON.HERO_CREATE) then
            self:make_hero(hero_propid)
        else
            local piece_have = self:get_item_num(conf.PieceID)
            ERROR("call_hero_by_piece: pid = %d, hero_propid = %d, conf.PieceID = %d, piece_have = %d < conf.CallPrice = %d",
                   self.pid, hero_propid, conf.PieceID, piece_have, conf.CallPrice)
            return
        end
    else
        ERROR("call_hero_by_piece: player already have this hero. pid = %d, hero_propid = %d.", self.pid, hero_propid)
        return
    end
end


--------------------------------------------------------------------------------
-- Function : 英雄升星
-- Argument : self, hero_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function hero_star_up(self, hero_idx)
    if not hero_idx then
        ERROR("hero_star_up: pid = %d, hero_idx = %d", self.pid or -1, hero_idx or -1)
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("hero_star_up: get_hero() failed. pid = %d, hero_idx = %d", self.pid or -1, hero_idx)
        return
    else
        hero:star_up()
    end
end

--------------------------------------------------------------------------------
-- Function : 英雄升级
-- Argument : self, hero_id, item_idx, num
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function hero_lv_up(self, hero_idx, item_idx, num)
    if not hero_idx or not item_idx or not num or num <= 0 then
        ERROR("hero_lv_up: hero_idx = %d, item_idx = %d, num = %d", hero_idx or -1, item_idx or -1, num or -1)
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("hero_lv_up: get_hero() failed. pid = %d, hero_idx = %d.", self.pid, hero_idx)
        return
    end

    if not hero:can_lv_up() then
        return
    end

    local item = self:get_item(item_idx)
    if not item then
        ERROR("hero_lv_up: get_item() failed. pid = %d, item_idx = %d.", self.pid, item_idx)
        return
    else
        local conf = resmng.get_conf("prop_item", item[2])
        if not conf then
            return
        end

        if conf.Class ~= ITEM_CLASS.HERO or conf.Mode ~= ITEM_HERO_MODE.EXP_BOOK then
            ERROR("hero_lv_up: not hero exp book. pid = %d, item_idx = %d, item_id= %d, conf.Class = %d, conf.Mode = %d.",
                   self.pid, item_idx, item[2], conf.Class, conf.Mode)
            return
        else

            if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.HERO_LV_UP) then
                hero:gain_exp(conf.Param[1] * num)
            else
                return
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 查询所有英雄的详细信息
-- Argument : self, pid
-- Return   : NULL
-- Others   : pid
--------------------------------------------------------------------------------
function get_hero_list_info(self, pid)
    if self.pid ~= pid then
        return ERROR("get_hero_list_info: not allowed to get other players' info. self.pid = %d, pid = %d", self.pid, pid)
    end

    local ply = getPlayer(pid)
    if not ply then
        return LOG("get_hero_list_info: getPlayer(pid = %d) failed.", pid or -1)
    end

    local hero_list_info = {}
    for idx, hero in pairs(ply:get_hero()) do
        local hero_info = hero:gen_hero_info(true)
        table.insert(hero_list_info, hero_info)
    end

    return Rpc:on_get_hero_list_info(self, hero_list_info)
end


--------------------------------------------------------------------------------
-- Function : 查询指定英雄的详细信息
-- Argument : self, hero id
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function get_hero_detail_info(self, hero_id)
    if not hero_id then
        return LOG("get_hero_detail_info: no hero_id.")
    end

    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if not hero then
        return LOG("get_hero_detail_info: get hero failed, hero_id = %s", hero_id)
    end

    -- 暂时只允许查看自己的英雄，以后有需求再放开
    if hero.pid ~= self.pid then
        return ERROR("get_hero_detail_info: not allowed to get other players' info. self.pid = %d, hero_id = %s", self.pid, hero_id)
    end

    local hero_detail_info = hero:gen_hero_info(true)
    return Rpc:on_get_hero_detail_info(self, hero_detail_info)
end


--------------------------------------------------------------------------------
-- Function : 派遣英雄
-- Argument : self, build_idx, hero_idx, ignore_update_ef_hero
-- Return   : NULL
-- Others   : hero_idx = 0 表示取消派遣; ignore_update_ef_hero 表示是否忽略调用 update_ef_hero()
--------------------------------------------------------------------------------
function dispatch_hero(self, build_idx, hero_idx, ignore_update_ef_hero)
    if not build_idx or not hero_idx then
        ERROR("dispatch_hero: build_idx = %d, hero_idx = %d.", build_idx or -1, hero_idx or -1)
        return
    end

    local build = self:get_build(build_idx)
    if not build then
        ERROR("dispatch_hero: get_build() failed. pid = %d, build_idx = %d", self.pid, build_idx)
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero and hero_idx ~= 0 then
        ERROR("dispatch_hero: get_hero() failed. pid = %d, hero_idx = %d", self.pid, hero_idx)
        return
    end

    if build.hero_idx == hero_idx then
        ERROR("dispatch_hero: repeated dispatch. pid = %d, build_idx = %d, hero_idx = %d", self.pid, build_idx, hero_idx)
        return
    end

    -- 清理旧的派遣
    local old_dispatch_hero = self:get_hero(build.hero_idx)
    if old_dispatch_hero then
        old_dispatch_hero.build_idx = 0
        old_dispatch_hero.status = HERO_STATUS_TYPE.FREE
    end
    if hero then
        local old_dispatch_build = self:get_build(hero.build_idx)
        if old_dispatch_build then
            self:dispatch_hero(hero.build_idx, 0, true)
        end
    end

    -- 记录新的派遣
    build.hero_idx = hero_idx
    if hero then
        hero.build_idx = build_idx
        hero.status = HERO_STATUS_TYPE.BUILDING
    end

    -- 更新 BUFF
    if not ignore_update_ef_hero then
        self:update_ef_hero()
    end

    LOG("dispatch_hero: build._id= %d, hero_idx = %d", self._id, hero_idx)
end


--------------------------------------------------------------------------------
-- Function : 更新 self._ef_hero
-- Argument : self, is_init
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function update_ef_hero(self, is_init)
    local old_ef_hero = self._ef_hero
    self._ef_hero = {}

    -- 遍历英雄，更新 BUFF
    for _, hero in pairs(self:get_hero()) do
        local build = self:get_build(hero.build_idx)
        if build then
            local buff_list = hero:gen_build_buff_info()
            for _, buff_id in pairs(buff_list) do
                local buff_conf = resmng.get_conf("prop_buff", buff_id)
                if buff_conf and buff_conf.Cond then
                    -- 将 buff 转换成对应的数值加成
                    if build:cond_check(unpack(buff_conf.Cond)) then
                        for effect_name, effect_value in pairs(buff_conf.Value) do
                            self._ef_hero[effect_name] = (self._ef_hero[effect_name] or 0) + effect_value
                        end
                    end
                else
                    ERROR("update_ef_hero: get prop_buff conf failed. hero._id = %s, buff_id = %d,", hero._id, buff_id)
                end
            end
        end
    end

    if not is_init then
        -- 重新计算科技、资源、医疗和造兵的加速效果
        self:recalc_build_work(old_ef_hero)
    end

    -- 同步 ef_hero 变化
    -- TODO: 如果前端不需要同步的话就删掉
    Rpc:state_ef_hero(self, self._ef_hero)

    LOG("update_ef_hero: pid = %d", self.pid or -1)
end


--------------------------------------------------------------------------------
-- Function : 对比新旧 ef_hero, 返回变化的部分
-- Argument : self, old_ef_hero
-- Return   : {effect_name_1 = effect_val_1, ...}
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_ef_hero_change(self, old_ef_hero)
    old_ef_hero = old_ef_hero or {}
    local ef_hero_change = copyTab(self._ef_hero)
    for effect_name, effect_value in pairs(old_ef_hero) do
        ef_hero_change[effect_name] = ef_hero_change[effect_name] or 0
        if ef_hero_change[effect_name] == effect_value then
            ef_hero_change[effect_name] = nil
        end
    end

    return ef_hero_change
end


--------------------------------------------------------------------------------
-- Function : 分解英雄，返还经验卡
-- Argument : self, hero_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function destroy_hero(self, hero_idx)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("destroy_hero: get hero failed. pid = %d, hero_idx = %d", self.pid, hero_idx or -1)
        return
    end

    local exp = hero:calc_total_exp()

    -- 判断状态是否正确
    if hero.status ~= HERO_STATUS_TYPE.FREE or hero.status ~= HERO_STATUS_TYPE.BUILDING or hero.status ~= HERO_STATUS_TYPE.BEING_CURED then
        return
    end

    -- 解除派遣
    if hero.build_idx ~= 0 then
        self:dispatch_hero(hero.build_idx, 0)
    end

    if heromng.destroy_hero(hero._id) then
        Rpc:on_destroy_hero(self, hero_idx)
        -- 返还技能经验卡
        self:return_skill_exp_item(hero, VALUE_CHANGE_REASON.DESTROY_HERO)
        -- 返还英雄经验
        self:return_exp_item(exp * DESTROY_HERO_RETURN_RATIO, VALUE_CHANGE_REASON.DESTROY_HERO)
    end
end


--------------------------------------------------------------------------------
-- Function : 根据经验值返回经验值道具
-- Argument : self, exp, reason
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function return_exp_item(self, exp, reason)
    if not exp or (reason ~= VALUE_CHANGE_REASON.RESET_SKILL and reason ~= VALUE_CHANGE_REASON.DESTROY_HERO) then
        ERROR("return_exp_item: exp = %d, reason = %d.", exp or -1, reason or -1)
        return
    end

    -- 统计经验道具
    local exp_item = {}
    if reason == VALUE_CHANGE_REASON.RESET_SKILL then
        for item_id, info in pairs(resmng.prop_item) do
            if info.Class == ITEM_CLASS.SKILL and info.Mode == ITEM_SKILL_MODE.COMMON_BOOK then
                table.insert(exp_item, {["item_id"] = item_id, ["exp"] = info.Param[2]})
            end
        end
    else
        for item_id, info in pairs(resmng.prop_item) do
            if info.Class == ITEM_CLASS.HERO and info.Mode == ITEM_HERO_MODE.EXP_BOOK then
                table.insert(exp_item, {["item_id"] = item_id, ["exp"] = info.Param[1]})
            end
        end
    end

    local func_sort = function (node_1, node_2)
        return node_1.exp > node_2.exp
    end
    table.sort(exp_item, func_sort)

    -- 计算道具
    local item_list = {}
    for _, v in pairs(exp_item) do
        local num = math.floor(exp / v.exp)
        if num > 0 then
            table.insert(item_list, {["item_id"] = v.item_id, ["num"] = num})
        end
        exp = exp - num * v.exp
        if exp < exp_item[#exp_item].exp then
            break
        end
    end

    -- 发放道具
    for _, v in pairs(item_list) do
        self:inc_item(v.item_id, v.num, reason)
    end
    dumpTab(item_list, string.format("return_exp_item: pid = %d, item_list = ", self.pid))
end


--------------------------------------------------------------------------------
-- Function : 关押hero
-- Argument : self, hero_id
-- Return   : NULL
-- Others   : 部队回城时调用
--------------------------------------------------------------------------------
function imprison_hero(self, hero_id)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if not hero then
        ERROR("imprison_hero: get hero failed. pid = %d, hero_id = %s", self.pid, hero_id)
        return
    else
        if hero.status ~= HERO_STATUS_TYPE.BEING_CAPTURED then
            ERROR("imprison_hero: pid = %d, hero_id = %s, hero.status = %d.", self.pid, hero_id, hero.status)
            return
        end
    end

    local prison = self:get_prison()
    if not prison then
        ERROR("imprison_hero: get prison failed. pid = %d.", self.pid)
        return
    end

    local conf = resmng.get_conf("prop_build", prison.propid)
    if not conf or not conf.Param or not conf.Param.time or not conf.Param.count then
        ERROR("imprison_hero: get prison conf failed. pid = %d, prison.propid = %d.", self.pid, prison.propid)
        dumpTab(conf or {}, "prison_conf")
        return
    end

    if #prison.extra.prisoners_info >= conf.Param.count then
        -- 达到容量上限，释放最早俘虏的hero
        local first_prison_id = prison.extra.prisoners_info[1] and prison.extra.prisoners_info[1].hero_id
        self:release_prisoner(first_prison_id)
    end

    -- put in prison
    hero.status = HERO_STATUS_TYPE.BEING_IMPRISONED
    local chg = prison.extra.prisoners_info
    table.insert(chg, {["hero_id"] = hero_id, ["prison_start_tm"] = gTime})
    prison:update_extra({["prisoners_info"] = chg})

    -- notify client.
    self:get_prisoners_info()

    -- new timer
    local prison_time = conf.Param.time * 60

    hero.tm_sn = timer.new("release_prisoner", prison_time, self.pid, hero_id)
end


--------------------------------------------------------------------------------
-- Function : 关押到期，释放俘虏
-- Argument : self, hero_id
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function release_prisoner(self, hero_id, sn)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if not hero then
        return
    else
        if sn and sn ~= hero.tm_sn then
            -- 已被主动释放或者处斩
            return
        end
    end

    if self:rm_prisoner(hero_id) then
        -- 行军返回城市
        self:let_prison_back_home(hero_id)
    end
end


--------------------------------------------------------------------------------
-- Function : 俘虏行军返回城市
-- Argument : hero_id
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function let_prison_back_home(self, hero_id)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if hero then
        hero.tm_sn    = 0
        hero.capturer = 0
        hero.status   = HERO_STATUS_TYPE.MOVING

        local ply = getPlayer(hero.pid)
        if ply then
            local des_id = {["eid"] = ply.eid}
            local troop_info = {["res"] = {["hero_idx"] = hero.idx}, ["src_pos"] = {["x"] = self.x, ["y"] = self.y}}
            ply:troop_go(resmng.TroopAction.PRISON_BACK_HOME, des_id, troop_info)
        else
            ERROR("let_prison_back_home: get player failed. pid = %d, hero._id = %s, hero.pid = %d.", self.pid, hero._id, hero.pid)
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 处死英雄
-- Argument : self, hero_id, buff_idx 选择的哪个buff
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function kill_hero(self, hero_id, buff_idx)
    local prison_idx = self:is_in_prison(hero_id)
    if not prison_idx then
        ERROR("kill_hero: pid = %d, hero_id = %s", self.pid, hero_id or "")
        return
    end

    local hero = heromng.get_hero_by_uniq_id(hero_id)
    local hero_owner = getPlayer(hero.pid)
    if not hero_owner then
        ERROR("kill_hero: get hero owner failed, pid = %d.", hero.pid)
        return
    end

    local prison = self:get_prison()
    if not prison then
        ERROR("kill_hero: get prison failed. pid = %d.", self.pid)
        return
    end

    local altar = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ALTAR)
    if not altar or altar.state ~= BUILD_STATE.WAIT then
        ERROR("kill_hero: altar not valid. pid = %d, altar.state = %d.", self.pid, altar and altar.state or -1)
        return
    end

    local conf = resmng.get_conf("prop_build", altar.propid)
    if not conf or not conf.Param then
        ERROR("kill_hero: get conf.Param failed. pid = %d", self.pid)
        return
    end
    local kill_time = conf.Param.kill_time
    local buff_time = conf.Param.buff_time
    local new_buff_id = conf.Param.buffs[buff_idx]
    if not kill_time then
        ERROR("kill_hero: get kill_time failed.")
        return
    end

    if not self:rm_prisoner(hero_id) then
        ERROR("kill_hero: rm_prisoner failed. pid = %d, hero_id = %d.", self.pid, hero_id)
        return
    end
    hero.tm_sn = 0
    hero.status = HERO_STATUS_TYPE.BEING_EXECUTED

    local chg = {
        ["hero_id"]       = hero_id,
        ["kill_start_tm"] = gTime,
        ["kill_over_tm"]  = gTime + kill_time,
    }
    altar:update_extra(chg)

    altar.state   = BUILD_STATE.WORK
    altar.tmStart = gTime
    altar.tmOver  = gTime + kill_time
    altar.tmSn    = timer.new("kill_hero", kill_time, self.pid, altar.idx, hero_id, new_buff_id, buff_time)

    -- notify client.
    self:get_prisoners_info()

    -- 世界频道公告处决信息
    local msg = string.format("%s的英雄%s正在被%s处决!", hero_owner.name, hero.name, self.name)
    self:chat(resmng.ChatChanelEnum.World, msg)
end


--------------------------------------------------------------------------------
-- Function : 真正的处决英雄
-- Argument : self, hero_id, new_buff_id, buff_time
-- Return   : succ - true; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function real_kill_hero(self, hero_id, new_buff_id, buff_time)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if not hero or hero.status ~= HERO_STATUS_TYPE.BEING_EXECUTED then
        ERROR("real_kill_hero: pid = %d, hero_id = %s, hero.status = %d.", self.pid, hero_id or "", hero and hero.status or -1)
        return
    end

    local altar = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ALTAR)
    if not altar then
        ERROR("real_kill_hero: get altar failed. pid = %d", self.pid)
        return
    end

    if new_buff_id then
        -- remove old buff
        if altar.extra.curr_buff_id then
            self:update_kill_buff(altar.extra.curr_buff_id)
        end

        -- add new buff
        self:update_kill_buff(new_buff_id, true, buff_time)

        -- new timer to delete new buff.
        timer.new("delete_kill_buff", buff_time, self.pid, new_buff_id)
    end

    hero.status = HERO_STATUS_TYPE.DEAD
    -- altar.state = BUILD_STATE.WAIT

    local chg = {"hero_id", "kill_start_tm", "kill_over_tm"}
    altar:clear_extra(chg)

    -- new timer destroy hero.
    timer.new("destroy_dead_hero", RELIVE_HERO_DAYS_LIMIT * 24 * 60 * 60, hero_id)
end


--------------------------------------------------------------------------------
-- Function : 从监狱中移除指定英雄
-- Argument : self, hero_id
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function rm_prisoner(self, hero_id)
    local idx = self:is_in_prison(hero_id)
    if not idx then
        ERROR("rm_prisoner: pid = %d, hero_id = %s, not in prison.", self.pid, hero_id or -1)
        return false
    end

    local prison = self:get_prison()
    local chg = prison.extra.prisoners_info
    table.remove(chg, idx)
    prison:update_extra({["prisoners_info"] = chg})

    Rpc:on_get_out_of_prison(self, hero_id)
    return true
end


--------------------------------------------------------------------------------
-- Function : 添加或者删除 kill_buff
-- Argument : self, buff_id, is_add
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function update_kill_buff(self, buff_id, is_add, buff_time)
    -- TODO: 根据英雄战力计算buff加成
    local buff_conf = resmng.get_conf("prop_buff", buff_id)
    if buff_conf then
        -- TODO: check cond ???
        for effect_name, effect_value in pairs(buff_conf.Value) do
            if is_add then
                self._ef_hero[effect_name] = (self._ef_hero[effect_name] or 0) + effect_value
            else
                self._ef_hero[effect_name] = (self._ef_hero[effect_name] or 0) - effect_value
            end
        end
        LOG("update_kill_buff: pid = %d, buff_id = %d, is_add = %s.", self.pid, buff_id, is_add and "true" or "false")
    else
        ERROR("update_kill_buff: get prop_buff conf failed. pid = %d, buff_id = %d,", self.pid, buff_id)
    end

    -- modify kill_buff info.
    local altar = self:get_altar()
    if not altar then
        ERROR("update_kill_buff: get altar failed. pid = %d.", self.pid)
        return
    else
        if is_add then
            local chg = {
                ["curr_buff_id"] = buff_id,
                ["buff_over_tm"] = gTime + buff_time,
            }
            altar:update_extra(chg)
        else
            altar:clear_extra({"curr_buff_id", "buff_over_tm"})
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 校验某个英雄是否被关押在监狱中
-- Argument : self, hero_id
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function is_in_prison(self, hero_id)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if not hero then
        ERROR("is_in_prison: get hero failed. pid = %d, hero_id = %s", self.pid, hero_id)
        return false
    else
        if hero.status ~= HERO_STATUS_TYPE.BEING_IMPRISONED then
            ERROR("is_in_prison: pid = %d, hero_id = %s, hero.status = %d.", self.pid, hero_id, hero.status)
            return false
        end
    end

    local prison = self:get_prison()
    if not prison then
        ERROR("is_in_prison: get prison failed. pid = %d.", self.pid)
        return false
    else
        for k, v in pairs(prison.extra.prisoners_info) do
            if v.hero_id == hero_id then
                return k
            end
        end

        return false
    end
end


--------------------------------------------------------------------------------
-- Function : 复活英雄
-- Argument : self, hero_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function relive_hero(self, hero_idx)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("relive_hero: get hero failed. pid = %d, hero_idx = %d.", self.pid, hero_idx or -1)
        return
    else
        if hero.status ~= HERO_STATUS_TYPE.DEAD then
            ERROR("relive_hero: pid = %d, hero_idx = %d, hero.status(%d) ~= HERO_STATUS_TYPE.DEAD.", self.pid, hero_idx, hero.status)
            return
        end
    end

    -- 消耗资源、金币
    local cons = self:calc_relive_price(hero_idx)
    if self:dec_cons(cons, VALUE_CHANGE_REASON.RELIVE_HERO) then
        hero.status = HERO_STATUS_TYPE.FREE
    end
end


--------------------------------------------------------------------------------
-- Function : 计算复活价格
-- Argument : self, hero_id
-- Return   : {}
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_relive_price(self, hero_idx)
    -- TODO: 调试代码，扣除10个金币
    return {{resmng.CLASS_RES, resmng.DEF_RES_GOLD, 10}}
end


--------------------------------------------------------------------------------
-- Function : 获得当前祭坛的配置信息
-- Argument : self
-- Return   : succ - {}; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function get_altar_conf(self)
    local altar = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ALTAR)
    if not altar then
        ERROR("get_altar_conf: get altar failed. pid = %d", self.pid)
        return false
    end

    local conf = resmng.get_conf("prop_build", altar.propid)
    if not conf then
        ERROR("get_altar_conf: failed. pid = %d, altar.prop_build = %d", self.pid, altar.prop_build)
        return false
    end
    return conf
end


--------------------------------------------------------------------------------
-- Function : 治疗hero
-- Argument : self, hero_idx, delta_hp 血量增量
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function cure_hero(self, hero_idx, delta_hp)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("cure_hero: get hero failed. pid = %d, hero_idx = %d", self.pid, hero_idx or -1)
        return
    end

    if delta_hp <= 0 or (delta_hp + hero.hp) > hero.max_hp then
        ERROR("cure_hero: pid = %d, hero_idx = %d, delta_hp = %d, hero.hp = %d, hero.max_hp= %d", self.pid, hero_idx, delta_hp, hero.hp, hero.max_hp)
        return
    end

    -- 计算治疗费用
    local conf = resmng.get_conf("prop_hero_cure", resmng.CURE_PRICE)
    if not conf then
        ERROR("cure_hero: get prop_hero_cure config failed.")
        return
    end

    local cost = copyTab(conf.Cons)
    for _, v in pairs(cost) do
        v[3] = v[3] * delta_hp
    end

    if self:dec_cons(cost, VALUE_CHANGE_REASON.CURE_HERO) then
        -- 启动定时器
        local cure_time = self:calc_real_dura("CureSpeed", delta_hp)

        hero.state = HERO_STATUS_TYPE.BEING_CURED
        hero.tm_sn = timer.new("cure_hero", cure_time, self.pid, hero_idx, delta_hp)

        LOG("cure_hero: pid = %d, hero_idx = %d, delta_hp = %d", self.pid, hero_idx, delta_hp)
    end
end


--------------------------------------------------------------------------------
-- Function : 治疗定时器返回
-- Argument : self, tm_sn, hero_idx, delta_hp
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function do_timer_cure_hero(self, tm_sn, hero_idx, delta_hp)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("do_timer_cure_hero: get hero failed. pid = %d, hero_idx = %d", self.pid, hero_idx)
        return
    end

    if hero.tm_sn ~= tm_sn then
        hero.tm_sn = 0
        return
    else
        hero.tm_sn = 0
    end

    local des_hp = hero.hp + delta_hp
    hero.hp = (des_hp <= hero.max_hp) and des_hp or hero.max_hp
    hero.status = HERO_STATUS_TYPE.FREE
end


--------------------------------------------------------------------------------
-- Function : 取消治疗
-- Argument : self, hero_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function cancel_cure_hero(self, hero_idx)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("cancel_cure_hero: get hero failed. hero_idx = %d", hero_idx)
        return
    end

    -- 计算资源
    local node = timer.get(hero.tm_sn)
    local delta_hp = node and node.param and node.param[3]
    if delta then
        ERROR("cancel_cure_hero: get delta_hp failed. pid = %d, hero_idx = %d, hero.tm_sn = %d", self.pid, hero_idx, hero.tm_sn)
        hero.tm_sn = 0
        return
    end

    local conf = resmng.get_conf("prop_hero_cure", resmng.CURE_PRICE)
    if not conf then
        ERROR("cure_hero: get prop_hero_cure config failed.")
        return
    end

    local cost = copyTab(conf.Cons)
    for _, v in pairs(cost) do
        v[3] = math.floor(v[3] * delta_hp * CANCEL_CURE_RETURN_RATIO)
    end

    -- 返回道具和资源
    self:inc_cons(cost, VALUE_CHANGE_REASON.CANCEL_CURE_HERO)

    -- 修改状态
    hero.tm_sn = 0
    hero.status = HERO_STATUS_TYPE.FREE
end


--------------------------------------------------------------------------------
-- Function : 想前端推送俘虏信息
-- Argument : self
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function get_prisoners_info(self)
    local prison = self:get_prison()
    if not prison then
        ERROR("get_prisoners_info: get prison failed. pid = %d.", self.pid)
        return
    end

    local gen_prisoner_info = function(info)
        local hero = heromng.get_hero_by_uniq_id(info.hero_id)
        if hero then
            local ply = getPlayer(hero.pid)
            if ply then
                local t = {
                    hero_id         = hero._id,
                    propid          = hero.propid,
                    star            = hero.star,
                    lv              = hero.lv,
                    fight_power     = hero.fight_power,
                    prison_start_tm = info.prison_start_tm,
                    kill_start_tm   = info.kill_start_tm,
                    kill_over_tm    = info.kill_over_tm,
                    player_name     = ply.name,
                    player_id       = ply._id,
                    union_name      = "",
                }

                local union = ply:union()
                if union then t.union_name = union.name end
                return t
            else
                ERROR("get_prisoners_info: get player failed. pid = %d, hero_id = %d, hero.pid = %d", self.pid, hero_id, hero.pid)
            end
        else
            ERROR("get_prisoners_info: get hero failed. pid = %d, hero_id = %d.", self.pid, hero_id)
        end
    end

    local ret = {}
    for _, info in pairs(prison.extra.prisoners_info) do
        local t = gen_prisoner_info(info)
        if t then table.insert(ret, t) end
    end

    local altar = self:get_altar()
    if altar and altar.extra.hero_id then
        local t = gen_prisoner_info(altar.extra)
        if t then table.insert(ret, t) end
    end

    Rpc:on_get_prisoners_info(self, ret)
end


--------------------------------------------------------------------------------
-- Function : 指定守城英雄
-- Argument : self, def_heros = {步兵英雄hero_idx, 骑兵hero_idx, 弓兵hero_idx, 车兵hero_idx}
-- Return   : NULL
-- Others   : hero_idx = 0 表示取消该类兵种英雄设置
--------------------------------------------------------------------------------
function set_def_hero(self, def_heros)
    -- check params.
    local count = {}
    for i = 1, 4 do
        local hero_idx = def_heros[i]
        if hero_idx ~= 0 then
            count[hero_idx] = (count[hero_idx] or 0) + 1
            if count[hero_idx] > 1 then
                ERROR("set_def_hero: repeated hero_idx. pid = %d, hero_idx = %d.", self.pid, hero_idx)
                dumpTab(def_heros, string.format("set_def_hero[%d]", self.pid))
                return
            end

            local hero = self:get_hero(hero_idx)
            if not hero or not hero:can_def() then
                ERROR("set_def_hero: pid = %d, hero_idx = %d, hero.status = %d.", self.pid, hero_idx, hero and hero.status or -1)
                return
            end
        end
    end

    local flag = false
    local tmp = self.def_heros
    for i = 1, 4 do
        if tmp[i] ~= def_heros[i] then
            tmp[i] = def_heros[i]
            flag = true
        end
    end
    if flag then
        self.def_heros = tmp
    end
end


--------------------------------------------------------------------------------
-- Function : get_def_hero
-- Argument : self
-- Return   : {{fight_attr}, false, {fight_attr}, false}
-- Others   : NULL
--------------------------------------------------------------------------------
function get_def_hero(self)
    local ret = {}

    -- 优先取玩家设置的守城英雄
    for k = 1, 4 do
        local hero_idx = self.def_heros[k]
        if hero_idx then
            -- TODO: 俘虏、关押、斩杀、分解、治疗英雄时，维护 def_heros ?
            local hero = self:get_hero(hero_idx)
            if hero and hero:can_def() then
                ret[k] = hero._id
            end
        end
    end

    -- 空缺位置，按照步、骑、弓、车顺序，选取战力高的英雄依次补齐
    if get_table_valid_count(ret) < 4 then
        local can_def_heros = {}
        for hero_idx, hero in pairs(self:get_hero()) do
            if not is_in_table(ret, hero._id) and hero:can_def() then
                table.insert(can_def_heros, {["hero_id"] = hero._id, ["fight_power"] = hero.fight_power})
            end
        end

        local func_sort = function (node_1, node_2)
            return node_1.fight_power > node_2.fight_power
        end
        table.sort(can_def_heros, func_sort)

        for k = 1, 4 do
            if not ret[k] and next(can_def_heros) then
                local t = table.remove(can_def_heros, 1)
                ret[k] = t.hero_id
            end
        end
    end

    return ret
end


----------------------------------------------------------------------------------
-- Function : return_skill_exp_item
-- Argument : self
-- Return   : NULL
-- Others   : NULL
----------------------------------------------------------------------------------
function return_skill_exp_item(self, hero, reason)
    local skills = hero.basic_skill
    local total_exp = 0
    for k, v in pairs(skills) do
        local skill_id = v[1]
        local skill_exp = v[2]
        if skill_id ~= 0 and skill_exp ~= 0 then
            local cur_lv = resmng.prop_skill[skill_id].Lv
            local exp_array = resmng.prop_hero_skill_exp[cur_lv].TotalExp
            total_exp = total_exp + (exp_array[k] + skill_exp)  --k是技能槽位
        end
    end

    local ratio = 0.8
    local return_exp = math.floor(total_exp * ratio)
    for i = 1, 4 do
        local item_id = ITEM_CLASS.SKILL * 1000000 + ITEM_SKILL_MODE.COMMON_BOOK * 1000 + i
        local grade = resmng.prop_item[item_id].Param[2]
        local book_num = math.floor(return_exp / grade)
        if book_num > 0 then
            self:inc_item(item_id, book_num, reason)
            return_exp = return_exp - math.mod(return_exp, grade)
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 释放所有俘虏
-- Argument : self
-- Return   : NULL
-- Others   : 当关押俘虏的城市被任意玩家攻破后，城内所有俘虏（包括正在被处决中的）立刻逃脱，行军返回自己的城市。
--------------------------------------------------------------------------------
function release_all_prisoner(self)
    -- 监狱
    local prison = self:get_prison()
    if prison then
        if prison.extra and prison.extra.prisoners_info then
            for _, prisoner in pairs(prison.extra.prisoners_info) do
                self:release_prisoner(prisoner.hero_id)
            end
        end
    end

    -- 祭坛
    local altar = self:get_altar()
    if altar then
        if altar.extra and altar.extra.hero_id then
            -- 释放hero
            self:let_prison_back_home(altar.extra.hero_id)

            -- 清理祭坛
            altar.state   = BUILD_STATE.WAIT
            altar.tmSn    = 0
            altar.tmStart = gTime
            altar.tmOver  = 0

            local chg = {"hero_id", "kill_start_tm", "kill_over_tm"}
            altar:clear_extra(chg)
        end
    end

    -- notify client.
    self:get_prisoners_info()
end

