module("player_t")

function init()
    _example.lv = 1
    _example.exp = 0
    _example.vip_lv = 0
    _example.vip_exp = 0
    _example.photo = 1
    _example.name = "unknown"
    _example.photo_url = ""
    _example.x = 0
    _example.y = 0
    _example.eid = 0
    _example.pid = 0
    _example.uid = 0
    _example.rmb = 0
    _example.gold = 999999999

    _example.wood = 10000
    _example.food = 10000
    _example.iron = 10000
    _example.energy = 0


    _example.res={{1,1},{2,3}, }

    _example.foodUse = 0
    _example.foodTm = gTime
    _example.talent = 20
    _example.arms = {}
    _example.genius = {}
    _example.tech = {}
    _example.sinew = 0

    _example.mail_sys = 0
    _example.mail_max = 0

    _example.cival = 0  --civalization

    --物资市场模块
    _example.buy_num = 0--已购买物资总次数
    _example.buy_time = 0--每日刷新记录时间
    _example.res_num  = 0--剩余购买物资次数
    _example.resm_type1  = 0--第一件暴击商品类型
    _example.resm_type2  = 0--第二件暴击商品类型
    _example.resm_type1_mu  = 0--第一件暴击商品倍数
    _example.resm_type2_mu  = 0--第二件暴击商品倍数


    _example.active = 0  --每日任务活跃度

    _example.def_heros = {}  -- 守城英雄
end

function make_pid(eid)
    return gMapID * 65536 + eid
end

function create(account, pid)
    local x, y = c_get_pos_by_lv(1,4,4)
    if not x then return INFO("!!!! NO ROOM FOR NEW PLAYER") end

    local eid = get_eid_ply()
    if not eid then return end

    --local pid = make_pid(eid)
    pid = pid or getId("pid")

    local p = copyTab(player_t._example)
    p._id = pid
    p.pid = pid
    p.eid = eid
    p.map = gMapID
    p.x = x
    p.y = y
    p.name = string.format("K%d_%d", gMapID, p.pid)
    p.account = account

    local ply = player_t.new(p)
    ply.eid = eid
    ply.propid = resmng.PLY_CITY_ROME_1

    local db = dbmng:getOne(pid)
    db.player:insert(p)

    local default_build = {
        resmng.BUILD_CASTLE_1,
        resmng.BUILD_ALTAR_1,
        resmng.BUILD_WALLS_1,
        resmng.BUILD_RANGE_1,
        resmng.BUILD_BLACKMARKET_1,
        resmng.BUILD_FORGE_1,
        resmng.BUILD_FACTORY_1,
        resmng.BUILD_EMBASSY_1,
        resmng.BUILD_RESOURCESMARKET_1,
        resmng.BUILD_HALLOFHERO_1,
        resmng.BUILD_HALLOFWAR_1,
        resmng.BUILD_PRISON_1,
        resmng.BUILD_STABLES_1,
        resmng.BUILD_MARKET_1,
        resmng.BUILD_DAILYQUEST_1,
        resmng.BUILD_ACADEMY_1,
        resmng.BUILD_BARRACKS_1,
        resmng.BUILD_STOREHOUSE_1,
        resmng.BUILD_DRILLGROUNDS_1,
        resmng.BUILD_TUTTER_LEFT_1,
        resmng.BUILD_TUTTER_RIGHT_1,
        resmng.BUILD_WATCHTOWER_1,
        resmng.BUILD_MILITARYTENT_1,
        resmng.BUILD_FARM_1,
        resmng.BUILD_LOGGINGCAMP_1,
        resmng.BUILD_MINE_1,
        resmng.BUILD_QUARRY_1,
    }

    local bs = {}
    for _, build_propid in ipairs(default_build) do
        local conf = resmng.get_conf("prop_build", build_propid)
        local build_idx = ply:calc_build_idx(conf.Class, conf.Mode, 1)
        print(build_propid, build_idx)
        bs[ build_idx ] = build_t.create(build_idx, pid, build_propid, 0, 0, BUILD_STATE.WAIT)
    end
    ply._build = bs
    ply:initEffect()

    ply._item = {}
    db.item:insert({_id=pid})

    ply._hero = {}
    ply._email = {}
    ply.size = 4

    -- Hx@2015-12-24 : lazy init union when login, not here
    --ply._union = union_member_t.create(pid, 0, 0)

    gEtys[ eid ] = ply
    etypipe.add(ply)
    --接任务
    ply:init_task()
    ply:take_daily_task(true)
    ply:take_life_task()

    return ply
end

function create_character(self, info)
    dumpTab(info, "create_character")

    local account = info.account
    local process = info.process
    local name = info.name

    local gate = self.gid

    if not process or not account then
        WARN("create_character, name=%s, not enough param", name)
        return
    end

    local p = gAccs[ account ]
    if not p then
        p = player_t.create(account)
        p.name = name
        if p then
            LOG("firstPacket, account=%s, pid=%d, process=%s, create new player in local ", account, p.pid, process)
            local dg = dbmng:getGlobal()
            dg.ply:insert({_id=account, pid=p._id, map=p.map, create=gTime, state=0})
            set_ply_map(gate, process, p.map, p.pid)
        else
            --sendCertify()
        end
    end
end

