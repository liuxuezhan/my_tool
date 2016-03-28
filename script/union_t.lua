-- Hx@2015-11-30 : 军团类
module_class("union_t", {
    uid = 0,
    _id = 0,
    name = "",
    alias = "",
    level = 0,
    language = "",
    credit = 0,
    membercount = 0,
    mars = 0,       --战神
    leader = 0,
    tech_mark = {},
    donate = 0,
    rank_alias = {},
    buildlv = {},   --设施级别
    note_in = "",
    note_out = "",
})

function init(self)
    if not self._members then self._members = {} end
    if not self.applys then self.applys = {} end
    if not self._invites then self._invites = {} end
    if not self.mass then self.mass = {} end
    if not self._tech then self._tech = {} end
    if not self.log then self.log = {} end
    table.sort(self.log, function(l, r)
        return l.sn > r.sn
    end)
    if not self._fight then self._fight = {} end
    setmetatable(self._fight, {__mode="v"})
    if not self.donate_rank then self.donate_rank = {} end
    if not self.buildlv then self.buildlv = {} end
    if not self.build then self.build = {} end
end

--{{{ basic
function create(A, name, alias, language, mars)
    local old = unionmng.get_union(A:get_uid())
    if old then old:rm_member(A) end

    local id = getId("union")
    local data = {
        uid=id,_id=id,name=name,alias=alias,level=1,language=language,credit=0,
        membercount=1,mars=mars,leader=A.pid, note_in="",note_out="",invites = {}
    }
    local union = new(data)

    --hack add member
    union._members[A.pid] = A
    A:on_join_union(union.uid)
    --self:notifyall("member", resmng.OPERATOR.ADD, A:get_union_info())

    A:set_uid(union.uid)
    A:set_rank(resmng.UNION_RANK_5)

    unionmng.add_union(union)
    dbmng:getOne().union:insert(union._pro)
    dbmng:getOne().union_log:insert({_id=id})

    union:add_log(resmng.EVENT_TYPE.UNION_CREATE, {name=A.account})

    LOG("[Union] create, pid:%s, uid:%s,", A.pid, union.uid)
    return union
end

function on_check_pending(db, _id, chgs)
    db.union:update({_id=_id}, {["$set"]= chgs})

    chgs.uid = _id

    local u = unionmng.get_union(_id)
    u:notifyall("info", resmng.OPERATOR.UPDATE, chgs)

end

function get_info(self)
    local info = {}
    info.uid = self.uid
    info.name = self.name
    info.alias = self.alias
    info.level = self.level
    info.membercount = self.membercount
    info.language = self.language
    info.flag = self.flag
    info.note_in = self.note_in
    if not self.leader then
        info.leader = "Unknown"
    else
        info.leader = getPlayer(self.leader).name
    end
    return info
end

-- -----------------------------------------------------------------------------
-- Hx@2016-01-26 : 删除联盟
-- 包括 union, member, fight, build, tech,
-- -----------------------------------------------------------------------------
function destory(self)
    --self:notifyall("union", resmng.OPERATOR.DELETE, self.uid)
    self:broadcast("union_destory")
    for k, v in pairs(self.build) do
        um:remove_build(k)
    end

    for _, A in pairs(self._members) do
        A:leave_union()
    end
    local db = dbmng:getOne()
    db.union:delete({_id=self.uid})
    LOG("[Union] destory, uid:%s", self.uid)
end

function get_effect(eid)
    local A = get_ety(eid)
    if not A then return {} end
    if is_ply(eid) then
        if A:get_uid() == self.uid then
            return self:get_ef(A.x, A.y, 4)
        else
            return self:get_def(A.x, A.y, 4)
        end
    else
        --TODO: 怪物
    end
end

function get_ef(self, x, y, size)
    -- default: player
    size = size or 4

    local ef = {}
    local function _add(res)
        for k, v in pairs(res) do
            ef[k] = (ef[k] or 0) + v
        end
    end
    _add(self:get_build_ef(x, y, size))
    _add(self:get_tech_ef(x, y, size))
    return ef
end

function get_def(self, x, y, size)
    --TODO: 敌军在领地内
end
--}}}

