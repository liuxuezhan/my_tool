module_class("build_t", {
    _id = "0_0",
    idx = 0,
    pid = 0,
    x = 0, y = 0,
    propid = 0,
    action = 0,
    state = 0,
    tmSn = 0,
    tmStart = 0,
    tmOver = 0,
    extra = {},
    hero_idx = 0,
})

function create(idx, pid, propid, x, y, state, tmStart, tmOver)
    local _id = string.format("%d_%d", idx, pid)
    local t = {_id=_id, map=gMapID, idx=idx, pid=pid, propid=propid, x=x, y=y, state=state or 0, tmStart=tmStart or 0, tmOver=tmOver or 0}
    local db = dbmng:getOne()
    db.build:insert(t)
    return new(t)
end

function getData(self)
    return  rawget(self._pro)
end

function on_check_pending(db, _id, chgs)
    db.build:update({_id=_id}, {["$set"]=chgs})

    local idx, pid = string.match(_id, "(%d+)_(%d+)")
    local p = getPlayer(tonumber(pid))
    if p then
        chgs.idx = tonumber(idx)
        Rpc:stateBuild(p, chgs)
    end
end


--------------------------------------------------------------------------------
-- Function : 建筑加速
-- Argument : self, secs
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function acceleration(self, secs)
    if not secs or secs <= 0 then
        ERROR("acceleration: secs = %d.", secs or -1)
        return
    end

    if self.state == BUILD_STATE.WAIT then
        ERROR("acceleration: build._id = %s, build.state = BUILD_STATE.WAIT.", self._id)
        return
    else
        -- state tmSn tmStart tmOver
        local player = getPlayer(self.pid)
        if not player then
            ERROR("acceleration: getPlayer(%d) failed.", self.pid)
            return
        end

        LOG("acceleration: build._id = %s, build.tmOver = %s, secs = %d", self._id, timestamp_to_str(self.tmOver), secs)

        self.tmOver = self.tmOver - secs
        if self.tmOver <= gTime then
            self.tmOver = gTime
            local t = timer.get(self.tmSn)
            if t then
                timer.callback(self.tmSn, t.tag)
                -- player:doTimerBuild(self.tmSn, self.idx)
            else
                ERROR("acceleration: get timer failed. build._id = %s, build.tmSn = %d", self._id, self.tmSn)
            end
        else
            timer.acc(self.tmSn, secs)
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 计算加速所需的金币数量
-- Argument : self
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_gold_for_acc(self)
    if self.state == BUILD_STATE.WAIT then
        ERROR("calc_gold_for_acc: build._id = %s, build.state = BUILD_STATE.WAIT, can't acceleration.", self._id)
        return math.huge
    end

    -- TODO: 找策划要计算公式（剩余CD时间和金币的换算关系），这里暂时扣除10金币做测试用
    -- return self.tmOver - gTime
    return 10
end


--------------------------------------------------------------------------------
-- Function : 校验是否能够使用免费加速
-- Argument : self
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function can_acc_for_free(self)
    -- TODO: check conditions.
    -- 校验Vip等级对应的免费时长与剩余时长
    return true
end


--------------------------------------------------------------------------------
-- Function : cond check
-- Argument : self
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function cond_check(self, check_type, value_1, value_2, value_3)
    if check_type == "BSTATE" then
        return self:state_check(value_1)
    elseif check_type == "BTYPE" then
        return self:type_check(value_1, value_2, value_3)
    end
end


--------------------------------------------------------------------------------
-- Function : state check.
-- Argument : self, state
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function state_check(self, state)
    if self.state == state then
        return true
    else
        return false
    end
end


--------------------------------------------------------------------------------
-- Function : type check.
-- Argument : self, class, mode, lv
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function type_check(self, class, mode, lv)
    local conf = resmng.get_conf("prop_build", self.propid)
    if not conf then
        return false
    end

    if class and class ~= conf.Class then
        return false
    end
    if mode and mode ~= conf.Mode then
        return false
    end

    if lv and lv ~= conf.Lv then
        return false
    end

    return true
end