--function firstPacket(self, uid, account, pasw)
--    if self.pid ~= 0 then return LOG("duplicate firstPacket, uid=%d, account=%s, process=%s", uid, account, process) end
--    local process = pullString()
--
--    local old = self.gid
--
--    local dg = dbmng:getGlobal()
--    local info = dg.ply:find({_id=account})
--    local plys = {}
--    local pids = {}
--    while info:hasNext() do
--        local p = info:next()
--        table.insert(plys, p)
--        table.insert(pids, { p.pid, p.map} )
--    end
--    local cur = self.gid
--    self.gid = old
--    Rpc:ply_list(self, process, account, pids, plys)
--    self.gid = cur
--end

function set_ply_map(gate, proc, map, pid)
    pushHead(gate, 0, 9)  -- set server id
    pushInt(pid)
    pushInt(map)
    pushString(proc)
    pushOver()
end

function change_server(gate, proc, map)
    pushHead(gate, 0, 13) -- change server id
    pushInt(map) -- server id
    pushString(proc)
    pushOver()
end

----[[
function firstPacket(self, uid, account, pasw)
    local process = pullString()
    if self.pid ~= 0 then return LOG("duplicate firstPacket, uid=%d, account=%s, process=%s", uid, account, process) end

    local magic = pullInt()
    LOG("firstPacket, account=%s, pid=%d, process=%s, magic=%d", account, self.pid, process, magic)
    if magic ~= 20100731 then return end
    local gateid = self.gid

    local p = gAccs[ account ]
    if not p then
        LOG("firstPacket, account=%s, pid=%d, process=%s, account not in local", account, self.pid, process)
        local dg = dbmng:getGlobal()
        local info = dg.ply:findOne({_id=account})

        -- steer to map server the player belong to
        if info then
            if info.map == gMapID then
                LOG("firstPacket, account=%s, pid=%d, process=%s, account in map %d, missing, recreate", account, info.pid, process, info.map)
                p = player_t.create(account, info.pid)
            else
                LOG("firstPacket, account=%s, pid=%d, process=%s, account in map %d", account, info.pid, process, info.map)
                local map = info.map
                local pid = info.pid
                set_ply_map(gateid, process, map, pid)
                return
            end
        end

        -- steer to map server the system recomment
        local steer = gSysConfig.steer
        if steer and steer ~= gMapID then
            LOG("firstPacket, account=%s, pid=%d, process=%s, account steer to map %d", account, self.pid, process, steer)
            change_server(gateid, process, steer)
            return
        end
    end

    if not p then
        p = player_t.create(account)
        if p then
            LOG("firstPacket, account=%s, pid=%d, process=%s, create new player in local ", account, p.pid, process)
            local dg = dbmng:getGlobal()
            dg.ply:insert({_id=account, pid=p._id, map=p.map, create=gTime, state=0})
        end
    end
    if not p then return INFO("NOT HANDLE WHY") end

    local map = p.map
    local pid = p._id
    LOG("firstPacket, setSrvID, pid=%d, map=%d, proc=%s, gid=%d", pid, map, process, self.gid)

    set_ply_map(gateid, process, map, pid)
    return
end
--]]

function login(self, pid)
    if self.pid ~= 0 then return end
    local gid = self.gid

    local p = getPlayer(pid)
    if p then
        p.gid = gid
        INFO("[LOGIN], on, pid=%d, gid=%d, name=%s", pid, gid, p.name)
        p.tmLogin = gTime
        Rpc:onLogin(p, p.pid, p.name)
        if p.tmLogout and p.tmLogout == gTime then
            p.tmLogout = gTime - 1
        end
        p:get_build()
        p._pro.food = 10000000
        p._pro.wood = 10000000
        p._pro.arms = {
            {1001,100000},
            {2001,100000},
            {3001,100000},
            {4001,100000},
        }
        p._pro.rmb = 1000000

        p:get_item()

        --p._item = {
        --    -- 英雄卡
        --    {1, 4001001, 100},
        --    {2, 4001002, 100},
        --    {3, 4001003, 100},
        --    {4, 4001004, 100},

        --    -- 碎片
        --    {5, 4002001, 100},
        --    {6, 4002002, 100},
        --    {7, 4002003, 100},
        --    {8, 4002004, 100},

        --    -- 经验书
        --    {9, 4003001, 100},
        --    {10, 4003002, 100},
        --    {11, 4003003, 100},

        --    -- 特定技能书
        --    {12, 5001001, 100},
        --    {13, 5001002, 100},
        --    {14, 5001003, 100},
        --    {15, 5001004, 100},
        --    {16, 5001005, 100},
        --    {17, 5001006, 100},
        --    {18, 5001007, 100},
        --    {19, 5001008, 100},
        --    {20, 5001009, 100},
        --    {21, 5001010, 100},

        --    -- 通用技能书
        --    {22, 5002001, 100},
        --    {23, 5002002, 100},
        --    {24, 5002003, 100},
        --    {25, 5002004, 100},

        --    -- 重置技能书
        --    {26, 5003001, 100},

        --    -- 城建加速
        --    {27, 3000001, 100},
        --    {28, 3000002, 100},
        --    {29, 3001001, 100},
        --    {30, 3001002, 100},
        --    {31, 3002001, 100},
        --    {32, 3002002, 100},
        --    {33, 3003001, 100},
        --    {34, 3003002, 100},
        --}

        -- Hx@2015-12-24 : lazy init union part, in case db:union_member was deleted manually
        if not p._union then p._union = union_member_t.create(pid, 0, 0) end

        return
    end
    LOG("player:login, pid=%d, gid=%d, not found player", pid, gid)
end

