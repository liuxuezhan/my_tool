module("player_t")

--{{{ create & destory
function union_load(self, what)
    local union = unionmng.get_union(self:get_uid())
    local result = {
        key = what,
        val = {},
    }
    if not union then
        --nil
    elseif what == "info" then
        result.val = union:get_info()
    elseif what == "member" then
        result.val = union:get_member_info()
    elseif what == "apply" then
        local info = {}
        if union_t.is_legal(self, "Invite") then
            for _, apply in pairs(union.applys) do
                local A  = getPlayer(apply.pid)
                local data = A:get_union_info()
                data.rank = 0
                table.insert(info, data)
            end
        end
        result.val = info
    elseif what == "mass" then
        local info = {}
        for idx, _ in pairs(union.mass or {}) do
            table.insert(info, union:get_mass_simple_info(idx))
        end
        result.val = info
    elseif what == "tech" then
        local info = {}
        for _, t in pairs(union._tech) do
           table.insert(info, t:get_pro())
        end
        result.val = {info=info, mark=union.tech_mark}
    elseif what == "donate" then
        result.val = {tmOver=self._union.tmDonate, flag=self._union:get_donate_flag()}
    elseif what == "aid" then
        for _, At in ipairs(self.aid) do
            table.insert(result.val, At._pro)
        end
    elseif what == "fight" then
        room.load_fight(result,self.pid)
       --[[
        result.val = {}
        for _, t in pairs(union._fight) do
            table.insert(result.val, union_t.get_fight_info(t))
        end
        --]]
    elseif what == "buildlv" then
        for _, v in pairs(union.buildlv) do
            table.insert(result.val, v)
        end
    elseif what == "build" then
        for _, v in pairs(union.build) do
            table.insert(result.val, v._pro)
        end
    end

    result.val = result.val or {}
    Rpc:union_load(self, result)
end

function union_create(self, name, alias, language, mars)
    if not union_t.is_legal(self, "Create") then
        ack(self, "union_create", resmng.E_DISALLOWED) return
    end
    if self.rmb < 2000 then
        ack(self, "union_create", resmng.E_NO_RMB) return
    end
    self:doUpdateRes(resmng.DEF_RES_RMB, 2000, VALUE_CHANGE_REASON.UNION_CREATE)
    local union = union_t.create(self, name, alias, language, mars)
    Rpc:union_on_create(self, union:get_info())
end

function union_destory(self)
    local tr = self:get_troop() or {}
    if next(tr) then
       ack(self, "union_destory", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(self, "Destory") then
        ack(self, "union_destory", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_destory", resmng.E_NO_UNION) return
    end

    unionmng.rm_union(u)
end
--}}}

--{{{ basic info
function union_set_info(self, info)
    local u = self:union()
    if not u then return end

    --TODO: 敏感词检查，长度检查，唯一性检查
    if union_t.is_legal(self, "ChgName") and info.name then
        u.name = info.name
    end
    if union_t.is_legal(self, "ChgAlias") and info.alias then
        u.alias = info.alias
    end
    if union_t.is_legal(self, "ChgFlag") and info.flag then
        --TODO: 扣钱
        u.flag = info.flag
    end
    if union_t.is_legal(self, "ChgRankAlias") and info.rank_alias then
        u.rank_alias = info.rank_alias
    end
    if union_t.is_legal(self, "ChgFlag") and info.language then
        u.language = info.language
    end

    ack(self, "union_set_info", resmng.E_OK)
end
--}}}

--{{{ member
function union_rm_member(self, pid)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_rm_member", resmng.E_NO_PLAYER) return
    end

    local tr = B:get_troop() or {}
    if next(tr) then
       ack(self, "union_rm_member", resmng.E_DISALLOWED) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_rm_member", resmng.E_NO_UNION) return
    end

    local ret = union:kick(self, B)
    if ret ~= resmng.E_OK then ack(self, "union_rm_member", ret) end
end

function union_add_member(self, pid)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_add_member", resmng.E_NO_PLAYER) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_add_member", resmng.E_NO_UNION) return
    end

    local ret = union:accept_apply(self, B)
    if ret ~= resmng.E_OK then ack(self, "union_add_member", ret) end
end

function union_apply(self, uid)
    local tr = self:get_troop() or {}
    if next(tr) then
       ack(self, "union_apply", resmng.E_DISALLOWED) return
    end

    local old_union = unionmng.get_union(self:get_uid())
    if old_union and not union_t.is_legal(self, "Join") then
       ack(self, "union_apply", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(uid)
    if not u then
        ack(self, "union_apply", resmng.E_NO_UNION) return
    end

    u:add_apply(self)

    if u:get_apply(self.pid) then
        Rpc:union_reply(self, u.uid, resmng.UNION_STATE.APPLYING)
    elseif u:has_member(self) then
        Rpc:union_reply(self, u.uid, resmng.UNION_STATE.IN_UNION)
    end
end

function union_quit(self)
    local tr = self:get_troop() or {}
    if next(tr) then
       ack(self, "union_quit", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then return end
    local ret = u:quit(self)
    ack(self, "union_quit", ret)
end

function union_reject(self, pid)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_reject", resmng.E_NO_PLAYER) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_reject", resmng.E_NO_UNION) return
    end

    local ret = union:reject_apply(self, B)
    if ret == resmng.E_OK then
        Rpc:union_reply(B, self.uid, resmng.UNION_STATE.NONE)
    end
    ack(self, "union_reject", ret)
end

function union_list(self)
    local data = {}
    for _, union in pairs(unionmng.get_all()) do
        local info = union:get_info()
        info.state = resmng.UNION_STATE.NONE
        if info.uid == self:get_uid() then
            info.state = resmng.UNION_STATE.IN_UNION
        elseif union:get_apply(self.pid) then
            info.state = resmng.UNION_STATE.APPLYING
        end
        table.insert(data,info)
    end
    Rpc:union_list(self, data)
end

function union_invite(self, pid)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_invite", resmng.E_NO_PLAYER) return
    end
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_invite", resmng.E_NO_UNION) return
    end

    local ret = union:send_invite(self, B)
    ack(self, "union_invite", ret)
end

function union_accept_invite(self, uid)
    local tr = self:get_troop() or {}
    if next(tr) then
       ack(self, "union_accept_invite", resmng.E_DISALLOWED) return
    end

    local union = unionmng.get_union(uid)
    if not union then
        ack(self, "union_accept_invite", resmng.E_NO_UNION) return
    end
    local ret = union:accept_invite(self)
    if ret ~= E_OK then
        ack(self, "union_accept_invite", ret) return
    end

    union:broadcast("union_add_member", self:get_union_info())
end

function union_member_rank(self, pid, r)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_member_rank", resmng.E_NO_PLAYER) return
    end
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_member_rank", resmng.E_NO_UNION) return
    end
    local ret = u:set_member_rank(self, B, r)
    ack(self, "union_member_rank", ret)
end

function union_leader_update(self, pid)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_leader_update", resmng.E_NO_PLAYER) return
    end
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_leader_update", resmng.E_NO_UNION) return
    end

    u.leader = pid
    local ret = u:set_member_rank(self, B, 5)
    ack(self, "union_lead_update", ret)
    local ret = u:set_member_rank(B, self,1)
    ack(self, "union_lead_update", ret)
end

function union_member_mark(self, pid, mark)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_member_mark", resmng.E_NO_PLAYER) return
    end
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_member_mark", resmng.E_NO_UNION) return
    end

    local ret = u:set_member_mark(self, B, mark)
    ack(self, "union_member_mark", ret)
end
--}}}

--{{{ mass


--}}}

--{{{ aid
function add_aid(self, At)
    table.insert(self.aid, At)

    --Rpc:union_state_aid(self, {At._pro})
end

function rm_aid(self, pid)
    for i = #self.aid, 1, -1 do
        local At = self.aid[i]
        if At.pid == pid then
            local p = getPlayer(pid)
            p:troop_back(At)
            --Rpc:union_state_aid(self, {At._pro})
            table.remove(self.aid, i)
            return
        end
    end
    ack(self, "rm_aid", resmng.E_NO_TROOP)
end

function get_aid(self, pid)
    for _, At in pairs(self.aid) do
        if At.pid == pid then
            return At
        end
    end
    return nil
end

function union_aid_count(self, pid)
    local data = { pid = pid, }
    local A = getPlayer(pid)
    if A then
        data.max = A:get_max_aid()
        data.cur = A:get_aid_count()
    end
    Rpc:union_aid_count(self, data)
end

function get_aid_count(self)
    local count = 0
    for _, At in pairs(self.aid) do
        count = count + troop_t.sum(At)
    end
    return count
end

function get_max_aid(self)
    --TODO: get right num
    return 5000
    --return self:getPropValue("MaxAid")
end




--}}}

--{{{ tech & donate
function union_tech_info(self, idx)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_info", resmng.E_NO_UNION) return
    end
    local tech = union:get_tech(idx)
    local donate = self._union:get_donate_cache(idx)
    Rpc:union_tech_info(self, {
        idx = tech.idx,
        id = tech.id,
        exp = tech.exp,
        tmOver = tech.tmOver,
        tmStart = tech.tmStart,
        donate = donate,
    })
end

function union_tech_mark(self, info)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_mark", resmng.E_NO_UNION) return
    end
    local ret = union:set_tech_mark(info)
    ack(self, "union_tech_mark", ret)
end

function union_donate(self, idx, dt)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_donate", resmng.E_NO_UNION) return
    end
    local tech = union:get_tech(idx)
    if not tech then
        ack(self, "union_donate", resmng.E_FAIL) return
    end

    if not resmng.prop_union_tech[tech.id + 1] then
        ack(self, "union_donate", resmng.E_NO_UNION) return
    end

    local conf = resmng.prop_union_donate[union_tech_t.get_class(tech.idx)]
    if not conf then
        ack(self, "union_donate", resmng.E_FAIL) return
    end

    if self._union:get_donate_flag() == 1 then
        ack(self, "union_donate", resmng.E_TIMEOUT) return
    end

    --[[ test
    if gTime - self._union.tmJoin < 14400 then
        ack(self, "union_donate", resmng.E_DISALLOWED) return
    end
    --]]

    local donate = self._union:get_donate_cache(idx)
    if donate[dt] == 0 then
        ack(self, "union_donate", resmng.E_FAIL) return
    end

    if not union:can_donate(idx) then
        ack(self, "union_donate", resmng.E_DISALLOWED) return
    end

    local cost = nil
    local reward = nil
    if dt == resmng.TECH_DONATE_TYPE.PRIMARY then
        cost = conf.Primary[donate[dt]]
        reward = conf.Pincome
    elseif dt == resmng.TECH_DONATE_TYPE.MEDIUM then
        cost = conf.Medium[donate[dt]]
        reward = conf.Mincome
    elseif dt == resmng.TECH_DONATE_TYPE.SENIOR then
        cost = conf.Senior[donate[dt]]
        reward = conf.Sincome
    end
    if not cost or not reward then
        ack(self, "union_donate", resmng.E_FAIL) return
    end
    self:doUpdateRes(cost[1], cost[2], VALUE_CHANGE_REASON.UNION_DONATE)

    local d = self:union_data()
    d:add_donate(reward[1])
    union:add_donate(reward[2])
    d:add_techexp(reward[3])
    tech:add_exp(reward[3])

    union.donate_rank = {}
    d:add_donate_cooldown(conf.TmAdd)
    d:fresh_donate_cache(idx, dt)

    self:union_tech_info(idx)
    Rpc:union_donate_info(self, {tmOver=self._union.tmDonate,flag=self._union:get_donate_flag()})
    ack(self, "union_donate", resmng.E_OK)
end

function union_tech_upgrade(self, idx)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_upgrade", resmng.E_NO_UNION) return
    end

    if not union_t.is_legal(self, "TechUp") then
        ack(self, "union_tech_upgrade", resmng.E_DISALLOWED) return
    end

    local ret = union:upgrade_tech(idx)
    ack(self, "union_tech_upgrade", ret)
end

function union_donate_rank(self, what)
    local u = unionmng.get_union(self:get_uid())
    if not u then return end
    local result = { what = what, val = {} }
    local rank = u:get_donate_rank(what)
    result.val = rank
    Rpc:union_donate_rank(self, result)
end

--}}}

--{{{ log
function union_log(self, sn, mode)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_upgrade", resmng.E_NO_UNION) return
    end

    local result = {
        mode = mode,
        sn = sn,
        val = {},
    }
    if mode and mode ~= 0 then
        result.val = union:get_log_by_mode(mode, sn)
    else
        result.val = union:get_log_by_sn(sn)
    end
    Rpc:union_log(self, result)
end
--}}}

function union_set_note_in(self, what)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_upgrade", resmng.E_NO_UNION) return
    end

    if not union_t.is_legal(self, "SetNoteIn") then
        ack(self, "set_note_in no rank", resmng.E_DISALLOWED) return
    end
    union:set_note_in(self.pid,what)
end
--{{{ build
function union_build_donate(self, class)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_build_donate", resmng.E_NO_UNION) return
    end

    if not union:add_buildlv_donate(class) then
        ack(self, "union_build_donate", resmng.E_FAIL) return
    else
        Rpc:union_build_donate(self, union:get_buildlv(class))
    end
end

function union_build_setup(self, idx,propid, x, y)
    local u = self:union()
    if not u then
        ack(self, "union_build_setup no union", resmng.E_NO_UNION) return
    end

    if not union_t.is_legal(self, "BuildPlace") then
        ack(self, "union_build_setup no rank", resmng.E_DISALLOWED) return
    end

    union_build_t.create(self.uid, idx, propid, x, y)
end

function union_build_remove(self, idx)
    local u = self:union()
    if not u then return end

    local bcc = resmng.prop_world_unit[u.build[idx].propid]
    if not bcc then return false end

    local ret = u:remove_build(idx)

--拆除奇迹相关建筑
    if bcc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        for k, v in pairs(u.build) do
            local cc = resmng.prop_world_unit[v.propid]
            if not u:can_castle(bcc) then
                u:remove_build(k)
            end
        end
    end
end

function union_build_upgrade(self, idx)
    local u = self:union()
    if not u then return end

    local ret = u:upgrade_build(self, idx)
end


--}}}
--}}}