--------------------------------------------------------------------------------
-- Function : ef_hero 发生变化时调用, 结算之前的加速效果, 根据当前 ef_hero 重新计算加速
-- Argument : self, ef_hero_change
-- Return   : NULL
-- Others   : 只影响工作中的建筑，只针对 科技研究、资源、治疗、造兵
--------------------------------------------------------------------------------
function recalc_work(self, ef_hero_change)
    if not ef_hero_change then
        ERROR("recalc_work: no ef_hero_change.")
        return
    end

    -- 只影响工作中的建筑
    if self.status ~= BUILD_CLASS.WORK then
        LOG("recalc_work: pid = %d, build.idx = %d, build.status(%d) ~= BUILD_CLASS.WORK, ignore.", self.pid, self.idx, self.status)
        return
    end

    if gTime >= self.tmOver then
        LOG("recalc_work: pid = %d, build.idx = %d, gTime(%d) >= build.tmOver(%d).", self.pid, self.idx, gTime, self.tmOver)
        return
    end

    local player = getPlayer(self.pid)
    if not player then
        ERROR("recalc_work: get player failed. pid = %d", self.pid)
        return
    end

    local conf = resmng.prop_build[self.propid]
    if conf then
        if conf.Class == BUILD_CLASS.FUNCTION and conf.Mode == BUILD_FUNCTION_MODE.ACADEMY and ef_hero_change["TechSpeed"] then
            -- 研究院(科技研究): calc new dura
            local extra = self.extra
            if not extra then
                ERROR("recalc_work: lost extra. pid = %d, build.idx = %d", self.pid, self.idx)
                return
            end

            local percent_left = (self.tmOver - gTime) / (self.tmOver - self.tmStart)
            local dura = math.ceil(player:calc_real_dura("TechSpeed", extra.std_dura) * percent_left)

            -- new timer
            self.tmOver = gTime + dura
            self.tmSn = timer.new("learn_tech", dura, self.pid, self.idx, extra.tech_id)
        elseif conf.Class == BUILD_CLASS.FUNCTION and conf.Mode == BUILD_FUNCTION_MODE.HOSPITAL and ef_hero_change["CureSpeed"] then
            -- 医疗所(治疗): 遍历处理治疗中的英雄
            for _, hero in pairs(player:get_hero()) do
                if hero.state == HERO_STATUS_TYPE.BEING_CURED then
                    local t = timer.get(hero.tm_sn)
                    if t then
                        -- local node = {_id=id, tag=0, start=gTime, over=gTime+sec, what=what, param={...}}
                        local percent_left = (t.over - gTime) / (t.over - t.start)
                        local delta_hp = t.param[3]
                        local delta_hp_left = delta_hp * percent_left
                        local dura = math.ceil(player:calc_real_dura("CureSpeed", delta_hp_left))
                        hero.tm_sn = timer.new("cure_hero", dura, self.pid, hero.idx, delta_hp)
                    end
                end
            end

        elseif conf.Class == BUILD_CLASS.RESOURCE then
            -- TODO:
            -- 资源生产
            if conf.Mode == BUILD_RESOURCE_MODE.FARM and ef_hero_change["FoodSpeed"] then
                -- 农田
                -- TODO: player 身上的得到的是全局的，build 自己身上可能还有独立的加成(等待添加)
                local speed = player:get_val("FoodSpeed")
                local count = player:get_val("FoodCount")
                local make = math.floor((gTime - self.tmStart) * speed / 3600 )
                local made = (self.extra.made or 0) + make
                if made > count then made = count end
                local chg = {["made"] = made}
                self:update_extra(chg)
                self.tmStart = gTime
            elseif conf.Mode == BUILD_RESOURCE_MODE.LOGGINGCAMP and ef_hero_change["WoodSpeed"] then
                -- 伐木场
                local speed = player:get_val("WoodSpeed")
                local count = player:get_val("WoodCount")
                local make = math.floor((gTime - self.tmStart) * speed / 3600 )
                local made = (self.extra.made or 0) + make
                if made > count then made = count end
                local chg = {["made"] = made}
                self:update_extra(chg)
                self.tmStart = gTime
            -- TODO: 暂时没有以下两个
            -- elseif conf.Mode == BUILD_RESOURCE_MODE.MINE and ef_hero_change["IronSpeed"] then
                -- 铁矿
            -- elseif conf.Mode == BUILD_RESOURCE_MODE.QUARRY and ef_hero_change["EnergySpeed"] then
                -- 能源石
            end
        elseif conf.Class == BUILD_CLASS.ARMY and ef_hero_change["TrainSpeed"] then
            -- 造兵
            -- calc new dura
            local extra = self.extra
            if not extra then
                ERROR("recalc_work: lost extra. pid = %d, build.idx = %d", self.pid, self.idx)
                return
            end

            local percent_left = (self.tmOver - gTime) / (self.tmOver - self.tmStart)
            local dura = math.ceil(player:calc_real_dura("TrainSpeed", extra.std_dura) * percent_left)

            -- new timer
            self.tmOver = gTime + dura
            self.tmSn = timer.new("learn_tech", dura, self.pid, self.idx, extra.tech_id)
        end
    else
        ERROR("recalc_work: get prop_build config failed. pid = %d, build.idx = %d, build.propid = %d", self.pid, self.idx, self.propid)
    end
end


--------------------------------------------------------------------------------
-- Function : 初始化
-- Argument : NULL
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function init(self)
    local conf = resmng.get_conf("prop_build", self.propid)
    if not conf then
        ERROR("build_t.init: get conf failed. propid = %d.", self.propid)
        return
    end

    if not self.extra then
        self.extra = {}
    end

    -- 监狱
    if conf.Class == BUILD_CLASS.FUNCTION and conf.Mode == BUILD_FUNCTION_MODE.PRISON then
        if not self.extra.prisoners_info then
            self.extra.prisoners_info = {}
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 更新extra
-- Argument : self, chg = {k1 = v1, k2 = v2, ...}
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function update_extra(self, chg)
    if not chg then
        ERROR("update_extra: no chg.")
        return
    end

    local extra = self.extra or {}
    for k, v in pairs(chg) do
        extra[k] = v
    end
    self.extra = extra
end

--------------------------------------------------------------------------------
-- Function : 清理extra
-- Argument : self, chg = {key1, key2, ...}
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function clear_extra(self, chg)
    if not chg then
        ERROR("clear_extra: no chg.")
        return
    end

    local extra = self.extra or {}
    for _, v in pairs(chg) do
        extra[v] = nil
    end

    self.extra = extra
end

function get_extra_val(self, what)
    return self.extra and self.extra[ what ]
end