function onBreak(self)
    INFO("[LOGIN], off, pid=%d, gid=%d, name=%s", self.pid or 0, self.gid or 0, self.name or "unknonw")
    self.gid = nil
    self.tmLogout = gTime
    -- find some way to remove player's email
    --self._mail = nil
    c_rem_eye(self.pid)
end

function isOnline(self)
    return self.gid
    --if self.tmLogin then
    --    if not self.tmLogout then return true end
    --    if self.tmLogin > self.tmLogout then return true end
    --end
end

function is_online(self)
    if self.tmLogin then
        if not self.tmLogout then return true end
        if self.tmLogin > self.tmLogout then return true end
    end
end


function debugInput(self, str)
    if self.pid == 0 then
        loadstring(str)()
    end
end

function get_user_simple_info(self, pid)
    local p = getPlayer(pid)
    if p then
        Rpc:on_get_user_simple_info(self, p.pid, p.vip_lv, p.name, p.photo, p.photo_url)
    end
end

function get_user_info(self, pid, what)
    local t = {}
    t.key = what

    local pb = getPlayer(pid)
    if not pb then
        --nil
    elseif what == "pro" then
        t.val = {
            pid = pb.pid,
            name = pb.name,
            lv = pb.lv,
            uid = pb:get_uid(),
        }
    elseif what == "ef" then
    elseif what == "aid" then
        t.val = {
            max = 6666
        }
    end
    if not t.val then t.val = {} end
    Rpc:get_user_info(self, t)
end

--{{{ union
function get_uid(self)
    return self.uid
    --if self._union then return self._union.uid or 0 end
    --return 0
end

function set_uid(self, val)
    self.uid = val
    --self._union.uid = val
end

function get_rank(self)
    return self._union.rank
end

function set_rank(self, val)
    self._union.rank = val
end

function union_data(self)
    return self._union
end

function leave_union(self)
    local tr = self:get_troop()
    for k, v in pairs(tr or {} ) do
        room.del(v)
    end

    local um = self._union
    um.tmLeave = gTime
    um:add_history({
        uid=self:get_uid(),
        tmJoin = um.tmJoin,
        tmLeave = um.tmLeave,
        rank = um.rank,
    })
    self:set_uid(0)
    self._union:clear()
end

function on_join_union(self, uid)
    local t = self._union
    t.tmJoin = gTime
    --t.uid = uid
    self:set_uid(uid)
    t.rank = resmng.UNION_RANK_1
    etypipe.add(self)
end

function get_union_info(self)
    return {
        pid = self.pid,
        name = self.name,
        lv = self.lv,
        rank = self:get_rank(),
        photo = self.photo,
        eid = self.eid,
        x = self.x,
        y = self.y,
    }
end

function get_intro(self)
    local t = {
        pid = self.pid,
        name = self.name,
        lv = self.lv,
        uid = self:get_uid(),
        photo = self.photo,
    }
    local u = unionmng.get_union(self:get_uid())
    if u then
        t.uid = u.uid
        t.alias = u.alias
        t.flag = u.flag
        t.rank = u.rank
    end
    return t
end

function union(self)
    return unionmng.get_union(self:get_uid())
end

--}}}

function initObj(self)
    if not self.aid then self.aid = {} end
    --setmetatable(self.aid, {__mode="v"})
    --if not self._troop then self._troop = {} end
end

function getTime(self)
    Rpc:getTime(self, gTime)
end


function get_db_checker(db, frame)
    local f = function( )
        local info = db:runCommand("getPrevError")
        if info.ok then
            local dels = {}
            local its = _cache
            local cur = gFrame

            for k, v in pairs(its) do
                local n = v._n_
                if n then
                    if n == frame then
                        table.insert(dels, k)
                    elseif cur - n > 100 then
                        v._n_ = nil
                    end
                end
            end
            for _, v in pairs(dels) do its[ v ] = nil end

            dels = {}
            its = _cache_items
            for k, v in pairs(its) do
                local n = v._n_
                if n then
                    if n == frame then
                        table.insert(dels, k)
                    elseif cur - n > 100 then
                        v._n_ = nil
                    end
                end
            end
            for _, v in pairs(dels) do its[ v ] = nil end

        end
    end
    return coroutine.wrap(f)
end


function check_pending()
    local db = dbmng:tryOne(1)
    if not db then return end
    local hit = false
    local cur = gFrame
    for pid, chgs in pairs(_cache) do
        if not chgs._n_ then
            db.player:update({_id=pid}, {["$set"]=chgs})
            dumpTab(chgs, "update player")
            local p = getPlayer(pid)
            Rpc:statePro(p, chgs)
            chgs._n_ = cur
            hit =true
        end
    end

    for pid, chgs in pairs(_cache_items) do
        if not chgs._n_ then
            db.item:update({_id=pid}, {["$set"]=chgs})
            local p = getPlayer(pid)
            Rpc:stateItem(p, chgs)
            chgs._n_ = cur
            hit = true

            for k, v in pairs(chgs) do
                if k ~= "_n_" then
                    if v[3] <= 0 then
                        db.item:update({_id=pid}, {["$unset"]={[k]=1}})
                        p._item[ v[1] ] = nil
                    end
                end
            end
        end
    end

    if hit then get_db_checker(db, gFrame)() end
end


