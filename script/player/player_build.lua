--------------------------------------------------------------------------------
-- Desc     : player build
-- Author   : Yang Cong
-- History  :
--     2016-1-26 11:52:14 Created
-- Copyright: Chengdu Tapenjoy Tech Co.,Ltd
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
module("player_t")


--------------------------------------------------------------------------------
-- load
function do_load_build(self)
    local db = self:getDb()
    local info = db.build:find({pid=self.pid})
    local bs = {}
    while info:hasNext() do
        local b = info:next()
        bs[ b.idx ] = build_t.new(b)
    end
    for _, v in pairs(bs) do
        local node = resmng.prop_build[ v.propid ]
        if node and node.Effect then
            self:addEffect(node.Effect or {}, true)
        end
        v.name = node.Name
    end
    return bs
end


--------------------------------------------------------------------------------
-- Function : 计算建筑在 ply._build 中的 idx
-- Argument : self, build_class, build_mode, build_seq 玩家拥有的第几个该类型建筑
-- Return   : succ - build_idx; fail - nil
-- Others   : 传入 build_seq 时表示根据 build_class, build_mode, build_seq 计算 build_idx;
--            不传入 build_seq 时表示根据 build_class, build_mode 获取一个可用的 build_idx
--------------------------------------------------------------------------------
function calc_build_idx(self, build_class, build_mode, build_seq)
    local max_seq = BUILD_MAX_NUM[build_class] and BUILD_MAX_NUM[build_class][build_mode]
    if not max_seq then
        ERROR("calc_build_idx: get max_seq failed. pid = %d, build_class = %d, build_mode = %d.", self.pid, build_class or -1, build_mode or -1)
        return
    end

    if not build_seq then
        for seq = 1, max_seq do
            local build_idx = self:calc_build_idx(build_class, build_mode, seq)
            local build = self:get_build(build_idx)
            if not build then
                return build_idx
            end
        end
    else
        if build_seq < 0 or build_seq > max_seq then
            ERROR("calc_build_idx: build_seq = %d, max_seq = %d.", build_seq, max_seq)
            return
        end

        return build_class * 100 * 100 + build_mode * 100 + build_seq
    end
end


-- get
function get_build(self, idx)
    if not self._build then self._build = self:do_load_build() end
    if idx then
        if self._build then return self._build[ idx ] end
    else
        return self._build
    end
end


--------------------------------------------------------------------------------
-- Function : 根据 class, mode, seq 获取建筑
-- Argument : self, build_class, build_mode, build_seq
-- Return   : succ - build; fail - nil
-- Others   : build_seq 默认值为 1
--------------------------------------------------------------------------------
function get_build_extra(self, build_class, build_mode, build_seq)
    local max_seq = BUILD_MAX_NUM[build_class] and BUILD_MAX_NUM[build_class][build_mode]
    if not max_seq then
        ERROR("get_build_extra: get max_seq failed. pid = %d, build_class = %d, build_mode = %d.", self.pid, build_class or -1, build_mode or -1)
        return
    end

    local build_idx = self:calc_build_idx(build_class, build_mode, build_seq or 1)
    if not build_idx then
        return
    end

    local build = self:get_build(build_idx)
    if not build then
        ERROR("get_build_extra: get_build() failed. pid = %d, build_idx = %d.", self.pid, build_idx)
        return
    else
        return build
    end
end


--------------------------------------------------------------------------------
-- Function : 根据 class 和 mode 获取玩家身上所有满足条件的建筑
-- Argument : self, build_class, build_mode
-- Return   : succ - {1=build_1, ...}; fail - {}
-- Others   : NULL
--------------------------------------------------------------------------------
function get_builds_extra(self, build_class, build_mode)
    local max_seq = BUILD_MAX_NUM[build_class] and BUILD_MAX_NUM[build_class][build_mode]
    if not max_seq then
        ERROR("get_builds_extra: get max_seq failed. pid = %d, build_class = %d, build_mode = %d.", self.pid, build_class or -1, build_mode or -1)
        return {}
    end

    local ret = {}
    for seq = 1, max_seq do
        local build_idx = self:calc_build_idx(build_class, build_mode, seq)
        local build = self:get_build(build_idx)
        if not build then
            -- 已取到所有此类建筑
            break
        else
            table.insert(ret, build)
        end
    end

    return ret
end