--{{{ member
-- -----------------------------------------------------------------------------
-- Hx@2016-01-25 : 添加移除玩家感觉写的有问题，涉及到的api过多，不够清晰
-- -----------------------------------------------------------------------------
function add_member(self, A)
    if self:has_member(A) then return resmng.E_ALREADY_IN_UNION end
    local old = unionmng.get_union(A:get_uid())
    if old then
        old:quit(A)
    end
    A:on_join_union(self.uid)
    self._members[A.pid] = A
    self.membercount = tabNum(self._members)
    --self:broadcast("union_add_member", A:get_union_info())
    local t = A:get_union_info()
    t.uid = self.uid
    self:notifyall("member", resmng.OPERATOR.ADD, t)

    self.donate_rank = {}
    self:add_log(resmng.EVENT_TYPE.UNION_JOIN, {name=A.account})
    return resmng.E_OK
end

function rm_member(self, A)
    if not self:has_member(A) then return resmng.E_NO_UNION end
    --self:broadcast("union_on_rm_member", A.pid)
    self:notifyall("member", resmng.OPERATOR.DELETE, {pid=A.pid})
    self._members[A.pid] = nil
    self.membercount = tabNum(self._members)
    A:leave_union()

    self.donate_rank = {}
    return resmng.E_OK
end

function kick(self, A, B)
    if not (is_legal(A, "Kick") and A:get_rank() > B:get_rank() ) then
        return resmng.E_DISALLOWED
    end

    local t = B:get_troop()
    for _, v in pairs(t or {}) do
        if v.action == (resmng.TroopAction.Aid or resmng.TroopAction.Mass_Node or resmng.TroopAction.Mass) then
            troopx_back(B, v.idx)
        end
    end

    local ret = self:rm_member(B)
    if ret == resmng.E_OK then
        LOG("[Union], A:%s kick B:%s", A.pid, B.pid)
        self:add_log(resmng.EVENT_TYPE.UNION_KICK, {
            name = A.account,
            k_name = B.account,
        })
    end
    return ret
end

function quit(self, A)
    if not is_legal(A, "Quit") then return resmng.E_DISALLOWED end

    local ret = self:rm_member(A)
    if ret == resmng.E_OK then
        LOG("[Union] quit, pid:%s ", A.pid)
        self:add_log(resmng.EVENT_TYPE.UNION_QUIT, {
            name = A.account,
        })
    end
    return ret
end

function trans(self, A)
    --TODO
end

function has_member(self, ...)
    local arg = {...}
    for i = 1, #arg do
        A = arg[i]
        if self.uid ~= A:get_uid() then
            return false
        else
            if not self._members[A.pid] then
                WARN("uid matching but not in member list, pid:%s, uid:%s", A.pid, self.uid)
                return false
            end
        end
    end
    return true
end

function get_member_info(self)
    local info = {}
    for _, A in pairs(self._members) do
        table.insert(info, A:get_union_info())
    end
    return info
end

function accept_apply(self, A, B)
    if not self:has_member(A) then return resmng.E_NO_UNION end
    if self:has_member(B) then return resmng.E_ALREADY_IN_UNION end
    if not is_legal(A, "Invite") or not is_legal(B, "Join") then
        return resmng.E_DISALLOWED
    end

    if not self:get_apply(B.pid) then return resmng.E_FAIL end

    self:remove_apply(B.pid)
    return self:add_member(B)
end

function remove_apply(self, pid)
    assert(pid)
    local idx = self:get_apply(pid)
    if idx then
        table.remove(self.applys, idx)
        local db = dbmng:getOne(self.pid)
        db.union:update({_id=self.uid},{["$pull"]={applys={pid=pid}} })
        return true
    end
    return false
end

function get_apply(self, pid)
    assert(pid)
    for index, apply in pairs(self.applys) do
        if pid == apply.pid then
            return index
        end
    end
end

function add_apply(self, B)
    assert(B)
    if self:has_member(B) then return end
    if self:get_apply(B.pid) then return end

    local data = {pid=B.pid, time=gTime}
    table.insert(self.applys, data)

    local db = dbmng:getOne(self.pid)
    db.union:update({_id=self.uid},{["$push"]={applys=data}})

    local data = B:get_union_info()
    data.rank = 0

    LOG("[Union] add_apply, pid:%s, uid:%s", B.pid, self.uid)
end

function reject_apply(self, A, B)
    if not self:has_member(A) then return resmng.E_NO_UNION end
    if not is_legal(A, "Invite") then return resmng.E_DISALLOWED end
    if self:remove_apply(B.pid) then
        self:broadcast("union_reject", B.pid)
        --self:notifyall("apply", resmng.OPERATOR.DELETE, B.pid)
        return resmng.E_OK
    else
        return resmng.E_FAIL
    end
end

function set_member_rank(self, A, B, r)
    if not self:has_member(A, B) then return resmng.E_FAIL end
    if not (resmng.UNION_RANK_1 <= r and r < resmng.UNION_RANK_5) then
        return resmng.E_DISALLOWED
    end

    if A:get_rank() > r then
        B:set_rank(r)
        LOG("[Union] set_rank, A:%s, B:%s, R:%s", A.pid, B.pid, r)
        self:notifyall("member", resmng.OPERATOR.UPDATE, B:get_union_info())
        return resmng.E_OK
    else
        return resmng.E_FAIL
    end
end

function set_member_mark(self, A, B, mark)
    if not self:has_member(A, B) then return resmng.E_FAIL end
    if not is_legal(A, "MemMark") or not (A:get_rank() > B:get_rank()) then
        return resmng.E_DISALLOWED
    end

    B:union_data().mark = mark
    self:notifyall("member", resmng.OPERATOR.UPDATE, A:get_union_info())
    return resmng.E_OK
end
--}}}

function is_legal(A, what)
    local conf = resmng.prop_union_power[A:get_rank()]
    if not conf then return false end
    if not conf[what] or conf[what] == 0 then return false end
    return true
end