-- _ef,
-- _efcivil
-- _efunion
-- _efhero
function initEffect(self)
    -- todo
    -- default, build, tech, talent, equip
    -- union
    -- hero

    -- default
    for k, v in pairs(resmng.prop_effect_type) do
        if v.Default ~= 0 then
            self:addEffect({[k] = v.Default}, true)
        end
    end

    -- debug
    self:addEffect({BuildQueue=1, TrainCount=10, Captive=10, CounterCaptive=10, GatherSpeed = 54000}, true)

    -- build
    local bs = self:get_build()
    if bs then
        for _, v in pairs(bs) do
            local node = resmng.prop_build[ v.propid ]
            if node and node.Effect then
                self:addEffect(node.Effect or {}, true)
            end
        end
    end

    local es = self:get_equip()
    if es then
        for k, v in pairs(es) do
            local node = resmng.prop_equip[ v.propid ]
            if node and node.Effect then
                self:ef_add(node.Effect, true)
            end
        end
    end

    -- hero
    self:update_ef_hero(true)
end

function addEffect(self, eff, init)
    if not eff then return end
    local t = self._ef
    local res = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) + v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end
        if not init then LOG("addEffect, pid=%d, what=%s, num=%d", self.pid, k, v) end
    end
    if not init then Rpc:stateEf(self, res) end
end

function remEffect(self, eff)
    if not eff then return end
    local t = self._ef
    local res = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) - v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end
        LOG("remEffect, pid=%d, what=%s, num=%d", self.pid, k, v)
    end
    Rpc:stateEf(self, res)
end


function calc_diff(A, B) -- A, original; B, new one
    local C = {}
    for k, v in pairs(A) do
        C[k] = (B[k] or 0) - v
    end
    for k, v in pairs(B) do
        if not A[k] then
            C[k] = B[k]
        end
    end
    return C
end

function ef_chg(self, A, B) -- A, original; B, new, for upgrade
    local C = calc_diff(A, B)
    self:addEffect(C)
end

function ef_add(self, eff, init)
    if not eff then return end
    local t = self._ef
    local res = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) + v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end
        LOG("addEffect, pid=%d, what=%s, num=%d", self.pid, k, v)
    end
    if not init then Rpc:stateEf(self, res) end
end

function ef_rem(self, eff)
    if not eff then return end
    local t = self._ef
    local res = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) - v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end
        LOG("remEffect, pid=%d, what=%s, num=%d", self.pid, k, v)
    end
    Rpc:stateEf(self, res)
end


function get_val(self, what)
    return get_val_by(what, self._ef, self._ef_hero or {}, self._ef_union or {})
end



--------------------------------------------------------------------------------
-- Function : 获取指定effect的ef, ef_a, ef_r
-- Argument : self, what
-- Return   : ef, ef_a, ef_r
-- Others   : NULL
--------------------------------------------------------------------------------
function get_val_extra(self, what)
    local node = resmng.get_conf("prop_effect_type", what)
    if not node then
        return 0
    end

    local bidx = what
    local ridx = string.format("%s_R", what)
    local eidx = string.format("%s_A", what)

    local sf = self._ef
    local hf = self._ef_hero or {}
    local uf = self._ef_union or {}

    local b = (sf[bidx] or 0) + (hf[bidx] or 0) + (uf[bidx] or 0)
    local r = (sf[ridx] or 0) + (hf[ridx] or 0) + (uf[ridx] or 0)
    local e = (sf[eidx] or 0) + (hf[eidx] or 0) + (uf[eidx] or 0)
    r =  (10000 + r) * 0.0001

    return b, r, e
end


function getProp(self, what)
    if not resmng.EFFECT_TYPE[what] then WARN("effect:%s not found", what) end
    return self._ef[ what ] or 0
end

function getPropRate(self, what)
    if not resmng.EFFECT_TYPE[what] then WARN("effect:%s not found", what) end
    local rate = self._ef[ string.format("%sRate", what) ]
    if not rate then return 1 end
    return (10000 + rate) * 0.0001
end

function getPropValue(self, what)
    return self:getProp(what) * self:getPropRate(what)
end

function getDb(self)
    return dbmng:getOne(self.pid)
end

function doCondCheck(self, class, mode, lv, ...)
    if class == "OR" then
        for _, v in pairs({mode, lv, ...}) do
            if self:doCondCheck(unpack(v)) then return true end
        end
        return false

    elseif class == "AND" then
        for _, v in pairs({mode, lv, ...}) do
            if not self:doCondCheck(unpack(v)) then return false end
        end
        return true

    elseif class == resmng.CLASS_RES then
        if mode == resmng.DEF_RES_FOOD then
            return self.food - (gTime-self.foodTm)*self.foodUse / 3600 >= lv
        elseif mode == resmng.DEF_RES_WOOD then
            return self.wood >= lv
        end
    elseif class == resmng.CLASS_BUILD then
        local t = resmng.prop_build[ mode ]
        if t then
            local c = t.Class
            local m = t.Mode
            local l = t.Lv
            for _, v in pairs(self:get_build()) do
                local n = resmng.prop_build[ v.propid ]
                if n and n.Class == c and n.Mode == m and n.Lv >= l then return true end
            end
        end
    elseif class == resmng.CLASS_GENIUS then
        local t = Data.prop_genius[ mode ]
        if t then
            local c = t.class
            local m = t.mode
            local l = t.lv
            for _, v in pairs(self.genius) do
                local n = Data.prop_genius[ v ]
                if n and n.Class == c and n.Mode == m and n.Lv >= l then return true end
            end
        end
    elseif class == resmng.CLASS_TECH then
        local t = resmng.get_conf("prop_tech", mode)
        if t then
            for _, v in pairs(self.tech) do
                local n = resmng.get_conf("prop_tech", v)
                if n and t.Class == n.Class and t.Mode == n.Mode and t.Lv <= n.Lv then
                    return true
                end
            end
        end
    elseif class == resmng.CLASS_ITEM then
        return self:get_item_num(mode) >= lv

    end

    -- default return false
    return false