function get_castle_lv(self)
    local bs = self:get_build()
    for k, v in pairs(bs) do
        local propid = v.propid
        local n = resmng.prop_build[ propid ]
        if n and n.Class == 0 and n.Mode == 0 then
            return n.Lv
        end
    end
end


-- set
function set_build(self, idx, b)
    local bs = self:get_build()
    bs[ idx ] = b
end


-- 建造
function construct(self, x, y, build_propid)
    if not x or not y or not build_propid then
        ERROR("construct: arguments error. x = %d, y = %d, build_propid = %d", x or -1, y or -1, build_propid or -1)
        ack(self, "construct", resmng.E_FAIL)
    end

    --if self:get_build_queue() >= self:getPropValue("BuildQueue") then return end
    local node = resmng.prop_build[ build_propid ]
    if node and node.Lv == 1 then
        if self:condCheck(node.Cond) and self:consCheck(node.Cons) then
            local id = string.format("_%d", self.pid)
            local idx = self:calc_build_idx(node.Class, node.Mode)
            if idx then
                self:consume(node.Cons, 1, VALUE_CHANGE_REASON.BUILD_CONSTRUCT)

                local t = build_t.create(idx, self.pid, node.ID, x, y, BUILD_STATE.CREATE, gTime, gTime+node.Dura)
                t.tmSn = timer.new("build", node.Dura, self.pid, idx)
                self:set_build(idx, t)
                Rpc:stateBuild(self, t._pro)

                LOG("construct: pid = %d, build.propid = %d, build.x = %d, build.y = %d", self.pid, build_propid, x, y)
                return
            else
                ERROR("construct: get build_idx failed, pid = %d, node.Class = %d, node.Mode = %d.", self.pid, node.Class, node.Mode)
            end
        end
    end
    ack(self, "construct", resmng.E_FAIL)
end


-- 定时器升级
function upgrade(self, idx)
    --if self:get_build_queue() >= self:getPropValue("BuildQueue") then return end
    local build = self:get_build(idx)
    if build then
        local node = resmng.prop_build[ build.propid ]
        if node then
            local id = node.ID + 1
            local dst = resmng.prop_build[ id ]
            if dst then
                if self:condCheck(dst.Cond) and self:consCheck(dst.Cons) then
                    self:consume(dst.Cons, 1, VALUE_CHANGE_REASON.BUILD_UPGRADE)
                    build.state = BUILD_STATE.UPGRADE
                    build.tmStart = gTime
                    build.tmOver = gTime + dst.Dura
                    build.tmSn = timer.new("build", dst.Dura, self.pid, idx)

                    LOG("upgrade: pid = %d, build.propid = %d, build.idx = %d", self.pid, build.propid, idx)
                    return
                end
            end
        end
    end
    ack(self, "upgrade", resmng.E_FAIL)
end


--------------------------------------------------------------------------------
-- Function : 这里才是真的升级
-- Argument : self, build_idx
-- Return   : succ - true; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function do_upgrade(self, build_idx)
    local build = self:get_build(build_idx)
    if not build then
        ERROR("do_upgrade: get_build() failed, pid = %d, build_idx = %d", self.pid, build_idx)
        return false
    end

    local node = resmng.get_conf("prop_build", build.propid)
    if node then
        local id = node.ID + 1
        local dst = resmng.get_conf("prop_build", id)
        if dst then
            self:ef_chg(node.Effect or {}, dst.Effect or {})
            build.propid = dst.ID
            if dst.Class == 0 and dst.Mode == 7 then -- 更新物资市场免费购买次数
                self.res_num = resmng.prop_resm[id].Num
            end

            return true
        end
    end

    ERROR("do_upgrade: upgrade failed. pid = %d, build_idx = %d", self.pid, build_idx)
    return false
end