--{{{ invite
function send_invite(self, A, B)
    if not is_legal(A, "Invite") then return resmng.E_DISALLOWED end
    if not self:has_member(A) then return resmng.E_NO_UNION end
    if self:has_member(B) then
        WARN("[Union]: sendInvite, already in union, player:%s", B.pid)
        return resmng.E_ALREADY_IN_UNION
    end

    --[[
    B:mailNew(
        A.pid, A.name, resmng.MailMode.UnionInvite,
        "invite title",
        "invite content",
        self.uid
    )
    --]]
    self:add_invite(B.pid)
    return resmng.E_OK
end

function accept_invite(self, B)
    if self:has_member(B) then
        WARN("[Union]: acceptInvite, already in Union, player:%s, union:%s", B.pid, self.uid)
        return resmng.E_ALREADY_IN_UNION
    end

    if self:is_invite_timeout(B.pid) then
        WARN("[Union]: acceptInvite, invite timeout, player:%s, union:%s", B.pid, self.uid)
        return resmng.E_TIMEOUT
    end
    self:remove_invite(B.pid)

    self:add_member(B)
end

function is_invite_timeout(self, pid)
    assert(pid)
    local index, invite = self:get_invite(pid)
    if not invite then
        return true
    end

    if os.time() - invite.tm < 24 * 3 * 60 * 60 then
        return false
    end

    return true
end

function remove_invite(self, pid)
    assert(pid)
    local db = dbmng:getOne()
    local index, invite = self:get_invite(pid)
    if invite then
        db.union:update( {_id=self.uid},{["$pull"]={invites={pid=pid}} })
        table.remove(self.invites, index)
    end
end

function add_invite(self, pid)
    assert(pid)
    local db = dbmng:getOne()

    local index, invite = self:get_invite(pid)
    if invite then
        invite.tm = os.time()
        db.union:update(
            {_id=self.uid,["invites.pid"]=invite.pid},
            {["invites.$.tm"]=invite.tm}
        )
    else
        invite = {tm=os.time(),pid=pid}
        table.insert(self.invites, invite)
        db.union:update( {_id=self.uid}, {["$push"]={invites=invite}})
    end
end
function get_invite(self, pid)
    for index, invite in pairs(self.invites) do
        if invite.pid == pid then
            return index, invite
        end
    end
end
---}}}

--{{{  broadcast
-- -----------------------------------------------------------------------------
-- Hx@2016-01-05 : use notifyall, merge all broadcast messages
-- Hx@2016-01-25 : 所有联盟广播合并到notifyall下，逐步移除broadcast api,
-- 联盟下非全联盟广播需要自己做
-- -----------------------------------------------------------------------------
function broadcast(self, protocol, ...)
    local pids = {}
    for _, p in pairs(self._members) do
        if p:isOnline() then
            table.insert(pids, p.pid)
        end
    end
    if #pids == 0 then return end
    Rpc[protocol](Rpc, pids, ...)
end

function notifyall(self, what, mode, data)
    local pids = {}
    for _, p in pairs(self._members) do
        if p:isOnline() then
            table.insert(pids, p.pid)
        end
    end
    if #pids == 0 then return end
    Rpc:union_broadcast(pids, what, mode, data)
end
---}}}

--{{{ mass
-- -----------------------------------------------------------------------------
-- Hx@2016-01-25 : mass合并到fight中，这部分重复的api慢慢去掉
-- -----------------------------------------------------------------------------
function mass_add(self, mass)
    self.mass[mass.idx] = mass
    local data = self:get_mass_simple_info(mass.idx)
    --self:broadcast_mass_state(data)
end

--[[
function mass_join(self, idx, At)
    troop_t.add_arm(self:get_mass(idx), At)
    self:mass_update(idx)
end
--]]

function get_mass_simple_info(self, idx)
    assert(idx, "idx,".. debug.stack())
    local mass = self:get_mass(idx)
    if not mass then return end

    local count = 0
    local troops = {}
    for _, tid in ipairs(mass.troops) do
        local t = troop_t.get_by_tid(tid)
        assert(t, string.format("tid:%s,%s",tid, debug.stack()))
        table.insert(troops, {pid=t.pid,state=t.state})
        count = count + troop_t.sum(t)
    end

    local state = 0
    if mass.state == resmng.TroopState.Wait then
        state = resmng.UNION_MASS_STATE.CREATE
    else
        state = resmng.UNION_MASS_STATE.FINISH
    end

    local data = {
        idx = idx,
        pid = mass.pid,
        aeid = mass.eid,
        deid = mass.did,
        tmStart = mass.tmStart,
        tmOver = mass.tmOver,
        max = mass.max,
        count = count,
        troops = troops,
        state = state,
    }

    return data
end

function mass_update(self, idx)
    local mass = self:get_mass(idx)

    local count = 0
    local troops = {}
    for _, tid in ipairs(mass.troops) do
        local t = troop_t.get_by_tid(tid)
        table.insert(troops, {pid=t.pid,state=t.state})
        count = count + troop_t.sum(t)
    end

    --[[
    local data = {
        mid = mass.idx,
        state = resmng.UNION_MASS_STATE.UPDATE,
        count = count,
        troops = troops,
    }
    self:broadcast_mass_state(data)
    --]]
end

function mass_cancel(self, A, idx)
    local mass = self:get_mass(idx)

    for _, tid in pairs(mass.troops) do
        local t = troop_t.get_by_tid(tid)
        local p = getPlayer(t.pid)
        --if mass.pid == t.pid then
        --    t.tmStart = gTime
        --    t.tmOver = gTime
        --    p:troop_home(t)
        --else
            if t.state == resmng.TroopState.Wait then
                p:troop_back(t)
            --else
                --p:troop_recall(t)
            end
        --end
    end

    local data = {
        idx = mass.idx,
        state = resmng.UNION_MASS_STATE.DESTORY,
    }

    --self:notifyall()
    --self:broadcast_mass_state(data)
    troop_t.del(mass)
    self.mass[idx] = nil
end

function mass_deny(self, idx, pid)

    --[[
    local mass = self:get_mass(idx)
    for i = #mass.troops, 1, -1 do
        local t = troop_t.get_by_tid(mass.troops[i])
        if t.pid == pid then
            local p = getPlayer(pid)
            p:troop_recall(t)
            --p:troop_back(t)
            table.remove(mass.troops, i)
            self:mass_update(idx)
            return
        end
    end
    --]]
end

function is_player_in_mass(self, idx, pid)
    for tid, _ in pairs(self.mass[idx].troops) do
        local val = string.split(tid, "_")
        if tonumber(val[1]) == pid then
            return true
        end
    end
    return false
end

function get_mass(self, idx)
    if not self.mass then self.mass = {} end
    return self.mass[idx]
end

function broadcast_mass_state(self, data)
    WARN("To Del ".. debug.stack())
    --self:broadcast("union_state_mass", data)
end

function do_timer_mass(self, tsn, idx)
    WARN("[ToDel] "..debug.stack())
    --[[
    --INFO("---------------- mass timer -------------------")
    local mass = self.mass[idx]
    if not mass then return WARN("do_timer_mass, mass not found") end
    if mass.tmSn ~= tsn then return end
    mass.tmSn = 0

    local union = unionmng.get_union(getPlayer(mass.pid):get_uid())

    if mass.state == resmng.TroopState.Wait then
        LOG("[Union] mass wait finish, troop:%s, player:%s", mass._id, mass.pid)
        local p = getPlayer(mass.pid)
        local tm, speed = p:getMarchTime(mass, mass.sx, mass.sy, mass.dx, mass.dy)
        mass.state = resmng.TroopState.Go
        mass.speed = speed
        mass.tmStart = gTime
        mass.tmOver = gTime + tm
        mass.tmSn = timer.new("mass", tm, self.uid, idx)
        troop_t.show(mass)

        for i = #mass.troops,1,-1 do
            local t = troop_t.get_by_tid(mass.troops[i])
            if t.state ~= resmng.TroopState.Wait then
                LOG("[Union] mass remove unarrive, troop:%s state:%s", t._id, t.state)
                table.remove(mass.troops, i)
           else
               t.sx = mass.sx
               t.sy = mass.sy
               t.dx = mass.dx
               t.dy = mass.dy
               t.tmStart = mass.tmStart
               t.tmOver = mass.tmOver
               t.speed = mass.speed
               t.state = mass.state
           end
        end
    elseif mass.state == resmng.TroopState.Go then
        LOG("[Union] mass go finish, troop:%s, player:%s", mass._id, mass.pid)
        troop_t.unshow(mass)

        local D = get_ety(mass.did)
        if D then
            local Dt = D:init_def_troop()
            if is_ply(mass.did) then
                fight.pvp("seige", mass, Dt)
            elseif is_monster(mass.did) then
                fight.pvp("jungle", mass, Dt)
            end
        end
    elseif mass.state == resmng.TroopState.Back then
        WARN("[Union] mass has no state: back")
    elseif mass.state == resmng.TroopState.Fight then
        union.mass[mass.idx] = nil
        mass:owner():troop_back(mass)
    else
        WARN("[Union] mass, unknown state:%s", mass.state)
    end
    --]]
end
--}}}