end

function condCheck(self, tab)
    if tab then
        for _, v in pairs(tab) do
            if not self:doCondCheck(unpack(v)) then return false end
        end
    end
    return true
end

function consCheck(self, tab, num)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if not self:doCondCheck(class, mode, lv * num) then return false end
        end
    end
    return true
end

function consume(self, tab, num, why)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if not self:doConsume(class, mode, lv * num, why) then return false end
        end
    end
end

function doConsume(self, class, mode, num, why)
    if class == resmng.CLASS_RES then
        return self:doUpdateRes(mode, -num, why)
    elseif class == resmng.CLASS_ITEM then
        return self:dec_item_by_item_id(mode, num, why)
    end
end

function add_bonus(self, tab, reason)
    if tab ~= nil then
        for k, v in pairs(tab) do
            local class, mode, num = unpack(v)
            self:do_add_bonus(class, mode, num)
        end
    end
end

function do_add_bonus(self, class, mode, num, reason)
    if class == "item" then
        self:addItem(mode, num)
    elseif class == "res" then
        self:doUpdateRes(mode, num, reason)
    elseif class == "exp" then
        self:add_exp(mode)  --这种情况只有两个参数，mode就是数量
    elseif class == "solider" then
        self:inc_arm(mode, num)
    end
end

function getCureTime(t)
    return 10
end

function cure(self, hurt)
    local t = {}
    for k, v in pairs(hurt) do
        table.insert(t, {k, v})
    end
    timer.new("cure", self:getCureTime(t), self.pid, t)
end

-- when troop march through the country boundary
function qryCross(self, toPid, cmd, param)
    local sn = getSn("qryCross")
    local smap = gMapID
    local spid = self.pid

    LOG("qryCross, smap=%d, sn=%d", smap, sn)
    Rpc:onQryCross(getPlayer(0), toPid, sn, smap, spid, cmd, param)
    return putCoroPend("rpc", sn)
end

function onQryCross(self, toPid, sn, smap, spid, cmd, arg)
    LOG("onQryCross, toPid=%d, smap=%d, spid=%d, sn=%d, cmd=%s", toPid, smap, spid, sn, cmd)
    dumpTab(arg, "QryCross")
    local code = 0
    Rpc:onAckCross(getPlayer(0), smap, sn, code, arg)
end

function onAckCross(self, smap, sn, code, res)
    LOG("onAckCross, smap=%d, sn=%d, code=%d", smap, sn, code)
    if code == 0 then dumpTab(res, "AckCross") end
    local co = getCoroPend("rpc", sn)
    if co then
        coroutine.resume(co, code, res)
    end
end

function testQryCross(self)
    -- -2, the pid is minus, means the map 2, pid 0
    local code, tab = self:qryCross(2, "sayHello", {a=1, b="string"})
    LOG("qryCross, code=%d", code)
    if code == 0 then dumpTab(tab) end
end

local function sendCertify(proc, code)
    pushHead(gateid, 0, gNetPt.NET_CERTIFY)  -- NET_CERTIFY
    pushInt(code)
    pushString(proc)
    pushOver()
end


function gm_user(self, cmd)
    if config.IsEnableGm ~= 1 then
        return
    end

    local tb = string.split(cmd)
    local choose = tb[1]
    if choose == "addexp" then
        local value = gmmng:get_parm(1)
        self:add_exp(value)
    end
end

function qryInfo(self, aid)
    if aid == 0 then aid = self.pid end
    local p = getPlayer(aid)
    if p then
        Rpc:qryInfo(self, p._pro)
    end
end

function loadData(self, what)
    local t = {}
    t.key = what
    if what == "pro" then
        t.val = self._pro

    elseif what == "item" then
        t.val = self:get_item()

    elseif what == "equip" then
        t.val = self:get_equip()

    elseif what == "ef" then
        t.val = self._ef

    elseif what == "ef_hero" then
        t.val = self._ef_hero

    elseif what == "build" then
        local ts = {}
        local count = 0
        for k, v in pairs(self:get_build() or {}) do
            table.insert(ts, v._pro)
            count = count + 1
            local conf = resmng.get_conf("prop_build", v.propid)
            if conf then
                ts[count].name = conf.Name
            end
        end
        t.val = ts

    elseif what == "tech" then
        t.val = self.tech

    elseif what == "hero" then
        local ts = {}
        for k, v in pairs(self._hero or {}) do
            local h = copyTab(v._pro)
            table.insert(ts, h)
        end
        t.val = ts

    elseif what == "troop" then
        local data = {}
        for _, v in pairs(self._troop or {}) do
            -- Hx@2016-01-29: 过滤集结
            if v.idx < 1000 then
                table.insert(data, v._pro)
            end
        end
        t.val = data
    elseif what == "ache" then


    end


    if not t.val then t.val = {} end
    Rpc:loadData(self, t)
    --self:addTips("hello", {1,"hello", {"hello", {"world"}}} )
end

function addEye(self)
    local x = self.x
    local y = self.y
    local lv = 0
    if x < 0 or x >= 1280 then return end
    if y < 0 or y >= 1280 then return end
    c_add_eye(x, y, lv, self.pid, self.gid)