--------------------------------------------------------------------------------
-- Function : 一键升级
-- Argument : self, build_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function one_key_upgrade_build(self, build_idx)
    local build = self:get_build(build_idx)
    if not build then
        ERROR("one_key_upgrade_build: get_build() failed, pid = %d, build_idx = %d.", self.pid, build_idx or -1)
        return
    end

    if build.state ~= BUILD_STATE.WAIT then
        ERROR("one_key_upgrade_build: build._id = %s, build.state(%d) ~= BUILD_STATE.WAIT", build._id, build.state)
        return
    end

    local node = resmng.get_conf("prop_build", build.propid)
    if node then
        local dst = resmng.get_conf("prop_build", node.ID + 1)
        if not dst then
            ERROR("one_key_upgrade_build: get next node failed. build._id = %s, build lv = %d", build._id, node.Lv)
            return
        else
            if not self:condCheck(dst.Cond) then
                ERROR("one_key_upgrade_build: check cond failed. build._id = %s", build._id)
                return
            else
                -- 优先使用已有资源，不足的扣除相应金币
                -- 校验所需资源，拆分为 cons_have 和 cons_need_buy
                local cons_have, cons_need_buy = self:split_cons(dst.Cons)
                if not cons_have then
                    ERROR("one_key_upgrade_build: split_cons() failed.")
                    dumpTab(dst.Cons, string.format("prop_build[%d]", node.ID + 1))
                    return
                end

                local gold_need = calc_cons_value(cons_need_buy) + self:calc_cd_golds(dst.Dura)
                if gold_need > 0 and gold_need > self.gold then
                    ERROR("one_key_upgrade_build: pid = %d, player.gold(%d) < gold_need(%d)", self.pid, self.gold, gold_need)
                    return
                else
                    -- 扣除 cons_have 和 gold_need
                    self:dec_cons(cons_have, VALUE_CHANGE_REASON.BUILD_UPGRADE, true)
                    if gold_need > 0 then
                        self:doUpdateRes(resmng.DEF_RES_GOLD, -gold_need, VALUE_CHANGE_REASON.BUILD_UPGRADE)
                    end

                    -- 升级
                    self:do_upgrade(build_idx)
                end
            end
        end
    end
end


-- timer function
function doTimerBuild(self, tsn, build_idx, arg_1, arg_2, arg_3)
    local build = self:get_build(build_idx)
    if build then
        if build.tmSn ~= tsn then return end
        local state = build.state
        build.state = BUILD_STATE.WAIT
        build.tmSn = 0
        build.tmStart = gTime
        build.tmOver = 0

        if state == BUILD_STATE.CREATE then
            local node = resmng.prop_build[ build.propid ]
            if node then
                if node.Effect then self:addEffect(node.Effect) end
            end
        elseif state == BUILD_STATE.UPGRADE then
            self:do_upgrade(build_idx)

        elseif state == BUILD_STATE.WORK then
            local conf = resmng.get_conf("prop_build", build.propid)
            if not conf then
                ERROR("doTimerBuild: get prop_build config failed. pid = %d, build_idx = %d, build.propid = %d", self.pid, build_idx, build.propid)
                return
            end

            -- 根据建筑类型，分别调用对应的接口
            if conf.Class == BUILD_CLASS.FUNCTION then
                if conf.Mode == BUILD_FUNCTION_MODE.ACADEMY then
                    -- 研究院
                    self:do_learn_tech(build, arg_1)
                elseif conf.Mode == BUILD_FUNCTION_MODE.HOSPITAL then
                    -- 医疗所(治疗)
                    -- "CureSpeed"

                elseif conf.Mode == BUILD_FUNCTION_MODE.ALTAR then
                    -- 祭坛
                    self:real_kill_hero(arg_1, arg_2, arg_3)

                elseif conf.Mode == BUILD_FUNCTION_MODE.FORGE then
                    local tid = build:get_extra_val("forge")
                    if tid then self:equip_add(tid, VALUE_CHANGE_REASON.FORGE) end
                    build:clear_extra({"forge"})

                end

            elseif conf.Class == BUILD_CLASS.RESOURCE then
                -- 资源生产
                if conf.Mode == BUILD_RESOURCE_MODE.FARM then
                    -- 农田
                    -- "FoodSpeed"
                elseif conf.Mode == BUILD_RESOURCE_MODE.LOGGINGCAMP then
                    -- 伐木场
                    -- "WoodSpeed"
                elseif conf.Mode == BUILD_RESOURCE_MODE.MINE then
                    -- 铁矿
                    -- "IronSpeed"
                elseif conf.Mode == BUILD_RESOURCE_MODE.QUARRY then
                    -- 能源石
                    -- "EnergySpeed"
                end
            elseif conf.Class == BUILD_CLASS.ARMY then
                -- 造兵
                -- 'TrainSpeed'
                if conf.Mode == BUILD_ARMY_MODE.BARRACKS then
                    -- 兵营
                elseif conf.Mode == BUILD_ARMY_MODE.STABLES then
                    -- 马厩
                elseif conf.Mode == BUILD_ARMY_MODE.RANGE then
                    -- 靶场
                elseif conf.Mode == BUILD_ARMY_MODE.FACTORY then
                    -- 工坊
                end
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Function : build_acceleration
-- Argument : self, build_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function build_acceleration(self, build_idx, secs)
    local build = self:get_build(build_idx)
    if build and build.tmSn > 0 and build.tmOver > gTime then
        build:acceleration(secs)
    end