--{{{ tech & donate
function init_tech(self, idx)
    assert(self, debug.stack())
    if not self._tech[idx] then
        self._tech[idx] = union_tech_t.create(idx, self.uid)
    end
end

function get_tech(self, idx)
    self:init_tech(idx)
    return self._tech[idx]
end

function can_donate(self, idx)
    local tech = self:get_tech(idx)
    if tech and not tech:is_exp_full()
        and self:tech_cond_check(resmng.prop_union_tech[tech.id].Cond)
        and self:calc_tech() >= TechValidCond[union_tech_t.get_class(idx)] then
        return true
    else
        return false
    end
end

function add_donate(self, num)
    self.donate = self.donate + num
end

function calc_tech(self)
    local sum = 0
    for _, v in pairs(self._tech) do
        sum = sum + v:get_lv()
    end
    return sum
end

function set_tech_mark(self, mark)
    if tabNum(mark) > 2 then return E_FAIL end
    for idx, _ in pairs(mark) do
        if not self:get_tech(tonumber(idx)) then
            return resmng.E_FAIL
        end
    end
    self.tech_mark = mark
    return resmng.E_OK
end

function get_tech_mark(self)
    return self.tech_mark
end

-- Hx@2015-12-23 :
-- 1.use tmOver to set the upgrade time and to identify is in upgrade progress
-- 2.clear tmOver when update finished
function upgrade_tech(self, idx)
    local tech = self:get_tech(idx)
    if not tech or not tech:is_exp_full() then
        return resmng.E_FAIL
    end

    local next_conf = resmng.prop_union_tech[tech.id + 1]
    if not next_conf then
        return resmng.E_MAX_LV
    end

    if tech.tmOver ~= 0 then
        return resmng.E_FAIL
    end

    local tm = resmng.prop_union_tech[tech.id].TmLevelUp
    tech.tmStart = gTime
    tech.tmOver = gTime + tm
    tech.tmSn = timer.new("uniontech", tm, self.uid, idx)

    self:broadcast("union_tech_update", {
        idx=tech.idx,id=tech.id,tmStart=tech.tmStart, tmOver=tech.tmOver
    })

    return resmng.E_OK
end

function do_timer_tech(self, tsn, idx)
    local tech = self:get_tech(idx)
    if not tech then
        WARN("timer got no tech") return
    end

    local conf = resmng.prop_union_tech[tech.id]
    local next_conf = resmng.prop_union_tech[tech.id + 1]

    tech.id = next_conf.ID
    tech.exp = tech.exp - conf.Exp * conf.Star
    tech.tmSn = 0
    tech.tmStart = 0
    tech.tmOver = 0

    self:broadcast("union_tech_update", {
        idx=tech.idx,id=tech.id,exp=tech.exp,tmOver=tech.tmOver,tmStart=tech.tmStart
    })
end

function get_donate_rank(self, what)
    if not self.donate_rank[what] then
        local result = {}
        for _, v in pairs(self._members) do
            table.insert(result, {
                pid=v.pid,
                name=v.name,
                photo=v.photo,
                rank = v:get_rank(),
                donate = v:union_data().donate_data[what],
                techexp = v:union_data().techexp_data[what],
            })
        end
        table.sort(result, function(l, r)
            if l.techexp == r.techexp then
                if l.donate == r.donate then
                    if l.rank == r.rank then
                        --TODO: figt capacity
                        return true
                    else
                        return l.rank > r.rank
                    end
                else
                    return l.donate > r.donate
                end
            else
                return l.techexp > r.techexp
            end
        end)
        self.donate_rank[what] = result
    end
    return self.donate_rank[what]
end

function donate_summary_day(self)
    for _, A in pairs(self._members) do
        A:union_data():clear_donate_data(resmng.DONATE_RANKING_TYPE.DAY)
    end
end

function donate_summary_week(self)
    local rank = self:get_donate_rank(resmng.DONATE_RANKING_TYPE.WEEK)
    --TODO reward
    for _, A in pairs(self._members) do
        A:union_data():clear_donate_data(resmng.DONATE_RANKING_TYPE.WEEK)
    end
end

function tech_cond_check(self, cond)
    function do_cond_check(self, class, mode, ...)
        if class == "or" then
            for _, v in pairs({mode, lv, ...}) do
                if do_cond_check(unpack(v)) then return true end
            end
            return false
        elseif class == "and" then
            for _, v in pairs({mode, lv, ...}) do
                if not do_cond_check(unpack(v)) then return false end
            end
            return true
        elseif class == resmng.CLASS_UNION_TECH then
            local id = mode
            local conf = resmng.prop_union_tech[id]
            local tech = self:get_tech(conf.Idx)
            if conf and tech and tech.lv >= conf.Lv then
                return true
            end
        end
    end

    if cond then
        for _, v in pairs(cond) do
            if not do_cond_check(unpack(v)) then return false end
        end
    end
    return true
end

function get_tech_ef(self)
    if not self._tech_ef then
        local ef = {}
        for _, tech in pairs(self._tech) do
            local conf = resmng.prop_union_tech[tech.id]
            for k, v in pairs(conf.Effect) do
                ef[k] = (ef[k] or 0) + v
            end
        end
        self._tech_ef = ef
    end
    return self._tech_ef
end

--}}}