end

function get_room(self,rid)
    local info = room.get_info(rid)
    Rpc:get_room(self, rid,info)
end


function qryblock(self, ...)
    local pid = self.pid
    local gid = self.gid
    for _, v in pairs({...}) do
        if v >= 0 then
            c_qry_block(pid, gid, v)
        end
    end
end

function remEye(self)
    c_rem_eye(self.pid)
end

function movEye(self, x, y)
    if x < 0 or x >= 1280 then return end
    if y < 0 or y >= 1280 then return end
    --LOG("moveEye, x=%d, y=%d, x=%d, y=%d", x,y,x/16, y/16)
    c_mov_eye(self.pid, x, y)
end

function say(self, saying, i)
    LOG("pid=%d, say, i=%d, frame=%d", self.pid, i, gFrame)
    Rpc:say1(self, saying, i)
end


function runCommand(self, str)
    function run()
        Rpc:runCommand(self, {info=loadstring(str)()})
    end
    local result = xpcall(run, function(e)
        WARN(e..debug.stack(1))
        --Rpc:runCommand(self, {err=e, stack=debug.traceback()})
    end)
end

function can_food(self,num)
    local foodUse = self.foodUse * self:getPropRate("FoodUse")
    local use = math.ceil((gTime - self.foodTm) *  foodUse / 3600)
    local have = self.food

    if use >= have then
        have = 0
    else
        have = have - use
    end

    return have > num
end

function resetfood(self)


    local foodUse = self.foodUse * self:getPropRate("FoodUse")
    local use = math.ceil((gTime - self.foodTm) *  foodUse / 3600)
    local have = self.food
    if use >= have then have = 0
    else have = have - use end

    self.food = have
    self.foodTm = gTime

    --if save then self:save("player", self.pid, {food=have, foodTm=gTime}) end
    return self.food
end


--------------------------------------------------------------------------------
-- Function : 查询玩家资源数量
-- Argument : self, res_type
-- Return   : succ - number; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function get_res_num(self, res_type)
    local what = resmng.prop_resource[res_type].CodeKey
    if not what then
        ERROR("get_res_num: wrong resource type. pid = %d, res_type = %d", self.pid, res_type or -1)
        return false
    end

    if what == "food" then
        return self:resetfood()
    else
        self[what] = self[ what ] or 0
        if self[what] < 0 then
            self[what] = 0
        end
        return self[what]
    end
end


function doUpdateRes(self, mode, num, reason)
    -- TODO: 校验 num 大小是否合法

    local what = resmng.prop_resource[mode].CodeKey
    if not what then
        ERROR("doUpdateRes: wrong resource mode. pid = %d, mode = %d", self.pid, mode or -1)
        return false
    end

    reason = reason or VALUE_CHANGE_REASON.DEFAULT
    if reason == VALUE_CHANGE_REASON.DEFAULT then
        ERROR("doUpdateRes: pid = %d, don't use the default reason.", self.pid)
    end

    if what == "food" then
        local useSpeed = self.foodUse * self:getPropRate("FoodUse")
        local use = math.ceil((gTime - self.foodTm) * useSpeed / 3600)
        local have = self.food - use

        if have < 0 then have = 0 end
        local old = have
        have = have + num
        if have == 0 then have = 0 end
        self.food = have
        self.foodTm = gTime
        local tips = string.format("doUpdateRes: pid=%d, what=%s, num=%s, %d->%d, reason=%d", self.pid, what, num, old, have, reason)
        INFO(tips)
    else
        local have = self[ what ] or 0
        if have < 0 then have = 0 end
        local old = have
        have = have + num
        if have < 0 then have = 0 end
        self[ what ] = have
        local tips = string.format("doUpdateRes: pid=%d, what=%s, num=%s, %d->%d, reason=%d", self.pid, what, num, old, have, reason)
        INFO(tips)
    end
    return true
end

function get_build_queue(self)
    local num = 0
    for k, v in pairs(self:get_build()) do
        if v.state == BUILD_STATE.CREATE or v.state == BUILD_STATE.UPGRADE then
            num = num + 1
        end
    end
    return num
end

function reCalcFood(self)
    self:resetfood()
    local use = 0
    for _, v in pairs(self.arms) do
        local node = resmng.prop_arm[ v[1] ]
        if node then
            use = use + node.Consume * v[2]
        end
    end

    local ts = self:get_troop()
    for _, t in pairs(ts or {}) do
        for _, a in pairs(t.arms) do
            for _, o in pairs(a.objs) do
                local node = resmng.prop_arm(o.id)
                if node then
                    use = use + node.Consume * o.num
                end
            end
        end
    end

    use = math.ceil(use)
    self.foodUse = use
    self.foodTm = gTime
end

function addArm(self)
    for k, v in pairs(resmng.prop_arm) do
        self:inc_arm(k, 20000)
    end
    self:reCalcFood()
end

function addRes(self)
    self.food = (self.food or 0) + 10000
    self.wood = (self.wood or 0) + 10000
end