end


--------------------------------------------------------------------------------
-- Function : 使用金币或者免费时间加速建筑
-- Argument : self, build_idx, acc_type
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function acc_build(self, build_idx, acc_type)
    local build = self:get_build(build_idx)
    if not build then
        ERROR("acc_build: pid = %d, build_idx = %d", self.pid, build_idx or -1)
        return
    end

    if build.state == BUILD_STATE.WAIT then
        ERROR("acc_build: pid = %d, build_idx = %d, build.state = BUILD_STATE.WAIT", self.pid, build_idx)
        return
    end

    if acc_type == ACC_TYPE.FREE then
        if build:can_acc_for_free() then
            build:acceleration(build.tmOver - gTime)
        end
    elseif acc_type == ACC_TYPE.GOLD then
        local num = build:calc_gold_for_acc()
        if self:doUpdateRes(resmng.DEF_RES_GOLD, -num, VALUE_CHANGE_REASON.BUILD_ACC) then
            build:acceleration(build.tmOver - gTime)
        end
    else
        ERROR("acc_build: pid = %d, build_idx = %d, acc_type = %d", self.pid, build_idx, acc_type or -1)
        return
    end
end


--------------------------------------------------------------------------------
-- Function : Use speed item.
-- Argument : self, build_idx, item_idx, num
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function item_acc_build(self, build_idx, item_idx, num)
    -- check arguments.
    if not build_idx or not item_idx or not num or num <= 0 then
        ERROR("item_acc_build: pid = %d, build_idx = %d, item_idx = %d, num = %d", self.pid or -1, build_idx or -1, item_idx or -1, num or -1)
        return
    end

    -- check item.
    local item = self:get_item(item_idx)
    if not item then
        ERROR("item_acc_build: get_item() failed. pid = %d, item_idx = %d", self.pid or -1, item_idx)
        return
    end

    local conf = resmng.get_conf("prop_item" ,item[2])
    if not conf or conf.Class ~= ITEM_CLASS.SPEED then
        ERROR("item_acc_build: not speed item. pid = %d, item_idx = %d, item_id = %d, item_class = %d",
               self.pid or -1, item_idx, item[2], conf and conf.Class or -1)
        return
    end

    -- check build state.
    local build = self:get_build(build_idx)
    if not build then
        ERROR("item_acc_build: get_build() failed. pid = %d, build_idx = %d", self.pid, build_idx)
        return
    end
    if build.state == BUILD_STATE.WAIT then
        ERROR("item_acc_build: pid = %d, build_idx = %d, build.state = BUILD_STATE.WAIT", self.pid, build_idx)
        return
    end

    if not self:build_cond_check(build, conf.Cond) then
        ERROR("item_acc_build: build_cond_check not pass. pid = %d, build_idx = %d, build.state= %d, item_idx= %d, item_id= %d",
               self.pid, build_idx, build.state, item_idx, item[2])
        dumpTab(conf.Cond, "conf.Cond")
        return
    end

    -- speed up.
    if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.BUILD_ACC) then
        build:acceleration(conf.Param[1] * num)
    end
end


--------------------------------------------------------------------------------
-- Function : check cond.
-- Argument : self, build, tab
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function build_cond_check(self, build, tab)
    if not build then
        ERROR("build_cond_check: no build.")
        return false
    end

    if tab then
        if not do_build_cond_check(build, unpack(tab)) then
            return false
        end
    end

    return true
end

-- do cond check
function do_build_cond_check(build, value_1, value_2, value_3, ...)
    if value_1 == "AND" then
        for _, v in pairs({value_2, value_3, ...}) do
            if not build:cond_check(unpack(v)) then return false end
        end
        return true
    elseif value_1 == "OR" then
        for _, v in pairs({value_2, value_3, ...}) do
            if build:cond_check(unpack(v)) then return true end
        end
        return false
    end

    return false
