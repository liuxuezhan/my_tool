-- -----------------------------------------------------------------------------
-- Hx@2016-01-25 : 行军队列
-- 队列分为队列本身\容纳多个队列的容器
-- TODO: 容器套容器
-- -----------------------------------------------------------------------------

module_class("troop_t", {
    _id = 0,
    idx = 0,
    aid = 0, did = 0,
    eid = 0, pid = 0,
    sx = 0, sy = 0, dx = 0, dy = 0,
    action = 0, state = 0,
    tmSn = 0, tmStart = 0, tmOver = 0,
    carry = {},
    arms = {}, troops = {},
    speed = 0,
    show = 0,
    shell = false,
    max = 0,
    parent = 0,
    events = {},
    tid = 0,
    rid = 0,
})

gTroops = gTroops or {}

-- Hx@2016-01-20 : cache calc tms
_stdtimes = _stdtimes or {}
setmetatable(_stdtimes, {__mode="kv"})

-- if the troop be showed, will update when these values change
local watchs = {
    state = 1,
    tmOver = 1,
    dx = 1,
    dy = 1,
    sx = 1,
    sy = 1,
    eid = 1,
    show = 1,
}

function init(self)
    if self._id ~= 0 then
        gTroops[self._id] = self
    end
    --_cache[self._id] = self._pro
    owner(self):set_troop(self.idx, self)
end

function del(t)
    LOG("[Troop] del:%s", t._id)
    --PATCH: enroll fight when manually delete
    t.state = resmng.TroopState.Back
    local Au = t:owner():union()
    if Au then Au:enroll_fight(t) end

    local A = get_ety(t.aid)
    if A and is_ply(A) and t.idx > 0 then
        A._troop[ t.idx ] = nil
    end

    if t._id ~= 0 then
        local db = dbmng:getOne()
        _cache[ t._id ] = nil
        db.troop:delete({_id=t._id})
        gTroops[ t._id ] = nil
    end

    if t.eid > 0 then
        print("remove troop, ", t.eid)
        c_rem_ety(t.eid)
    end
end

function is_mass(t)
    WARN("To Del:".. debug.stack())
    return is_shell(t)
end

-- aid, attacker eid
-- did, defencer eid

function new_idx(p)
    local maxTroop = 3 + p:getProp("TroopExtra")
    local now_troop_count = get_table_valid_count(p:get_troop())
    if now_troop_count >= maxTroop then
        -- WARNING: 俘虏回城队列不受行军队列上限影响
        if action ~= resmng.TroopAction.PRISON_BACK_HOME then
            return 0
        end
    end

    -- WARNING: troop 应该不会超过100个
    for i = 1, 100 do
        if not p:get_troop(i) then
            return i
        end
    end

    return 0
end

function create(aid, did, action, state, sx, sy, dx, dy, arms, res,max)
    assert(aid and did and action and state and sx and sy and dx and dy )

    local shell = false
    if action == resmng.TroopAction.Mass then shell = true end

    local _id
    local idx = 0
    local A = get_ety(aid)

    if is_ply(aid) then
        if shell then
            idx = getId("mass")
            _id = string.format("%d_%d", idx, action)
        else
            idx=new_idx(A)       
            if 0 < idx then _id = string.format("%d_%d", idx, A.pid) end
        end
    end
    if idx == 0 then return end
    if not _id then return end

    local t =  {
        _id=_id, idx=idx, aid=aid, did=did, sx=sx, sy=sy, dx=dx, dy=dy,
        pid=A.pid, action=action, state=state, max=max,shell=shell
    }

    if arms then
        if not shell then
            t.arms = arms
        elseif #arms > 0 then
            WARN("troop shell with arms!!!")
        end
    end

    if res then
        t.res = res
    end

    local db = dbmng:getOne()
    db.troop:insert(t)
    local obj = new(t)
    _cache[obj._id] = obj._pro
    return obj
end