troopExample = {
    _id="1_2",
    idx=1,
    pid=2,
    eid=1, -- the troop eid
    aid=1, -- atacker eid
    did=1, -- defencer eid

    x=0, y=0, dx=1, dy=1,

    action="seige",
    state="go",
    tmStart = gTime,
    tmOver = gTime + 10,
    tmSn = 1,
    arms={
        [1] = {
            num = 100, mode = 1,
            objs = {
                {id=1001,num=50}, -- add extra "dead", "prop" to obj in fight
                {id=1002,num=50},
                {id=0, hero="1_1000", leader=1},
            }
        },
        [2] = {
            num = 100, mode = 2,
            objs = {
                {id=2001,num=50},
                {id=2002,num=50},
                {id=0, hero="1_1000", leader=1},
            }
        },
        [3] = {num=0, },
        [4] = {num=0, }
    }
}

function add_soldier(propid, num, troop)
    local prop = resmng.prop_arm[ propid ]
    if not prop then return end

    local mode = prop.Mode
    local arm = troop.arms[ mode ]
    if not arm then
        arm = {mode=mode, num=0, objs={}}
        troop.arms[ mode ] = arm
    end

    local hit = false
    for k, v in pairs(arm.objs) do
        if prop.ID == v.id then
            v.num = v.num + num
            hit = true
            break
        end
    end
    if not hit then
        table.insert(arm.objs, {id=prop.ID, num=num})
    end
    arm.num = arm.num + num
end

function add_hero(arm, mode, hero)
    local t = arm[ mode ]
    if not t then
        t = {num=0, objs={}}
        arm[mode] = t
    end
    local ch = heromng.get_hero_by_uniq_id(hero)
    local h = {hero=hero,id=ch.propid}
    table.insert(t.objs, h)
    return h
end

function troop_init(self, objs, troop)
    for _, v in pairs(objs) do
        local arm = v[1]
        local num = v[2]
        add_soldier(arm, num, troop)
    end
end

function init_arm(objs)
    local t = {arms={}}
    for _, v in pairs(objs) do
        local arm = v[1]
        local num = v[2]
        add_soldier(arm, num, t)
    end
    return t.arms
end


function init_def_troop(self)
    local t = {action=resmng.TroopAction.Defend, aid=self.eid, arms={}}
    local total = 0
    for _, v in pairs(self.arms) do
        local arm = v[1]
        local num = v[2]
        total = total + num
        add_soldier(arm, num, t)
    end

    local hs = self:get_def_hero()
    for i = 1, 4, 1 do
        if hs[i] then
            add_hero(t.arms, i, hs[i])
        end
    end
    return t
end

function get_weight(self, t)
    local total = 0
    for _, A in pairs(t.arms) do
        for _, O in pairs(A.objs) do
            local node = resmng.prop_arm[ O.id ]
            if node then
                total = total + node.Weight * O.num
            end
        end
    end
    return total
end

function addTips(self, tips, tipt)
    if tipt then
        local str = ""
        if type(tipt) == "table" then
            str = string.format("%s = %s", tips, sz_T2S(tipt))
        else
            str = string.format("%s = %s", tips, tostring(tipt))
        end
        Rpc:tips(self, str)
    else
        Rpc:tips(self, tips)
    end
end

function say2(self, a1, a2, a3)
    LOG("say2, a1=%d, a2[1]=%s, a3=%d", a1, a2["1"], a3)
    dumpTab(a2)
end

function testPack(self, i1, p2, s3)
    LOG("testPack, i1=%d, s3=%s", i1,s3)
    LOG("testPack, pack = ")
    dumpTab(p2)
    Rpc:testPack(self, i1, p2, s3)
end

function chat(self, channel, word, sn)
    if channel == resmng.ChatChanelEnum.World then
        Rpc:chat({pid=-1,gid=_G.GateSid}, channel, self.pid, self.photo, self.name, word)

    elseif channel == resmng.ChatChanelEnum.Union then
        local u = self:union()
        if not u then return end
        local pids = {}
        for _, v in pairs(u.members) do
            if v:is_online() then
                table.insert(pids)
            end
        end
        Rpc:chat(pids, channel, self.pid, self.photo, self.name, word)

    elseif channel == resmng.ChatChanelEnum.Culture then

    end

    reply_ok(self, "chat", sn)
end

function do_genius(self, id)
    if (self.talent or 0) < 1 then return end

    local conf = resmng.get_conf("prop_genius", id)
    if not conf then
        ERROR("do_genius: get prop_genius config failed. pid = %d, genius_id = %d.", self.pid, id)
        return
    end

    if not self:condCheck(conf.cond) then return end

    local tab = self.genius or {}
    if conf.Lv > 1 then
        local old_id = id - 1
        local old_conf = resmng.get_conf("prop_genius", old_id)
        if not old_conf then
            ERROR("do_genius: get prop_genius config failed. pid = %d, old_genius_id = %d.", self.pid, old_id)
            return
        else
            local idx = is_in_table(tab, old_id)
            if idx then
                table.remove(tab, idx)
                self:ef_rem(old_conf.Effect)
            end
        end
    end

    table.insert(tab, id)
    self:ef_add(conf.Effect)
    self.genius = tab
    self.talent = self.talent-1
end


function notify(self, chg)
    Rpc:statePro(self, chg)
end