end

-- 收获
function reap(self, idx)
    local n = self:get_build(idx)
    if n then
        if n.state ~= BUILD_STATE.WAIT then return end

        local prop = resmng.prop_build[ n.propid ]
        if not prop then return end
        if prop.Class ~= BUILD_CLASS.RESOURCE then return end

        -- TODO: 建筑的 Speed、Count 分为 golbal(玩家身上) 和 local(建筑自己身上)
        -- 这里的 speed 和 count 需要重新计算
        local speed = prop.Speed  -- 每小时的资源产量
        local count = prop.Count  -- 建筑资源容量上限

        if prop.Mode == resmng.DEF_RES_FOOD then
            speed = speed * self:getPropRate("FoodSpeed")
            count = count * self:getPropRate("FoodCount")
        elseif prop.Mode == resmng.DEF_RES_WOOD then
            speed = speed * self:getPropRate("WoodSpeed")
            count = count * self:getPropRate("WoodCount")
        end

        if speed and count then
            local make = math.floor( (gTime - n.tmStart) * speed / 3600 )
            make = make + (n.extra.made or 0)
            n:clear_extra({"made"})
            if make < 1 then return end
            if make > count then make = count end
            self:doUpdateRes(prop.Mode, make, VALUE_CHANGE_REASON.REAP)
            n.tmStart = gTime
        end
    end
end


function equip_forge(self, id)
    local b = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.FORGE)
    if not b or b.state ~= BUILD_STATE.WAIT then return LOG("forge, pid=%d, state=%d", self.pid, b and b.state or -1) end

    local n = resmng.get_conf("prop_equip", id)
    if not n then return end

    if not self:condCheck(n.Cons) then return LOG("forge, pid=%d, state=%d", self.pid, b and b.state or -1) end
    self:consume(n.Cons, 1, VALUE_CHANGE_REASON.FORGE)

    b.state = BUILD_STATE.WORK
    b.tmStart = gTime
    b.tmOver  = gTime + n.Dura
    b.tmSn    = timer.new("build", n.Dura, self.pid, b.idx)
    b:update_extra({forge=id})
end