function is_shell(self)
    return self.shell
end

function get_event_attack(self)
    local attack = {}
    local meets = {}
    for _, v in ipairs(self.events) do
        if not meets[v.idx] then
            meets[v.idx] = v
        else
            local prv = meets[v.idx]
            local ctm = v.tm - prv.tm
            if v.ef.Atk then
                attack[v.ef.Atk] = (ctm * v.ef.AtkSpeed / 60)
            end
        end
    end
    return attack
end

-- -----------------------------------------------------------------------------
-- Hx@2016-01-29: 计算行军事件seid 和 deid用来确定双方类型
-- aid 和 did 的对象可能由于战斗/刷新等事件而消失，所以传入x,y计算，不依赖eid
-- 出发时sx,sy为aid位置,返回时sx,sy为did位置，注意变换
-- -----------------------------------------------------------------------------
function calc_tmsA(aid, did, sx, sy, dx, dy, speed, state)
    assert(aid and did and sx and sy and dx and dy and speed and state)

    -- Hx@2016-01-21 : speed min --> sec
    speed = speed / 60

    local ckey = string.format("%s_%s_%s_%s_%s_%s_%s", aid, did, sx, sy, dx, dy, speed)
    if _stdtimes[ckey] then return _stdtimes[ckey] end
    LOG("[Troop] calc tms, aid:%s, did:%s, speed:%s", aid, did, speed)

    local crux = {}
    _stdtimes[ckey] = crux

    local idx = #crux / 2 + 1
    table.insert(crux, {idx=idx,eid=0,x=sx,y=sy,ef={}})
    table.insert(crux, {idx=idx,eid=0,x=dx,y=dy,ef={}})

    local function _ev_unionbuild(D)
        local Du = D:union()
        if not Du then return end

        for k, v in pairs(Du.build) do
            local cc = resmng.prop_world_unit[v.id]
            if cc and (cc.Mode == resmng.CLASS_UNION_BUILD_TUTTER1 or resmng.CLASS_UNION_BUILD_TUTTER2 ) then
                local a, b = v:get_cross_point(sx, sy, dx, dy)

                local idx = #crux / 2 + 1

                local eva = { idx=idx,eid=v.eid,x=a.x,y=a.y,ef=cc.Debuff or {}}
                table.insert(crux, eva)
                local evb = {idx=idx,eid=v.eid,x=b.x,y=b.y,ef=cc.Debuff or {}}
                table.insert(crux, evb)
            end
        end
    end

    if is_ply(aid) and is_ply(did) then
        local A = get_ety(aid)
        local D = get_ety(did)
        if A and D and A:get_uid() ~= D:get_uid() then _ev_unionbuild(D) end
    elseif is_monster(aid) and is_ply(did) then
        local A = get_ety(did)
        local D = get_ety(did)
        if A and D then _ev_unionbuild(D) end
    end

    local sortfun
    if sx == dx then
        if sy == dy then
            WARN("[Troop] calc tms, troop asc desc same!!!")
            sortfun = function(l, r) return true end
        elseif sy < dy then
            sortfun = function(l, r) return l.y < r.y end
        else
            sortfun = function(l, r) return l.y > r.y end
        end
    elseif sx < dx then
        sortfun = function(l, r) return l.x < r.x end
    else
        sortfun = function(l, r) return l.x > r.x end
    end

    table.sort(crux, sortfun)
    LOG("[Troop] crux count:%s", #crux)

    local meets = {}
    local function switch(data)
        if not meets[data.idx] then
            meets[data.idx] = data
        else
            meets[data.idx] = nil
        end
    end
    local function cur_speed_rate()
        local rate = 0
        for _, v in pairs(meets) do
            if (v.ef.SpeedR or 0) < rate then
                rate = v.ef.SpeedR or 0
            end
        end
        return rate
    end

    local tm = gTime
    for i = 1, #crux do
        local cur = crux[i]
        local nxt = crux[i + 1]
        switch(cur)
        if not nxt then break end
        local cur_speed = speed * (10000 + cur_speed_rate()) / 10000
        local dist = math.sqrt((cur.x - nxt.x)^2 + (cur.y - nxt.y)^2)
        local tmCross = dist / cur_speed
        cur.tm = math.ceil(tm)
        tm = tm + tmCross
        nxt.tm = math.ceil(tm)

        INFO("[Troop] calc_tms, i:%s, dist:%s speed:%s, tm:%s, tmCross:%s", i, dist, cur_speed, cur.tm, tmCross)
    end

    return crux
end

function calc_tms(aid, did, speed, state)
    assert(aid and did and speed and state)
    local A = get_ety(aid)
    local D = get_ety(did)
    local sx,sy,dx,dy = A.x,A.y,D.x,D.y
    -- Hx@2016-01-21 : speed min --> sec
    speed = speed / 60

    local ckey = string.format("%s_%s_%s_%s_%s_%s_%s", aid, did, sx, sy, dx, dy, speed)
    if _stdtimes[ckey] then return _stdtimes[ckey] end
    LOG("[Troop] calc tms, aid:%s, did:%s, speed:%s", aid, did, speed)

    local crux = {}
    _stdtimes[ckey] = crux

    local idx = #crux / 2 + 1
    table.insert(crux, {idx=idx,eid=0,x=sx,y=sy,ef={}})
    table.insert(crux, {idx=idx,eid=0,x=dx,y=dy,ef={}})

    if is_ply(aid) and is_ply(did) and A:get_uid() ~= D:get_uid() and state == resmng.TroopState.Go then
        local D = get_ety(did)
        local Du = D:union()
        if Du then
            for k, v in pairs(Du.build) do
                local cc = resmng.prop_world_unit[v.id]
                if cc and (cc.Mode == resmng.CLASS_UNION_BUILD_TUTTER1 or resmng.CLASS_UNION_BUILD_TUTTER2 ) then
                    local a, b = v:get_cross_point(sx, sy, dx, dy)

                    local idx = #crux / 2 + 1

                    local eva = { idx=idx,eid=v.eid,x=a.x,y=a.y,ef=cc.Debuff or {}}
                    table.insert(crux, eva)
                    local evb = {idx=idx,eid=v.eid,x=b.x,y=b.y,ef=cc.Debuff or {}}
                    table.insert(crux, evb)
                end
            end
        else

        end
    end

    local sortfun
    if sx == dx then
        if sy == dy then
            WARN("[Troop] calc tms, troop asc desc same!!!")
            sortfun = function(l, r) return true end
        elseif sy < dy then
            sortfun = function(l, r) return l.y < r.y end
        else
            sortfun = function(l, r) return l.y > r.y end
        end
    elseif sx < dx then
        sortfun = function(l, r) return l.x < r.x end
    else
        sortfun = function(l, r) return l.x > r.x end
    end

    table.sort(crux, sortfun)
    LOG("[Troop] crux count:%s", #crux)

    local meets = {}
    local function switch(data)
        if not meets[data.idx] then
            meets[data.idx] = data
        else
            meets[data.idx] = nil
        end
    end
    local function cur_speed_rate()
        local rate = 0
        for _, v in pairs(meets) do
            if (v.ef.SpeedR or 0) < rate then
                rate = v.ef.SpeedR or 0
            end
        end
        return rate
    end

    local tm = gTime
    for i = 1, #crux do
        local cur = crux[i]
        local nxt = crux[i + 1]
        switch(cur)
        if not nxt then break end
        local cur_speed = speed * (10000 + cur_speed_rate()) / 10000
        local dist = math.sqrt((cur.x - nxt.x)^2 + (cur.y - nxt.y)^2)
        local tmCross = dist / cur_speed
        cur.tm = math.ceil(tm)
        tm = tm + tmCross
        nxt.tm = math.ceil(tm)

        INFO("[Troop] calc_tms, i:%s, dist:%s speed:%s, tm:%s, tmCross:%s", i, dist, cur_speed, cur.tm, tmCross)
    end

    return crux
end

function add_arm(shell, node)
    LOG("[Troop] add troop, shell:%s, node:%s, prevcount:%s", shell._id, node._id, #shell.troops)
    if shell:is_shell() then
        table.insert(shell.troops, node._id)
        node.parent = shell._id
        shell.troops = shell.troops
    end
end

function rm_arm(shell, node)
    LOG("[Troop] del troop, shell:%s, node:%s, prevcount:%s", shell._id, node._id, #shell.troops)
    if shell:is_shell() then
        for k, v in pairs(shell.troops) do
            if v == node._id then
                shell.troops[k]=nil
                shell.troops = shell.troops
            end
        end
    end
end

function on_check_pending(db, _id, chgs)
    db.troop:update({_id=_id}, {["$set"]=chgs})
    local t = gTroops[ _id ]
    if not t then return end

    if t.pid > 0 then
        local A = getPlayer(t.pid)
        chgs.idx = t.idx

        if A and t.action ~= resmng.TroopAction.Mass then
            Rpc:stateTroop(A, chgs)
        end

        if t.action == resmng.TroopAction.Aid then
            if t.state == resmng.TroopState.Go
                or t.state == resmng.TroopState.Arrive
                or t.state == resmng.TroopState.Back then
                local pb = get_ety(t.did)
                chgs.pid = t.pid
                chgs.action = t.action
                chgs.state = t.state
                Rpc:union_state_aid(pb, chgs)
            end
        end

    end

    if t.show > 0 then
        local f = false
        for k, v in pairs(chgs) do
            if watchs[ k ] then
                f = true
                break
            end
        end
        if f then
            INFO(string.format("change show %d, tid:%s, gFrame=%d", t.eid, t._id, gFrame))
            troop_t.do_show(t)
        end
    end
end

function calc_num(t)
    local count = {}
    for i = 1, 4, 1 do
        if t.arms and t.arms[i] then
			count[i] = t.arms[i].num  or 0
        else
			count[i] = 0
		end
    end

	for _, tid in pairs(t.troops or {} ) do
        local v = get_by_tid(tid)
		for k, a in pairs(v.arms or {}) do
			count[k] = count[k]+ a.num
		end
    end

	return count
end

function show(t)
    if t.show and t.show == 0 then
        t.show = 1
        if not t.eid or t.eid == 0 then
            t.eid = get_eid_troop()
            gEtys[ t.eid ] = t
        end
    end
end

function unshow(t)--删除行军线
    if t.show and t.show == 1 then
        t.show = 0
        if t.eid and t.eid > 0 then
            rem_ety(t.eid)
            t.eid = 0
        end
    end
end

function do_show(t)--显示行军线
    local action = t.action
    local taction = resmng.TroopAction

    --event data different from engine to logic
    local events = {}
    for _, v in pairs(t.events) do
        table.insert(events, {
            idx=v.idx,tm=math.floor(v.tm),x=v.x,y=v.y,eid=v.eid,
            speed_rate=1 + (v.ef.SpeedR or 0) / 10000,
        })
    end

    if t.aid > 0 and is_ply(t.aid) then
        local p = get_ety(t.aid)
        if p then
            t.name = p.name
            t.uid = p:get_uid()
        end
    end

    t.count = calc_num(t)

    if t.eid == 0 then t.eid = get_eid_troop() end
    gEtys[ t.eid ] = t
    etypipe.add(t)
end

function get_by_tid(tid)
    assert(tid)
    return gTroops[tid]
end

function sum(self)
    local sum = 0
    for _, v in pairs(self.arms) do
        sum = sum + v.num
    end
    return sum
end

function owner(self)
    return get_ety(self.aid)
end

function atk_general(self, limit)
    local xs = {}
    if self.action == resmng.TroopAction.Mass then
        for i = 1, #self.troops do
            local tid = self.troops[i]
            if not tid then break end

            if limit then
                limit = limit - 1
                if limit < 0 then break end
            end

            local t = get_by_tid(tid)
            if t then
                local A = owner(t)
                table.insert(xs, {pid=A.pid,name=A.name,photo=A.photo,lv=A.lv})
            else
                WARN("atk_general can not get troop %s", tid)
            end
        end
    else
        local A = owner(self)
        table.insert(xs, {pid=A.pid,name=A.name,photo=A.photo,lv=A.lv})
    end
    return xs
end

function atk_detail(self)
    local xs = {}
    if self.action == resmng.TroopAction.Mass then
        for _, tid in ipairs(self.troops) do
            local T = get_by_tid(tid)
            local A = T:owner()
            table.insert(xs, {
                pid=A.pid,name=A.name,photo=A.photo,lv=A.lv,
                troop={state=T.state,tmStart=T.tmStart,tmOver=T.tmOver,arms=T.arms}
            })
        end
    else
        WARN("TODO, atk_detail,action:%s", self.action)
        --TODO
    end
    return xs
end

function atk_sum(self)
    if self.action == resmng.TroopAction.Mass then
        local sum = 0
        for _, tid in pairs(self.troops) do
            sum = sum + get_by_tid(tid):sum()
        end
        return sum
    else
        return T:sum()
    end
end

function def_general(self, limit)
    local xs = {}

    local D = get_ety(self.did)
    if not D then
        WARN("def_general")
        return xs
    end

    if is_ply(D.eid) then
        if self.action == resmng.TroopAction.Mass then
            table.insert(xs, {pid=D.pid,name=D.name,photo=D.photo,lv=D.lv})

            if limit then limit = limit - 1 end

            for i = 1, #D.aid do
                local t = D.aid[i]
                if not t then break end

                if limit then
                    limit = limit - 1
                    if limit < 0 then break end
                end

                local A = t:owner()
                table.insert(xs, {pid=A.pid,name=A.name,photo=A.photo,lv=A.lv})
            end
        else
            table.insert(xs, {pid=D.pid,name=D.name,photo=D.photo,lv=D.lv})
        end
    else
        table.insert(xs, {propid=D.propid})
    end

    return xs
end

function def_detail(self)
    local xs = {}
    if is_ply(self.did) then
        if self.action == resmng.TroopAction.Mass then
            local D = get_ety(self.did)
            local arms = {}
            for _, v in pairs(D.arms) do
                arms[#arms+1]={objs={{num=v[2],id=v[1]},},num=v[2],mode=0,}
            end
            table.insert(xs, {
                pid=D.pid,name=D.name,photo=D.photo,lv=D.lv,
                troop={state=0,tmStart=0,tmOver=0,arms=arms}
            })
            for _, Dat in pairs(D.aid) do
                local Da = Dat:owner()
                table.insert(xs, {
                    pid=Da.pid,name=Da.name,photo=Da.photo,lv=Da.lv,
                    troop={state=Dat.state,tmStart=Dat.tmStart,tmOver=Dat.tmOver,arms=Dat.arms}
                })
            end
        else
            WARN("TODO, def_detail,player,action:%s", self.action)
        end
    else
        WARN("TODO, def_detail,monster,action:%s", self.action)
    end
    return xs
end

function def_sum(self)
    local sum = 0
    if is_ply(self.did) then
        local D = get_ety(self.did)
        for _, arm in pairs(D.arms) do
            sum = sum + arm[2]
        end
        for _, troop in pairs(D.aid) do
            sum = sum + troop:sum()
        end
    elseif is_monster(self.did) then
        local M = get_ety(self.did)
        for _, arm in pairs(M.arms) do
            sum = sum + arm.num
        end
    end
    return sum
end