function testFight(self, an1, an2, an3, an4, ah1, ah2, ah3, ah4, dn1, dn2, dn3, dn4, dh1, dh2, dh3, dh4)
    local function _set(an1, an2, an3, an4, ah1, ah2, ah3, ah4)
        local arms = {}
        for k, v in ipairs({an1, an2, an3, an4}) do
            if v > 0 then
                arms[k] = {
                    mode = k,
                    objs = { {id=k*1000+1, num=v} }
                }
            end
        end

        for k, v in ipairs({ah1, ah2, ah3, ah4}) do
            if v > 0 then
                local hero = resmng.prop_hero_basic[ v ]
                if hero then
                    local node = arms[ k ]
                    if not node then
                        node = {mode=k, objs={} }
                        arms[k] = node
                    end
                    table.insert(node.objs, {id=v, num=1, hero="1_10000"})
                end
            end
        end
        return arms
    end

    local As = _set(an1, an2, an3, an4, ah1, ah2, ah3, ah4)
    local Ds = _set(dn1, dn2, dn3, dn4, dh1, dh2, dh3, dh4)

    --local As = _set(10000, 0, 0, 0, 1, 0, 0, 0)
    --local Ds = _set(10000, 0, 0, 0, 0, 0, 0, 0)

    --dumpTab(As, "As")
    --dumpTab(Ds, "Ds")

    local report = fight.pvp("test", {arms=As, did=self.eid, aid=self.eid}, {arms=Ds, aid=self.eid, did=self.eid})
    --for _, v in ipairs(report) do
    --    self:addTips("fight", v)
    --end
end

function query_fight_info(self, fid)
    local node = fight.gFightReports[ fid ]
    if node then
        Rpc:fightInfo(self, node[2])
    else
        reply_ok(self, "query_fight_info", 0, E_NO_REPORT)
    end
end

function migrate(self, x, y)
    local ts = self:get_troop()
    if ts and #ts > 0 then return ack(self, "migrate", resmng.E_TROOP_BUSY, 0) end
    if c_map_test_pos(x, y, 4) ~= 0 then return ack(self, "migrate", resmng.E_NO_ROOM, 0) end
    c_rem_ety(self.eid)
    self.x = x
    self.y = y
    etypipe.add(self)
    reply_ok(self, "migrate", y*65536+x)
end

function daily_task_list(self)
    self:packet_daily_task(self)
end

function life_task_list(self)
    self:packet_life_task()
end

function union_task_list(self)
    self:packet_life_task()
end

function finish_task(self, task_id)
    self:get_award(task_id)
end

function accept_task(self, task_id_array)
    self:accept_task(task_id_array)
end

function get_active(self)
    return self.active
end

function add_exp(self, value)
    if value <= 0 then
        return
    end

    local limit_level = #resmng.prop_level
    if self.lv >= limit_level then
        return
    end

    local add_exp = value
    local old_level = self.lv
    while(true)
    do
        local limit_exp = resmng.prop_level[self.lv].Exp
        local need_exp = limit_exp - self.exp
        if add_exp >= need_exp then
            self.lv = self.lv + 1
            self.exp = 0
            add_exp = add_exp - need_exp
        else
            self.exp = self.exp + add_exp
            break
        end
    end

   if self.lv > old_level then
       self:on_level_up(old_level, self.lv)
   end
end

function on_level_up(self, old_level, new_level)
    local diff = new_level - old_leve
    --升级要触发事情
end

function on_day_pass()
    self:task_on_day_pass()
end
function change_name(self, name)
    for k, v in pairs(gPlys) do
        if v.name == name then
            ack(self, "change_name", resmng.E_DUP_NAME)
            return
        end
    end
    self.name = name
    etypipe.add(self)
end

init()

function reply_ok(self, funcname, d1)
    ack(self, funcname, resmng.E_OK, d1 or 0)
end


--------------------------------------------------------------------------------
-- Function : 计算消除CD所需的金币
-- Argument : self, cd
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_cd_golds(self, cd)
    -- TODO: 策划规则未定
    return cd
end

function do_load_equip(self)
    local db = self:getDb()
    local info = db.equip:find({pid=self.pid, pos={["$gte"]=0}})
    local bs = {}
    while info:hasNext() do
        local b = info:next()
        bs[ b._id ] = b
    end
    return bs
end

function get_equip(self, id)
    if not self._equip then self._equip = self:do_load_equip() end
    if id then
        return self._equip[ id ]
    else
        return self._equip
    end
end

function equip_add(self, propid, why)
    local id = getId("equip")
    local t = {_id = id, propid=propid, pid=self.pid, pos=0}
    gPendingSave.equip[ id ] = t
    self:get_equip()
    self._equip[ id ] = t
    Rpc:equip_add(self, propid)

    INFO("equip_add: pid = %d, item_id = %d, reason = %d.", self.pid, propid, why)
end

function equip_rem(self, id, why)
    self:get_equip()
    self._equip[ id ] = nil
    gPendingSave.equip[ id ].pos = -1
    Rpc:equip_rem(self, id)

    INFO("equip_add: pid = %d, item_sn = %d, reason = %d.", self.pid, id, why)
end

function equip_on(self, id)
    local n = self:get_equip(id)
    if not n then return end
    if n.pos > 0 then return end
    local prop = resmng.get_conf("prop_equip", n.propid)
    if not prop then return end
    local idx = prop.Pos

    local ns = self:get_equip()
    for _, v in pairs(ns) do
        if v.pos == idx then return end
    end

    n.pos = idx
    self:ef_add(prop.Effect)
    gPendingSave.equip[ id ].pos = idx
    reply_ok(self, "equip_on", id)
end

function equip_off(self, id)
    local n = self:get_equip(id)
    if not n then return end
    if n.pos == 0 then return end
    n.pos = 0
    gPendingSave.equip[ id ].pos = 0

    local conf = resmng.get_conf("prop_equip", n.propid)
    if conf then
        self:ef_rem(conf.Effect)
    end
    reply_ok(self, "equip_off", id)
end