function equip_split(self, id)
    print("equip_split", id)
    local n = self:get_equip(id)
    if not n then return LOG("equip_split, no equip") end
    if n.pos ~= 0 then return end -- equip_on

    local prop = resmng.get_conf("prop_equip", n.propid)
    if not prop then return LOG("equip_split, no prop") end

    if not prop.Split then return LOG("equip_split, no prop.Split") end

    local total = 0
    for _, v in pairs(prop.Split) do
        total = total + v[2]
    end

    if total < 1 then return LOG("equip_split, no total") end
    local rate = math.random(1, total)

    local cur = 0
    local rare = false
    for _, v in pairs(prop.Split) do
        cur = cur + v[2]
        if rate <= cur then
            rare = v[1]
            break
        end
    end

    if not rare then return LOG("equip_split, no rare") end

    local group = get_material_group_by_rare(rare)
    if group and #group > 0 then
        local its = {}
        for i = 1, prop.SplitNum do
            local idx = math.random(1, #group)
            local tid = group[ idx ]
            its[ tid ] = (its[ tid ] or 0) + 1
        end

        for k, v in pairs(its) do
            self:inc_item(k, v, VALUE_CHANGE_REASON.SPLIT)
        end

        self:equip_rem(id, VALUE_CHANGE_REASON.SPLIT)
        return
    end

    if not rare then return LOG("equip_split, no group") end
end


-- 训练
function train(self, idx, armid, num)
    -- check params
    local build = self:get_build(idx)
    if not build then return end

    if build.state ~= BUILD_STATE.WAIT then return end
    local bnode = resmng.prop_build[ build.propid ]
    if not bnode then return end
    if bnode.Class ~= 2 then return self:addTips("class~=2") end

    local anode = resmng.prop_arm[ armid ]
    if not anode then return self:addTips("no armid") end
    if anode.Mode ~= bnode.Mode then return self:addTips("mode") end

    if anode.Lv > bnode.TrainLv then return self:addTips("lv") end

    local maxTrain = self:get_val("TrainCount")
    if num > maxTrain then return self:addTips("maxTrain") end

    -- check resources
    if not self:condCheck(anode.Cond) then return false end
    if not self:consCheck(anode.Cons, num) then return false end
    self:consume(anode.Cons, num, VALUE_CHANGE_REASON.TRAIN)

    local std_dura = num * anode.TrainTime
    local dura = self:calc_real_dura("TrainSpeed", std_dura)

    build.state = BUILD_STATE.WORK
    build.tmStart = gTime
    build.tmOver = gTime + dura

    local chg = {train_id = armid, train_num = num, std_dura = std_dura}
    build:update_extra(chg)
end

-- 征募
function draft(self, idx)
    local build = self:get_build(idx)
    if not build then return end
    if build.state ~= BUILD_STATE.WORK then return INFO("draft, not state %s", build.state) end
    if build.tmOver > gTime then return INFO("draft, not time %d", build.tmOver - gTime) end
    build.state = BUILD_STATE.WAIT
    --Rpc:stateBuild(self, build._pro)

    local extra = build.extra
    if extra and extra.train_id > 0 and extra.train_num > 0 then
        self:incArm(extra.train_id, extra.train_num)

        local chg = {"train_id", "train_num", "std_dura"}
        build:clear_extra(chg)

        self:reCalcFood()
    end
end


-- 研究科技
function learn_tech(self, build_idx, tech_id)
    local build = self:get_build(build_idx)
    if not build or build.state ~= BUILD_STATE.WAIT then
        ERROR("learn_tech: pid = %d, build_idx = %d, build.state(%d) ~= BUILD_STATE.WAIT", self.pid, build_idx or -1, build and build.state or -1)
        return
    end

    local build_conf = resmng.get_conf("prop_build", build.propid)
    if not build_conf then
        return
    else
        if build_conf.Class ~= BUILD_CLASS.FUNCTION or build_conf.Mode ~= BUILD_FUNCTION_MODE.ACADEMY then
            ERROR("learn_tech: not academy. pid = %d, build_idx = %d, build.propid = %d, build_conf.Class = %d, build_conf.Mode = %d",
                   self.pid, build_idx, build.propid, build_conf.Class, build_conf.Mode)
            return
        end
    end

    local tech_conf = resmng.get_conf("prop_tech", tech_id)
    if not tech_conf then
        ERROR("learn_tech: get prop tech config failed. pid = %d, tech_id = %d", self.pid, tech_id or -1)
        return
    end

    -- check repeat.
    for k, v in pairs(self.tech) do
        local t = resmng.get_conf("prop_tech", v)
        if not t then
            ERROR("learn_tech: get prop_tech config failed. pid = %d, v = %d", self.pid, v)
            return
        end

        if t.Class == tech_conf.Class and t.Mode == tech_conf.Mode and t.Lv >= tech_conf.Lv then
            ERROR("learn_tech: pid = %d, tech_id = %d, already have tech %d.", self.pid, tech_id, v)
            return
        end
    end

    -- check & consume
    if not self:condCheck(tech_conf.Cond) then
        ERROR("learn_tech: check cond failed. pid = %d", self.pid)
        return
    end
    if not self:consCheck(tech_conf.Cons) then
        ERROR("learn_tech: check cons failed. pid = %d", self.pid)
        return
    end
    self:consume(tech_conf.Cons, 1, VALUE_CHANGE_REASON.LEARN_TECH)

    -- new timer
    local dura = self:calc_real_dura("TechSpeed", tech_conf.Dura)
    build.state = BUILD_STATE.WORK
    build.tmStart = gTime
    build.tmOver = gTime + dura
    build.tmSn = timer.new("learn_tech", dura, self.pid, build_idx, tech_id)

    local chg = {tech_id = tech_id, std_dura = tech_conf.Dura}
    build:update_extra(chg)
end


--------------------------------------------------------------------------------
-- Function : 升级科技
-- Argument : self, tech_id
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function do_learn_tech(self, academy, tech_id)
    local conf = resmng.get_conf("prop_tech", tech_id)
    if not conf then
        ERROR("do_learn_tech: get prop_tech config failed. pid = %d, tech_id = %d.", self.pid, tech_id or -1)
        return
    end

    local tech = self.tech
    -- remove old tech
    if conf.Lv > 1 then
        local old_tech_id = tech_id - 1
        local old_conf = resmng.get_conf("prop_tech", old_tech_id)
        if not old_conf then
            ERROR("do_learn_tech: get old prop_tech config failed. pid = %d, old_tech_id = %d", self.pid, old_tech_id)
            return
        else
            local idx = is_in_table(self.tech, old_tech_id)
            if idx then
                table.remove(tech, idx)
                self:remEffect(old_conf.Effect)
            end
        end
    end

    -- add new tech
    table.insert(tech, tech_id)
    self:addEffect(conf.Effect)
    self.tech = tech

    -- clear
    local chg = {"tech_id", "std_dura"}
    academy:clear_extra(chg)
end


--------------------------------------------------------------------------------
-- Function : 拆除建筑
-- Argument : self
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function demolish(self, build_idx)
    local build = self:get_build(build_idx)
    if not build then
        ERROR("demolish: get_build() failed. pid = %d, build_idx = %d.", self.pid, build_idx or -1)
        return
    end

    -- TODO: Class、Mode、state 校验
    -- TODO: 解除玩家身上的引用

    -- 解除英雄派遣
    self:dispatch_hero(build_idx, 0)

    -- TODO: 存库
    -- TODO: 通知前端结果
end


--------------------------------------------------------------------------------
-- Function : 计算不同建筑行为受buff影响后的真实耗时
-- Argument : self, effect_type, arg
-- Return   : succ - number; fail - false
-- Others   : 这里的行为仅包括 科技研究、治疗、造兵
--------------------------------------------------------------------------------
function calc_real_dura(self, effect_type, arg)
    if not effect_type or not arg then
        ERROR("calc_real_dura: effect_type= %s, arg = %d.", effect_type or "", arg)
        return false
    end

    -- TODO: 策划还没有提供计算公式，以下为临时测试使用
    if effect_type == "TechSpeed" then
        local speed = self:get_val(effect_type)
        return math.ceil(arg / speed)
    elseif effect_type == "CureSpeed" then
        -- TODO: 这里默认1秒治疗1点血
        local speed = self:get_val(effect_type)
        return math.ceil(arg / speed)
    -- elseif effect_type =="FoodSpeed" then
    -- elseif effect_type =="WoodSpeed" then
    -- elseif effect_type =="IronSpeed" then
    -- elseif effect_type =="EnergySpeed" then
    elseif effect_type =="TrainSpeed" then
        local speed = self:get_val(effect_type)
        return math.ceil(arg / speed)
    else
        ERROR("calc_real_dura: pid = %d, wrong effect_type(%s).", self.pid, effect_type)
        return false
    end
end


--------------------------------------------------------------------------------
-- Function : 更新 ef_hero 时调用, 对 Work 状态中的建筑, 若 effect 发生变化, 则根据旧值进行结算, 根据当前值重新计算加速
-- Argument : self, old_ef_hero
-- Return   : NULL
-- Others   : 涉及 科技升级速度, 医疗恢复速度,  资源生产速度, 造兵速度
--------------------------------------------------------------------------------
function recalc_build_work(self, old_ef_hero)
    old_ef_hero = old_ef_hero or {}
    local ef_hero_change = self:calc_ef_hero_change(old_ef_hero)
    if next(ef_hero_change) then
        for build_idx, build in pairs(self:get_build()) do
            build:recalc_work(ef_hero_change)
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 查询主城等级
-- Argument : self
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function get_castle_lv(self)
    -- WARNING: 主城默认是第一个建筑
    local castle = self:get_build(1)
    local conf = resmng.getconf("prop_build", castle.propid)
    if not conf then
        ERROR("get_castle_lv: no way!!!")
        return
    else
        return conf.Lv
    end
end


--------------------------------------------------------------------------------
-- Function : 取得监狱建筑
-- Argument : self
-- Return   : succ - prison; fail - nil
-- Others   : NULL
--------------------------------------------------------------------------------
function get_prison(self)
    local prison = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.PRISON)
    if not prison then
        ERROR("get_prison: failed. pid = %d.", self.pid)
        return
    end

    return prison
end


--------------------------------------------------------------------------------
-- Function : 取得祭坛建筑
-- Argument : self
-- Return   : succ - prison; fail - nil
-- Others   : NULL
--------------------------------------------------------------------------------
function get_altar(self)
    local altar = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ALTAR)
    if not altar then
        ERROR("get_altar: get altar failed. pid = %d.", self.pid)
        return
    end

    if not altar.extra then
        altar.extra = {}
    end

    return altar
end