--{{{ log
-- -----------------------------------------------------------------------------
-- Hx@2016-01-29: log 需要使用gDayStart
-- 服务器重启时gDayStart 的初始化点貌似在拉数据之后导致异常??
-- -----------------------------------------------------------------------------

function add_log(self, mode, data)
    LOG("[Union] add log, union:%s, mode:%s", self._id, mode)

    local sn = getId("unionlog")
    self.log_csn = sn
    local log = {
        sn = sn,
        tm = gTime,
        mode = mode,
        data = data,
    }

    local len = #self.log
    for i = #self.log, 1, -1 do
        if self.log[i].tm < (gDayStart or gTime) - 2592000 then
            table.remove(self.log, i)
        end
    end
    if #self.log > 1000 then
        for i = #self.log, 500, -1 do
            table.remove(self.log, i)
        end
    end
    if len ~= #self.log then
        local db = dbmng:getOne()
        db.union_log:update({_id=self._id}, {
            ["$pull"]={log={
                sn={["$lt"]=self.log[#self.log].sn}
            }}
        })
    end


    local db = dbmng:getOne()
    db.union_log:update({_id=self._id}, {["$addToSet"]={log=log}})

    table.insert(self.log, 1, log)
end

local function log_qfind(t, sn)
    local function qfind(l, r)
        local k = math.floor((l + r) / 2)
        --print(l, k, r, sn, t[k].sn)
        if l > r then
            return nil
        elseif sn > t[k].sn then
            return qfind(l, k)
        elseif sn < t[k].sn then
            return qfind(k + 1, r)
        elseif sn == t[k].sn then
            return k
        end
    end
    return qfind(1, #t)
end

function get_log_by_mode(self, mode, sn)
    function check_mode(mode)
        for _, v in pairs(resmng.EventMode) do
            if v == mode then return true end
        end
        return false
    end

    local result = {}
    if not check_mode(mode) then return {} end
    if #self.log == 0 then return result end

    local idx = 0
    if sn ~= 0 then
        idx = log_qfind(self.log, sn)
        if not idx then return result end
    end

    while idx < #self.log do
        idx = idx + 1

        local log = self.log[idx]
        if log and log.mode == mode then
            if #result >= 20 then break end
            table.insert(result, log)
        end
    end
    return result
end

function set_note_in(self,pid,what)
    self.note_in = what
    local p = getPlayer(pid)
    self:add_log(resmng.EVENT_TYPE.SET_NOTE_IN, {name=p.account})
end

function get_log_by_sn(self, sn)
    local result = {}
    if #self.log == 0 then return result end

    local csn = sn
    if csn == 0 then
        csn = self.log_csn
    end

    local idx = 0
    if sn and sn ~= 0 then
        idx = log_qfind(self.log, sn)
        if not idx then return result end
    end

    while idx < #self.log  do
        idx = idx + 1
        local log = self.log[idx]
        if log then
            if #result >= 20 then break end
            table.insert(result, log)
        end
    end
    return result
end

--}}}

--{{{
-- -----------------------------------------------------------------------------
-- Hx@2016-01-25 : 联盟战争推送
-- 利用troop的脏检查监控字段的变化来实现，比使用在api中插入update更简洁
-- -----------------------------------------------------------------------------
function enroll_fight(self, troop, chgs)
    if troop.action == resmng.TroopAction.Seige then
        if is_ply(troop.aid) and is_ply(troop.did) then
            if not self._fight[troop._id]
                and (troop.state == resmng.TroopState.Wait or troop.state == resmng.TroopState.Go) then
                self._fight[troop._id] = troop
                LOG("[Union] fight add: %s", troop._id)
                --self:notifyall("fight", resmng.OPERATOR.ADD, get_fight_info(troop))
            elseif self._fight[troop._id] then
                if troop.state == resmng.TroopState.Back then
                    self._fight[troop._id] = nil
                    LOG("[Union] fight del: %s", troop._id)
                 --   self:notifyall("fight", resmng.OPERATOR.DELETE, {id=troop.idx})
                else
                    LOG("[Union] fight update: %s", troop._id)
                  --  self:notifyall("fight", resmng.OPERATOR.UPDATE, {id=troop.idx, T=chgs})
                end
            end
        end
    end

    -- Hx@2016-01-26: 集结变化
    -- 集结变化时所有参与者都能知道
    -- 玩家能确定自己是否为集结发起者
    -- TODO:集结的目标援助发生变化时能攻击方能知道
    if troop.action == resmng.TroopAction.Mass then
        if not self._fight[troop._id] then
            self._fight[troop._id] = troop
            LOG("[Union] fight add: %s", troop._id)
            --self:notifyall("fight", resmng.OPERATOR.ADD, get_fight_info(troop))
        elseif self._fight[troop._id] then
            if troop.state == resmng.TroopState.Back then
                self._fight[troop._id] = nil
                LOG("[Union] fight del: %s", troop._id)
             --   self:notifyall("fight", resmng.OPERATOR.DELETE, {id=troop.idx})
            else
                local data = {
                    id = troop.idx,
                    T = {
                        action = chgs.action,
                        state = chgs.state,
                        tmStart = chgs.tmStart,
                        tmOver = chgs.tmOver,
                        eid = chgs.eid,
                        did = chgs.did,
                        sx = chgs.sx,
                        sy = chgs.sy,
                        dx = chgs.dx,
                        dy = chgs.dy,
                    },
                }
                if chgs.troops then
                    data.A = troop_t.get_by_tid(troop._id):atk_general(5)
                    data.As = {
                        total = #troop.troops
                    }
                end

                LOG("[Union] fight update: %s", troop._id)
                room.troop_broadcast(troop,"fight", resmng.OPERATOR.UPDATE)
            end
        end
    end
end

function get_fight_info(troop)
    local xs = {
        id = troop.idx,
        A = troop:atk_general(5),
        D = troop:def_general(5),
        As = {
            total = #troop.troops
        },
        Ds = {
            total = #(troop:owner().aid) + 1
        },
    }

    local Au = troop:owner():union()
    if Au then
        xs.Au = {uid=Au.uid,alias=Au.alias,flag=Au.flag}
    end
    local D = get_ety(troop.did)
    if is_ply(D.eid) then
        xs.Dc = {cival=D.cival}
        local Du = D:union()
        if Du then
            xs.Du = {uid=Du.uid,alias=Du.alias,flag=Du.flag}
        end
    end

    xs.T = {
        action = troop.action,
        state = troop.state,
        tmStart = troop.tmStart,
        tmOver = troop.tmOver,
        eid = troop.eid,
        did = troop.did,
        sx = troop.sx,
        sy = troop.sy,
        dx = troop.dx,
        dy = troop.dy,
        idx = troop.idx,
    }

    return xs
end

--[[
function add_fight_log(self, T)
    if is_ply(T.aid) and is_ply(T.did) then
        local A = get_ety(T.aid)
        local D = get_ety(T.did)

        local log = {
            action = T.action,
            win = T.win or 0,
            A = {
                pid = A.pid,
                name = A.name,
                x = T.sx,
                y = T.sy,
            },
            D = {
                pid = D.pid,
                name = D.name,
                x = T.dx,
                y = T.dy,
            }
        }

        self:add_log(EVENT_TYPE.FIGHT, log)
    end
end
--]]

--}}}

--{{{ build

function init_buildlv(self, class)
    if not self.buildlv[class] then
        local conf = union_build_t.get_buildlv_conf(class, 1)
        if not conf then return end
        local data = {
            class = class,
            id = conf.ID,
            stage = 1,
            exp = 0,
        }
        self.buildlv[data.class] = data
    end
end

function check_buildlv_cond(self, cond)
    function check(self, class, mode, ...)
        if class == resmng.CLASS_UNION_BUILLDLV then
            local cc = resmng.prop_union_buildlv[mode]
            local lv = self:get_buildlv(lvcc.class)
            local lvcc = resmng.prop_union_buildlv[lv.class]


        else
        end
    end
    if cond then
        for _, v in pairs(cond) do
            if not check(unpack(v)) then return false end
        end
    end
    return true
end

function can_buildlv_donate(self, class)
    local lv = self:get_buildlv(class)
    if not lv then return false end

    local nc = resmng.prop_union_buildlv[lv.id + 1]
    if not nc then return false end

    return true
end

function get_buildlv(self, class)
    self:init_buildlv(class)
    return self.buildlv[class]
end

function add_buildlv_donate(self, class)
    if not self:can_buildlv_donate(class) then return false end

    local lv = self:get_buildlv(class)
    local cc = resmng.prop_union_buildlv[lv.id]

    --if lv.exp + cc.donate[lv.stage] >= cc.id then
    lv.exp = lv.exp + 300
    if lv.exp >= cc.Cons[lv.stage][2] then
        lv.stage = lv.stage + 1
        lv.exp = 0
        if lv.stage > #cc.Cons then
            local nc = resmng.prop_union_buildlv[lv.id + 1]
            lv.id = nc.ID
            lv.stage = 1
        end
        self:notifyall("buildlv", resmng.OPERATOR.UPDATE, lv)
    end

    --self.buildlv = self.buildlv
    return true
end

function get_build_count(self, Mode)
    local count = 0
    for _, v in pairs(self.build) do
        local cc = resmng.prop_world_unit[v.propid]
        if cc.Mode == Mode then
            count = count + 1
        end
    end
    return count
end
-- -----------------------------------------------------------------------------
-- Hx@2016-01-26 : 是否在联盟领地
-- 奇迹&小奇迹
-- AnchorPoint(0,0)
-- -----------------------------------------------------------------------------
function is_in_territory(self, x, y, size)
    for _, v in pairs(self.build) do
        local cc = resmng.prop_world_unit[v.propid]
        if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE
            or cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
            if v.x - cc.Range <= x and x <= v.x + cc.Range - size
                and v.y - cc.Range <= y and y <= v.y + cc.Range - size then
                return true
            end
        end
    end
    return false
end

function can_castle(self, bcc)  --在奇迹有效范围内

    if bcc.Mode ~= resmng.CLASS_UNION_BUILD_CASTLE and bcc.Mode ~= resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        for _, v in pairs(self.build or {} ) do
            local cc = resmng.prop_world_unit[v.propid]
            if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE and cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
                local c_x = cc.x - cc.range
                local c_y = cc.y - cc.range
                local s = 2*cc.range + cc.Size
                if (bcc.x >=c_x and bcc.x<=c_x+s-bcc.Size) and (bcc.y>=c_y and bcc.y<=c_y+s-bcc.Size)then
                    return true
                end
            end
        end
        return false
    end

    return true

end

function can_build(self, id)
    local bcc = resmng.prop_world_unit[id]
    if not bcc then return false end

    if not self:can_castle(bcc) then
        ack(self, "can_build", resmng.E_DISALLOWED,0)
        return false
    end

    if bcc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        --小奇迹数量限制
        local blv = self:get_buildlv(resmng.CLASS_UNION_BUILD_CASTLE)
        if not blv then return false end
        local conf = resmng.prop_union_buildlv[blv.id]
        if self:get_build_count(bcc.Mode) >= conf.Lv then
            ack(self, "can_build", resmng.E_DISALLOWED,0)
            return false
        end
        return true
    end

    local lv = self:get_buildlv(bcc.Mode)
    if not lv then
        ack(self, "can_build", resmng.E_DISALLOWED,0)
        return false
    end
    local lvcc = resmng.prop_union_buildlv[lv.id]
    if not lvcc then
        ack(self, "can_build", resmng.E_DISALLOWED,0)
        return false
    end
    --等级
    if lvcc.Lv ~= bcc.Lv then
        ack(self, "can_build", resmng.E_DISALLOWED,0)
        return false
    end
    --数量
    if self:get_build_count(bcc.Mode) >= lvcc.Num then return false end

    if bcc.Mode == resmng.CLASS_UNION_BUILD_MINE or resmng.CLASS_UNION_BUILD_FARM or CLASS_UNION_BUILD_LOGGINGCAMP or CLASS_UNION_BUILD_QUARRY then
        --超级矿排他
        for _, v in pairs(self.build) do
            local cc = resmng.prop_union_buildlv[v.id]
            if cc.Mode ~= bcc.Mode then
                ack(self, "can_build", resmng.E_DISALLOWED,0)
                return false
            end
        end
    end
    return true
end


function remove_build(self, idx)
    if not self.build[idx] then return end
    c_rem_ety(self.build[idx].eid)
	gEtys[self.build[idx].eid] = nil

    self.build[idx].state = BUILD_STATE.DESTORY

    self:notifyall("build", resmng.OPERATOR.DELETE, {idx=idx})
end

function refresh_builds(self)
    for _, v in pairs(self.build) do
        v.ef = nil
    end
end

function valid_build(self, class,mode)
    if not class then return end
    local blv = self:get_buildlv(class)
    if not blv then return end
    local lvcc = resmng.prop_union_buildlv[blv.id]
    if not lvcc then return end

    for _, v in pairs(resmng.prop_world_unit) do
        if v.Class == lvcc.Class and mode == v.Mode and v.Lv == lvcc.Lv then
            return v.ID
        end
    end
    return nil
end

function upgrade_build(self, A, idx)
    local b = self.build[idx]
    if not b then
        WARN("[Union] build upgrade, not found, idx:%s", idx)
        return resmng.E_FAIL
    end
    local id = self:valid_build(b:get_class())
    if not id then
        WARN("[Union] build upgrade, valid id nil")
        return resmng.E_FAIL
    end

    if not is_legal(A, "BuildUp") or id == b.id then
        return resmng.E_DISALLOWED
    end

    local cc = resmng.prop_world_unit[b.propid]
    local nxtcc = resmng.prop_world_unit[id]
    local tm = nxtcc.Dura - cc.Dura

    b.state = BUILD_STATE.UPGRADE
    b.tmStart = gTime
    b.tmOver = gTime + tm
    b.tmSn = timer.new("unionbuild", tm, b._id)
    LOG("[Union] build upgrade, _id:%s, tm:%s, player:%s", b._id, tm, A.pid)
    return resmng.E_OK
end

function marcket_add(self, pid,res )--上架特产

    if not self.marcket then self.marcket={ } end
    local f = 0
    for _, v in pairs(self.marcket  ) do
        for k, vv in pairs(res) do
            v.res[k] = (v.res[k] or 0 ) + vv
        end 
        f =1
    end

    if f ==0 then
        table.insert(self.marcket,{pid=pid,res=res})
    end
    dbmng:getOne().union:update({_id=self._id}, { ["$set"]={marcket=self.restore}})
end

function restore_add_res(self, pid,res )--存储资源

    if not self.restore then self.restore={ sum={},day={}} end
    local f = 0
    for _, v in pairs(self.restore.sum  ) do
        if v.pid == pid then
            for k, vv in pairs(res) do
                v.res[k] = (v.res[k] or 0 ) + vv
            end 
            f =1
        end
    end
    if f ==0 then
        table.insert(self.restore.sum,{pid=pid,res=res})
    end

    f=0
    for _, v in pairs(self.restore.day ) do
        if v.pid == pid then
            if os.date("%d",gTime)~=os.date("%d",v.time) then
                v.num = 0
            end
            v.num = (res[resmng.DEF_RES_FOOD] or 0 )* resmng.prop_resource[resmng.DEF_RES_FOOD].Mul + v.num
            v.num = (res[resmng.DEF_RES_WOOD] or 0 )* resmng.prop_resource[resmng.DEF_RES_WOOD].Mul + v.num
            v.num = (res[resmng.DEF_RES_IRON] or 0 )* resmng.prop_resource[resmng.DEF_RES_IRON].Mul+ v.num
            v.num = (res[resmng.DEF_RES_ENERGY] or 0 )*resmng.prop_resource[resmng.DEF_RES_ENERGY].Mul+ v.num
            v.time = gTime
            f=1
        end
    end

    if f==0 then
        local num = (res[resmng.DEF_RES_FOOD] or 0 )*resmng.prop_resource[resmng.DEF_RES_FOOD].Mul
        num = (res[resmng.DEF_RES_WOOD] or 0 )* resmng.prop_resource[resmng.DEF_RES_WOOD].Mul+ num
        num = (res[resmng.DEF_RES_IRON] or 0 )* resmng.prop_resource[resmng.DEF_RES_IRON].Mul+ num
        num = (res[resmng.DEF_RES_ENERGY] or 0 )* resmng.prop_resource[resmng.DEF_RES_ENERGY].Mul+ num
        table.insert(self.restore.day,{pid=pid,num=num,time=gTime})
    end

    dbmng:getOne().union:update({_id=self._id}, { ["$set"]={restore=self.restore}})
end

function get_res_day(self, pid )--计算当天已存储量
    if not self.restore then return 0  end
    for _, v in pairs(self.restore.day or {}) do
        if v.pid == pid then
            return v.num
        end
    end
    return 0
end

function get_res_count(self, pid )--计算总存储量
    if not self.restore then return 0  end
    for _, v in pairs(self.restore.sum or {}) do
        if v.pid == pid then
            local sum = (v.res[resmng.DEF_RES_FOOD] or 0 )* resmng.prop_resource[resmng.DEF_RES_FOOD].Mul
            local sum = sum + (v.res[resmng.DEF_RES_WOOD] or 0 )* resmng.prop_resource[resmng.DEF_RES_WOOD].Mul
            sum = sum + (v.res[resmng.DEF_RES_IRON] or 0 )* resmng.prop_resource[resmng.DEF_RES_IRON].Mul
            sum = sum + (v.res[resmng.DEF_RES_ENERGY] or 0 )*resmng.prop_resource[resmng.DEF_RES_ENERGY].Mul
            return sum
        end
    end
    return 0
end

function can_res(self,pid,r)--能否取出资源
    if not self.restore then return false  end
    for _, v in pairs(self.restore.sum or {}) do
        if v.pid == pid then
            for i = 1, #r do
                if not v.res[i] and r[i] > res [i] then
                    return false
                end
            end
            return true
        end
    end
    return false
end


function restore_del_res(self, pid,res )--取出资源
    if not self.restore then return false  end
    for _, v in pairs(self.restore.sum or {}) do
        if v.pid == pid then
            if not self:can_res(pid,res) then
                return false
            end
            for i = 1, #res do
                v.res[i] = v.res[i] - res[i]
            end
        end
    end
    dbmng:getOne().union:update({_id=self._id}, { ["$set"]={restore=self.restore}})
    return true
end

function get_build(self, idx )
    if idx then
	    return self.build[idx]
    else
	    return self.build
    end
end


function get_build_ef(self, x, y, size)
    if not self:is_in_territory(x, y, size) then return {} end
    for _, v in pairs(self.build) do
        local cc = resmng.prop_world_unit[v.propid]
        if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE then
           return copyTab(cc.Buff)
        end
    end
    return {}
end
--}}}
