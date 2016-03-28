module("player_t")

function get_restore_limit(self)--计算军团仓库上限
    local pack = {
        sum = {},day={}
    }
    local limit = 999999
    pack.sum.limit = limit*10
    pack.day.limit = limit

    local u = unionmng.get_union(self.uid)
    if not u then
        ack(self, "get_eye_info", resmng.E_NO_UNION) return
    end

    pack.day.num   = u:get_res_day(self.pid)
    pack.sum.num   = u:get_res_count(self.pid)

    return pack
end

function get_eye_info(self,eid)--查询大地图建筑信息
    local dp = get_ety(eid)
    if not dp then return end
    local pack ={}
    if is_union_building(dp) then
        local u = unionmng.get_union(dp.uid)
        if not u then
            ack(self, "get_eye_info", resmng.E_NO_UNION) return
        end
        if dp.uid == self.uid then
            local cc = resmng.prop_world_unit[dp.propid]
            if cc.Mode == resmng.CLASS_UNION_BUILD_RESTORE then
                pack.dp = dp
                pack.limit = get_restore_limit(self)
                if u.restore then
                    pack.res = u.restore.sum or {}
                else
                    pack.res =  {}
                end
            else
                pack.dp = dp
                pack.troop = {}
                for k, v in pairs(union_build_t.get_troop(dp._id) or {} ) do
                    local p = getPlayer(v.pid)
                    local t = p:get_troop(v.idx)
                    if t then
                        if t.state == resmng.TroopState.Gather then
                            t.act_speed = math.ceil(p:get_val("GatherSpeed") / 60)
                            t.buf_speed = 0
                        end
                        table.insert(pack.troop,t)
                    end
                end
            end
        end
        Rpc:get_eye_info(self,eid,pack)
    end
end

function get_eid_troop(self,eid,pid)
    local dp = get_ety(eid)
    if not dp then return end
    if is_union_building(dp) then
        local u = unionmng.get_union(dp.uid)
        if not u then
            ack(self, "get_eye_info", resmng.E_NO_UNION) return
        end
        if dp.uid == self.uid then
            for k, v in pairs(union_build_t.get_troop(dp._id) or {} ) do
                if v.pid == pid then
                    local p = getPlayer(v.pid)
                    local t = p:get_troop(v.idx)
                    Rpc:get_eid_troop(self,eid,pid,t.arms)
                    return
                end
            end
        end
    end

    Rpc:get_eid_troop(self,eid,pid,{})
end

function get_room_troop(self,rid,pid)
    local arms = room.get_troop(rid,pid)
    if arms then
        Rpc:get_room_troop(self, rid,pid,arms)
    end
end

function can_res(self,res)--判断资源是否足够
    if (not res[resmng.DEF_RES_FOOD]) or (not self:can_food(res[resmng.DEF_RES_FOOD])) then
        return false
    end

    if (not res[resmng.DEF_RES_WOOD]) or self.wood < res[resmng.DEF_RES_WOOD] then
        return false
    end

    if (not res[resmng.DEF_RES_IRON]) or self.iron < res[resmng.DEF_RES_IRON] then
        return false
    end

    if (not res[resmng.DEF_RES_ENERGY]) or self.energy < res[resmng.DEF_RES_ENERGY] then
        return false
    end

    return true
end

function del_res(self,res)
    if res then
        self:doUpdateRes(resmng.DEF_RES_FOOD, -res[resmng.DEF_RES_FOOD] , VALUE_CHANGE_REASON.UNION_RESTORE)
        self:doUpdateRes(resmng.DEF_RES_WOOD, -res[resmng.DEF_RES_WOOD] , VALUE_CHANGE_REASON.UNION_RESTORE)
        self:doUpdateRes(resmng.DEF_RES_IRON, -res[resmng.DEF_RES_IRON] , VALUE_CHANGE_REASON.UNION_RESTORE)
        self:doUpdateRes(resmng.DEF_RES_ENERGY, -res[resmng.DEF_RES_ENERGY] , VALUE_CHANGE_REASON.UNION_RESTORE)
    end
end

function add_res(self,res)
    self:doUpdateRes(resmng.DEF_RES_FOOD, res[resmng.DEF_RES_FOOD] , VALUE_CHANGE_REASON.UNION_RESTORE)
    self:doUpdateRes(resmng.DEF_RES_WOOD, res[resmng.DEF_RES_WOOD] , VALUE_CHANGE_REASON.UNION_RESTORE)
    self:doUpdateRes(resmng.DEF_RES_IRON, res[resmng.DEF_RES_IRON] , VALUE_CHANGE_REASON.UNION_RESTORE)
    self:doUpdateRes(resmng.DEF_RES_ENERGY, res[resmng.DEF_RES_ENERGY] , VALUE_CHANGE_REASON.UNION_RESTORE)
end


function can_troop_go(self,action,did,info)--判断行军队列前提条件

    if action == resmng.TroopAction.Hold then
        local dp = get_ety(did.eid)
        if not dp then return false end
        if is_union_building(dp) then
            local cc = resmng.prop_world_unit[dp.propid]
            if dp.uid == self.uid then
                for _, v in pairs(union_build_t.get_troop(dp._id) or {} ) do
                    if v.pid == self.pid then
                        return false
                    end
                end
                if (cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or resmng.CLASS_UNION_BUILD_MINI_CASTLE) then
                    return true
                end
            end
        end
    elseif action == resmng.TroopAction.Aid then
        local dp = get_ety(did.eid)
        if dp:get_aid(self.pid) then
            return false
        end

        if #dp.aid > 0 and  dp:get_aid_count()+ troop_t.sum(info.arms) > dp:get_max_aid() then
             return false
        end

        if self:get_uid() == 0 or not self:get_uid() == dp:get_uid() then
            return false
        end
        return true
    elseif action == resmng.TroopAction.Spy then
        return true
    elseif action == resmng.TroopAction.Seige then
        local dp = get_ety(did.eid)
        if not dp then return false end
        if is_union_building(dp) then
            local cc = resmng.prop_world_unit[dp.propid]
            if (cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or resmng.CLASS_UNION_BUILD_MINI_CASTLE) then
                return true
            end
        elseif is_ply(dp) then
            return true
        elseif is_monster(dp) then
            return true
        elseif is_res(dp) and dp.on then
            return true
        end

    elseif action == resmng.TroopAction.Gather then
        if did.eid then
            local dp = get_ety(did.eid)
            if not dp then return false end
            if is_res(dp) then
                return true
            end
            if is_union_building(dp) then
                local cc = resmng.prop_world_unit[dp.propid]
                if dp.uid == self.uid then
                    for _, v in pairs(union_build_t.get_troop(dp._id) or {} ) do
                        if v.pid == self.pid then
                            return false
                        end
                    end
                    if cc.Mode == resmng.CLASS_UNION_BUILD_MINE or resmng.CLASS_UNION_BUILD_FARM or CLASS_UNION_BUILD_LOGGINGCAMP or CLASS_UNION_BUILD_QUARRY then
                        return true
                    end
                end

            end
        end
    elseif action == resmng.TroopAction.Build then
        if is_union_building(did.eid) then
                return true
        end
    elseif action == resmng.TroopAction.Res_go then
        local dp = get_ety(did.eid)
        if not dp then return false end
        if is_union_building(dp) then
            local u = unionmng.get_union(dp.uid)
            local cc = resmng.prop_world_unit[dp.propid]
            if dp.uid == self.uid then
                if cc.Mode == resmng.CLASS_UNION_BUILD_RESTORE then
                    if not self:can_res(info.res) then --玩家已有的资源
                        return false
                    end

                    --仓库上限
                    local d = get_restore_limit(self)
                    local sum = 0
                    sum = sum + info.res[resmng.DEF_RES_FOOD]*resmng.prop_resource[resmng.DEF_RES_FOOD].Mul
                    sum = sum + info.res[resmng.DEF_RES_WOOD]*resmng.prop_resource[resmng.DEF_RES_WOOD].Mul
                    sum = sum + info.res[resmng.DEF_RES_IRON]*resmng.prop_resource[resmng.DEF_RES_IRON].Mul
                    sum = sum + info.res[resmng.DEF_RES_ENERGY]*resmng.prop_resource[resmng.DEF_RES_ENERGY].Mul
                    if sum + d.sum.num > d.sum.limit then
                        return false
                    end

                    if sum + d.day.num > d.day.limit then
                        return false
                    end
                    return true
                end
            end
        end
    elseif action == resmng.TroopAction.Res_back then
        local dp = get_ety(did.eid)
        if not dp then return false end
        if is_union_building(dp) then
            local u = unionmng.get_union(dp.uid)
            local cc = resmng.prop_world_unit[dp.propid]
            if dp.uid == self.uid then
                if cc.Mode == resmng.CLASS_UNION_BUILD_RESTORE then
                    if u:can_res(self.pid,info.res) then
                        return true
                    end
                end
            end
        end
    elseif action == resmng.TroopAction.PRISON_BACK_HOME then
        return true
    end
    return false
end

function getMarchTime(self, t, sx, sy, dx, dy) --计算行军时间
    assert(sx, debug.stack())

    local tr
    local speed = 10
    if t:is_shell() then
        tr = troop_t.get_by_tid(t.troops[1])
    else
        tr = t
    end

    for _, A in pairs(tr.arms) do
        for _, O in pairs(A.objs or {}) do
            if O.id then
                local node = resmng.prop_arm[ O.id ]
                if node then
                    if node.Speed < speed then speed = node.Speed end
                end
            end
        end
    end

    speed = speed * resmng.TROOP_STDSPEED

    -- TODO: 俘虏回城行军速度特殊处理
    if t.action == resmng.TroopAction.PRISON_BACK_HOME then
        -- speed = 100
    end

    -- Hx@2016-01-26: 速度计算依赖状态，导致必须在计算速度前设置好state!!!!
    tr.events = troop_t.calc_tmsA(tr.aid, tr.did, sx, sy, dx, dy, speed, t.state)

    local tm = math.ceil(tr.events[#tr.events].tm - tr.events[1].tm)
    LOG("[Player] getMarchTime, troop:%s, tm:%s, speed:%s", t._id, tm, speed)
    return tm, speed
end

function inc_arm(self, id, num)
    local arms = self.arms
    if not arms then
        arms = {}
        self.arms = arms
    end
    for _, v in pairs(arms) do
        if v[1] == id then
            v[2] = v[2] + num
            self.arms = arms
            return
        end
    end
    table.insert(arms, {id, num})
    self.arms = arms
end

function dec_arm(self, id, num, save)
    local arms = self.arms
    for k, v in pairs(arms) do
        if v[1] == id then
            v[2] = v[2] - num
            if v[2] < 1 then
                table.remove(arms, k)
            end
            self.arms = arms
            return
        end
    end
end

function get_build_speed(self,arms)
    local s = 0
    for _, v in pairs(arms) do
        for _, vv in pairs(v.objs) do
            local c = resmng.prop_arm[ vv.id]
            if c then
                s = s + c.BuildSpeed * vv.num
            end
        end
    end
    return s
end

function chk_arms(self, id, num)
    local arms = self.arms
    for _, v in pairs(arms) do
        if v[1] == id then
            INFO("chk_arms, id=%d, num=%d, have=%d", id, num, v[2])
            return v[2] >= num
        end
    end
    return false
end

function troop_go(self,action,did,info)--发出行军队列

	if not can_troop_go(self,action,did,info) then
		return ack(self, "troops", resmng.E_DISALLOWED)
	end

    local dp = get_ety(did.eid)
    if not dp then return end

    local arm
    if info.arms then
        local total = 0
        for _, v in pairs(info.arms) do
            if not self:chk_arms(v[1], v[2]) then
                return ack(self, "troop", resmng.E_NOT_ENOUGH_SOLDIER)
            end
            total = total + v[2]
        end

        if total < 1 then
            return ack(self, "troops", resmng.E_NO_SOLDIER)
        end

        local hs = {}
        for i = 1, 4, 1 do
            local hidx = info.heros[ i ]
            if not hidx then return ack(self, "troops", resmng.E_NO_HERO) end
            if hidx > 0 then
                local h = self:get_hero(hidx)
                if not h then return ack(self, "troops", resmng.E_NO_HERO) end
                if not heromng.can_go_to_battle(h._id) then ack(self, "troops", resmng.E_HERO_BUSY) end
                table.insert(hs, h._id)
            elseif hidx == 0 then
                table.insert(hs, 0)
            else
                return ack(self, "troops", resmng.E_NO_HERO)
            end
        end


        local max = self:getPropValue("MaxSoldier")
        --todo test
        max = 9999999
        if total > max then
            ack(self, "seige", resmng.E_TOO_MORE_SOLDIER) return
        end

        arm = init_arm(info.arms)
        for i = 1, 4, 1 do
            if hs[i] ~= 0 then
                add_hero(arm, i, hs[i])
                heromng.go_to_battle(hs[i])
            end
        end
    end

    local sx = 0
    local sy = 0
    if action == resmng.TroopAction.PRISON_BACK_HOME then
        sx = info.src_pos.x + 2
        sy = info.src_pos.y + 2
    else
        sx = self.x + 2
        sy = self.y + 2
    end

    local dx = dp.x
    local dy = dp.y
    local cc = resmng.prop_world_unit[dp.propid]
    dx =   dx + math.floor(cc.Size/2)
    dy =   dy + math.floor(cc.Size/2)

    local t = troop_t.create(self.eid, did.eid, action, resmng.TroopState.Go, sx, sy, dx, dy, arm, info.res)
    if not t then return end

    local usetime, speed = self:getMarchTime(t, sx, sy, dx, dy)
    t.speed = speed
    t.tmStart = gTime
    t.tmOver = gTime + usetime
    t.tmSn = timer.new("troop", usetime, self.pid, t.idx)

    for _, v in pairs(info.arms or {} ) do self:dec_arm(v[1], v[2]) end

    if is_monster(dp) then
        dp.aimed = self.eid
        dp:mark()
    elseif is_union_building(dp) then
        if action == resmng.TroopAction.Res_go then
            del_res(self,info.res)
        elseif action == resmng.TroopAction.Seige then
            room.new(t)
        elseif action == resmng.TroopAction.Hold or  resmng.TroopAction.Gather or resmng.TroopAction.Build then
            local u = unionmng.get_union(dp.uid)
            if not u then
                ack(self, "troop_go", resmng.E_NO_UNION) return
            end
            union_build_t.troop_go(dp._id,t.pid,t.idx)
        else
        end
    end

    troop_t.show(t)
    reply_ok(self, "troop_go")

end

function union_mass_create(self, deid, tm, arms,heros)

	if tm < 30 or tm > 1*60*60 then
		ack(self, "union_mass_create", resmng.E_TIMEOUT) return
	end

	if deid == self.eid then
		ack(self, "union_mass_create", resmng.E_DISALLOWED) return
	end
	local dp = get_ety(deid)
	if not dp then
		ack(self, "union_mass_create", resmng.E_NO_ENEMY) return
	end
	if not can_attack(dp) then
		ack(self, "union_mass_create", resmng.E_DISALLOWED) return
	end

	if is_ply(dp) and dp:get_uid() == self:get_uid() then
		return ack(self, "union_mass_create", resmng.E_NotAllowed)
	end

	local union = unionmng.get_union(self:get_uid())
	if not union then
		ack(self, "union_mass_create", resmng.E_FAIL) return
	end

	local hs = {}
	for i = 1, 4, 1 do
		local hidx = heros[ i ]
		if not hidx then return ack(self, "mass_create", resmng.E_NO_HERO) end
		if hidx > 0 then
			local h = self:get_hero(hidx)
			if not h then return ack(self, "mass_create", resmng.E_NO_HERO) end
			if not heromng.can_go_to_battle(h._id) then ack(self, "troops", resmng.E_HERO_BUSY) end

			table.insert(hs, h._id)
		elseif hidx == 0 then
			table.insert(hs, 0)
		else
			return ack(self, "mass_create", resmng.E_NO_HERO)
		end
	end

	local arm = init_arm(arms)
	for i = 1, 4, 1 do
		if hs[i] ~= 0 then
			add_hero(arm, i, hs[i])
		end
	end

	local At = troop_t.create(
		self.eid, self.eid, resmng.TroopAction.Mass_node, resmng.TroopState.Wait,
		self.x, self.y, self.x, self.y, arm
	)

	if not At then
		ack(self, "union_mass_create", resmng.E_NO_TROOP) return
	end

	for _, v in pairs(arms) do self:dec_arm(v[1], v[2]) end

	--local max = self:getPropValue("MaxSoldier")
	local max = 233333

	local mass = troop_t.create(
		self.eid, deid, resmng.TroopAction.Mass, resmng.TroopState.Wait,
		self.x, self.y, dp.x, dp.y, {}, max
	)

	troop_t.add_arm(mass, At)

	mass.tmStart = gTime
	mass.tmOver = gTime + tm
	mass.tmSn = timer.new("troop", tm, self.pid, mass.idx)

	At.tmStart = mass.tmStart
	At.tmOver = mass.tmOver

	room.new(At,mass)

	union:mass_add(mass)

--保存怪物
	if is_monster(dp) then
		dp.aimed = self.eid
		dp:mark()
	end
	INFO("--------------- create mass -----------------")

	Rpc:union_mass_on_create(self, mass.idx)
end

function union_aid_go(self, pid, arms,heros)
    local pb = getPlayer(pid)

    if not pb then
        ack(self, "union_aid_go", resmng.E_NO_PLAYER) return
    end

    if pb:get_aid(self.pid) then
        ack(self, "union_aid_go", resmng.E_DISALLOWED) return
    end

    if #pb.aid > 0 and  pb:get_aid_count()+ troop_t.sum(arms) > pb:get_max_aid() then
        ack(self, "union_aid_go", resmng.E_TOO_MUCH_SOLDIER) return
    end

    if self:get_uid() == 0 or not self:get_uid() == pb:get_uid() then
        ack(self, "union_aid_go", resmng.E_DISALLOWED) return
    end

    local hs = {}
    for i = 1, 4, 1 do
        local hidx = heros[ i ]
        if not hidx then return ack(self, "aid_go", resmng.E_NO_HERO) end
        if hidx > 0 then
            local h = self:get_hero(hidx)
            if not h then return ack(self, "aid_go", resmng.E_NO_HERO) end
			if not heromng.can_go_to_battle(h._id) then ack(self, "troops", resmng.E_HERO_BUSY) end

            table.insert(hs, h._id)
        elseif hidx == 0 then
            table.insert(hs, 0)
        else
            return ack(self, "aid_go", resmng.E_NO_HERO)
        end
    end

    local arm = init_arm(arms)
    for i = 1, 4, 1 do
        if hs[i] ~= 0 then
            add_hero(arm, i, hs[i])
        end
    end

    local At = troop_t.create(
        self.eid, pb.eid, resmng.TroopAction.Aid, resmng.TroopState.Go,
        self.x, self.y, pb.x, pb.y, arm
    )
    --local troop = self:troop_create(B.eid, arms, "aid")
    if not At then
        ack(self, "union_aid_go", resmng.E_FAIL) return
    end

    local tm, speed = self:getMarchTime(At, At.sx, At.sy, At.dx, At.dy)
    At.speed = speed
    At.tmStart = gTime
    At.tmOver = gTime + tm
    At.tmSn = timer.new("troop", tm, self.pid, At.idx)

    for _, v in pairs(arms) do self:dec_arm(v[1], v[2]) end
    troop_t.show(At)

    pb:add_aid(At)
    room.add_D(pb.pid,At)

    ack(self, "union_aid_go", resmng.E_OK)
end

function union_aid_recall(self, pid)
    self:rm_aid(pid)
end

function union_mass_join(self, rid, arms,heros)
	local r = room.get_room(rid)

	local mass = troop_t.get_by_tid(r.A.tid)
	if not mass then
		ack(self, "union_mass_join", resmng.E_NO_MASS) return
	end

	if mass:owner():get_uid() ~= self:get_uid() then
		ack(self, "union_mass_join", resmng.E_FAIL) return
	end

	for _, tid in pairs(mass.troops) do
		local tr = troop_t.get_by_tid(tid)
		if tr and tr.pid == self.pid then
			WARN("[Player] join mass repeated: shell:%s, pid:%s", mass._id, self.pid)
			return
		end
	end

	local dp = getPlayer(mass.pid)
	local hs = {}
	for i = 1, 4, 1 do
		local hidx = heros[ i ]
		if not hidx then return ack(self, "mass_join", resmng.E_NO_HERO) end
		if hidx > 0 then
			local h = self:get_hero(hidx)
			if not h then return ack(self, "mass_join", resmng.E_NO_HERO) end
			if not heromng.can_go_to_battle(h._id) then ack(self, "troops", resmng.E_HERO_BUSY) end

			table.insert(hs, h._id)
		elseif hidx == 0 then
			table.insert(hs, 0)
		else
			return ack(self, "mass_join", resmng.E_NO_HERO)
		end
	end

	local arm = init_arm(arms)
	for i = 1, 4, 1 do
		if hs[i] ~= 0 then
			add_hero(arm, i, hs[i])
		end
	end

	local At = troop_t.create(
		self.eid, dp.eid, resmng.TroopAction.Mass_node, resmng.TroopState.Go,
		self.x, self.y, dp.x, dp.y, arm
	)

	if not At then
		ack(self, "union_mass_join", resmng.E_FAIL) return
	end

	for _, v in pairs(arms) do self:dec_arm(v[1], v[2]) end

	mass:add_arm(At)
	room.add_A(rid,At)

	local tm, speed = self:getMarchTime(At, At.sx, At.sy, At.dx, At.dy)
	At.speed = speed
	At.tmStart = gTime
	At.tmOver = gTime + tm
	At.tmSn = timer.new("troop", tm, self.pid, At.idx)
	troop_t.show(At)

	--union:mass_join(mass.idx, At)
	INFO("--------------- join mass -----------------")
end

function union_mass_deny(self, rid, pid)
	local u = self:union()
	if not u then return end

	local r = room.get_room(rid)
	local tr = troop_t.get_by_tid(r.A.tid)
	if not tr then return end

	if tr.pid ~= self.pid then return end

	for i = #tr.troops, 1, -1 do
		local t = troop_t.get_by_tid(tr.troops[i])
		if t.pid == pid then
			local A = getPlayer(pid)
			A:troop_back(t)
			table.remove(tr.troops, i)
		end
	end
	tr.troops = tr.troops
end

function gather(self,deid,objs,heros)
    local dp = get_ety(deid)
    if not dp then return end

    if not is_res(dp) then
        return
    end

    local dx, dy = dp.x, dp.y

    local sx = self.x + 2
    local sy = self.y + 2
    local dx = dp.x + 1
    local dy = dp.y + 1

    local total = 0
    for _, v in pairs(objs) do
        if not self:chk_arms(v[1], v[2]) then return end
        total = total + v[2]
    end

    local arm = init_arm(objs)
    local t = troop_t.create(self.eid, deid, resmng.TroopAction.Gather, resmng.TroopState.Go, sx, sy, dx, dy, arm)
    if not t then return end

    local usetime, speed = self:getMarchTime(t, sx, sy, dx, dy)

    t.speed = speed
    t.tmStart = gTime
    t.tmOver = gTime + usetime
    t.tmSn = timer.new("troop", usetime, self.pid, t.idx)
    t.count = {}

    for _, v in pairs(objs) do self:dec_arm(v[1], v[2]) end
    troop_t.show(t)

    print(string.format("gather %d, %d -> %d, %d", t.sx, t.sy, t.dx, t.dy))

    reply_ok(self, "gather")
end


function spy(self, deid)
    local D = get_ply(deid)
    if D then
        local speed = 100
        local sx,sy = self.x+2, self.y+2
        local dx,dy = D.x+2, D.y+2


        local dist = math.pow( math.pow(dx-sx, 2) + math.pow(dy-sy,2), 0.5)
        local minute = dist / speed
        local usetime = math.ceil(minute * 60)

        local t = troop_t.create(self.eid, deid, resmng.TroopAction.Spy, resmng.TroopState.Go, sx, sy, dx, dy, {})
        if not t then return end
        t.speed = speed
        t.tmStart = gTime
        t.tmOver = gTime + usetime
        t.tmSn = timer.new("troop", usetime, self.pid, t.idx)
        troop_t.show(t)
    end
end

function seige(self, deid, objs, heros)
    if deid == self.eid then return end
    local dp = get_ety(deid)
    if not dp then return end
    if not can_attack(dp) then return end

    local dx, dy = dp.x, dp.y

    local total = 0
    for _, v in pairs(objs) do
        if not self:chk_arms(v[1], v[2]) then
            return ack(self, "seige", resmng.E_NOT_ENOUGH_SOLDIER)
        end
        total = total + v[2]
    end

    if total < 1 then
        return ack(self, "seige", resmng.E_NO_SOLDIER)
    end

    local hs = {}
    for i = 1, 4, 1 do
        local hidx = heros[ i ]
        if not hidx then return ack(self, "seige", resmng.E_NO_HERO) end
        if hidx > 0 then
            local h = self:get_hero(hidx)
            if not h then return ack(self, "seige", resmng.E_NO_HERO) end

            --if not h:can_go_to_battle() then ack(self, "seige", resmng.E_HERO_BUSY) end
            if not heromng.can_go_to_battle(h._id) then ack(self, "seige", resmng.E_HERO_BUSY) end

            table.insert(hs, h._id)
        elseif hidx == 0 then
            table.insert(hs, 0)
        else
            return ack(self, "seige", resmng.E_NO_HERO)
        end
    end


    local max = self:getPropValue("MaxSoldier")
    --todo test
    max = 9999999
    if total > max then
        ack(self, "seige", resmng.E_TOO_MORE_SOLDIER) return
    end

    local arm = init_arm(objs)
    for i = 1, 4, 1 do
        if hs[i] ~= 0 then
            add_hero(arm, i, hs[i])
            heromng.go_to_battle(hs[i])
        end
    end

    local sx = self.x + 2
    local sy = self.y + 2
    local dx =   dp.x
    local dy =   dp.y

    if is_ply(deid) then
        dx = dx + 2
        dy = dy + 2
    end

    local t = troop_t.create(self.eid, deid, resmng.TroopAction.Seige, resmng.TroopState.Go, sx, sy, dx, dy, arm)
    if not t then return end

    local usetime, speed = self:getMarchTime(t, sx, sy, dx, dy)
    t.speed = speed
    t.tmStart = gTime
    t.tmOver = gTime + usetime
    t.tmSn = timer.new("troop", usetime, self.pid, t.idx)

    for _, v in pairs(objs) do self:dec_arm(v[1], v[2]) end
    troop_t.show(t)

    if is_monster(dp) then
        dp.aimed = self.eid
        dp:mark()
    end

    room.new(t)
    reply_ok(self, "seige")
end

function get_troop(self, idx)
    if idx then
        if self._troop then
            return self._troop[ idx ]
        end
    else
        return self._troop
    end
end



function set_troop(self, idx, b)
    if not self._troop then self._troop = {} end
    self._troop[ idx ] = b
end



function troopx_back(self, idx)--手动返回行军队列
    local tr = self:get_troop(idx)
    if not tr then return end
    local dp = get_ety(tr.did)
    if not dp then
        return ack(self, "troop_back", resmng.E_FAIL)
    end


    if tr.state == resmng.TroopState.Wait or tr.state == resmng.TroopState.Arrive then
        local shell = troop_t.get_by_tid(tr.parent)
        if shell and shell.pid == tr.pid then
            LOG("[Player] troop back, troop:%s, pid:%s", shell._id, self.pid)
            if shell.action == resmng.TroopAction.Mass then
                self:troop_home(shell)
            else
                self:troop_back(shell)
            end
        else
            LOG("[Player] troop back, troop:%s, pid:%s", tr._id, self.pid)
            local Tparent = troop_t.get_by_tid(tr.parent)
            if Tparent then Tparent:rm_arm(tr) end
            if tr.action == resmng.TroopAction.Aid then
               dp:rm_aid(self.pid)
            else
                self:troop_back(tr)
            end
        end
    elseif tr.state == resmng.TroopState.Gather then
        player_t.func_troop[resmng.TroopAction.Gather][resmng.TroopState.Gather](tr.tmSn, self, tr)
    end
end


function troop_home(self, t)--行军队列到家
    if troop_t.is_shell(t) then--空壳
        --判断是否为集结发起人
        local o=nil
        local v = troop_t.get_by_tid(t.troops[1])
        if self.pid == v.pid then
            o = 1
        end

        for k, tid in pairs(t.troops) do
            local v = troop_t.get_by_tid(tid)
            if v and v.pid then
                local p = getPlayer(v.pid)
                if p then
                    if o == 1 then
                        p:troop_back(v)
                    else
                        if v.pid == self.pid then
                            p:troop_back(v)
                        end
                    end
                end
            end
        end
        troop_t.del(t)
        return
    else
        if t.action ~= resmng.TroopAction.Defend then
            troop_t.del(t)
        end
    end


    local deads = {}
    for _, arm in pairs(t.arms) do
        for _, obj in pairs(arm.objs or {}) do
            if obj.hero then
                heromng.back_from_battle(obj.hero, obj.num)
            else
                local id = obj.id
                if obj.num > 0 then self:inc_arm(id, obj.num) end
                deads[ id ] = (deads[ id ] or 0) + (obj.num0 or obj.num - obj.num)
            end
        end
    end

    if t.action == resmng.TroopAction.Defend then
        self:cure(deads)

    elseif t.action == resmng.TroopAction.Gather then
        --local prop = resmng.prop_build[ t.carryid ]
        --if prop then
        --    self:doUpdateRes(prop.Mode, t.carry, VALUE_CHANGE_REASON.GATHER)
        --end

        if t.carry then
            for k, v in pairs(t.carry) do
                if v[1] == resmng.CLASS_RES then
                    self:doUpdateRes(v[2], v[3], VALUE_CHANGE_REASON.GATHER)
                elseif v[1] == resmng.CLASS_ITEM then
                    self:inc_item(v[2], v[3], VALUE_CHANGE_REASON.GATHER)
                end
            end
        end
    elseif t.action == resmng.TroopAction.Res_back then
        add_res(self,t.res)
    end

end

function troop_back(self, t)--自动返回行军队列
    LOG("[Player] troop back:%s, action=%d, state=%d", t._id, t.action, t.state)
    if troop_t.is_shell(t) then
        for _, tid in pairs(t.troops) do
            local v = troop_t.get_by_tid(tid)
            if v and v.pid then
                v.dx = t.dx
                v.dy = t.dy

                local p = getPlayer(v.pid)
                if p then
                    p:troop_back(v)
                end
            end
        end
        troop_t.del(t)
        return
    end

    local dp = get_ety(t.did)
    if not dp then
        return
    end

    room.del(t)
    if is_union_building(dp) then
        local u = unionmng.get_union(dp.uid)
        if u then
            union_build_t.troop_back(dp._id,t.pid,t.idx)
        end
    end

    if t.action == resmng.TroopAction.Defend then
        return troop_home(self, t)
    end

    if t.state == resmng.TroopState.Go then
        local r = (gTime - t.tmStart) / (t.tmOver - t.tmStart)
        if r > 1 then r = 1 end
        if r < 0 then r = 0 end
        local t_dx, t_dy = math.floor(t.sx +(t.dx - t.sx) * r), math.floor(t.sy + (t.dy - t.sy) * r)
        t.sx, t.sy = t_dx, t_dy
    else
        t.sx,t.sy = t.dx,t.dy
    end

    t.dx = self.x + 2
    t.dy = self.y + 2
    t.state = resmng.TroopState.Back
    local usetime, speed = self:getMarchTime(t, t.sx, t.sy, t.dx, t.dy)
    t.tmStart = gTime
    t.tmOver = gTime + usetime
    t.tmSn = timer.new("troop", usetime, self.pid, t.idx)

    INFO("~~~~~~ troop home ~~~~~~~ ".. t._id.. " ".. usetime)

    troop_t.show(t)
end

function troopx_stdtime(self, did)--获取行军队列时间
    local D = get_ety(did)
    if not D then
        Rpc:troopx_stdtime(self, did, 0)
        return
    end
    local tms = troop_t.calc_tms(
        self.eid, did, self.x, self.y, D.x, D.y,
        resmng.TROOP_STDSPEED, resmng.TroopState.Go
    )

    local s = tms[1].tm
    local e = tms[#tms].tm

    Rpc:troopx_stdtime(self, did, math.ceil(e - s))
end


function doTimerTroop(self, tsn, tid)--行军队列定时器触发
    local A = self
    local At = A:get_troop(tid)
    if At then
        if At.tmSn ~= tsn then return end
        At.tmSn = 0
        local fun = player_t.func_troop[ At.action ]
        if fun then
            fun = fun[ At.state ]
            if fun then
                fun(tsn, A, At)
            end
        else
            WARN("troop:%s fun not found:%s", At._id, At.action)
        end
    else
        WARN("troop, idx=%d, pid=%d not found", tid, self.pid)
    end
end

player_t.func_troop = {}
player_t.func_troop[resmng.TroopAction.Spy] = {}
player_t.func_troop[resmng.TroopAction.Spy][resmng.TroopState.Go] = function (tsn, A, At)
    local D = get_ply(At.did)
    if D then
        --if D.x == At.dx and D.y == At.dy then
            At.state = resmng.TroopState.Back
            local usetime = gTime - At.tmStart
            At.tmStart = gTime
            At.tmOver = gTime + usetime
            At.tmSn = timer.new("troop", usetime, A.pid, At.idx)
            At.dx, At.dy = A.x+2, A.y+2
            At.sx, At.sy = D.x+2, D.y+2
            troop_t.show(At)

            D:resetfood()
            local res1 = {D.food, D.wood, D.iron, D.energy}
            local res0 = {0, 0, 0, 0}

            for _, v in pairs(D:get_build()) do
                local node = resmng.prop_build[ v.propid ]
                if node and node.class == BUILD_CLASS.RESOURCE then
                    local mode = node.Mode
                    local speed = node.Speed
                    local count = node.Count
                    local b, m, a = self:get_val_extra(string.format("Res%dSpeed"), mode)
                    local make = math.floor( (gTime - v.tmStart) * (speed * m + a) / 3600 )
                    if make > count then make = count end
                    res0[ mode ] = res0[ mode ] + make
                end
            end

            local content = {name=D.name, photo=D.photo, x=D.x, y=D.y, arms=D.arms, res0=res0, res1=res1}
            local mail = {class=MAIL_CLASS.FIGHT, mode=MAIL_FIGHT_MODE.SPY, content=content}
            A:mail_new(mail)

            D:mail_new({class=MAIL_CLASS.FIGHT, mode=MAIL_FIGHT_MODE.BE_SPY, content={name=A.name, photo=A.photo}})
        --end
    end
end

player_t.func_troop[resmng.TroopAction.Spy][resmng.TroopState.Back] = function (tsn, A, At)
    troop_t.del(At)
end

function go_fight(at)--战斗统一入口

    local dp = get_ety(at.did)
    if not dp then return end

    if is_ply(dp) then
        local Dt = dp:init_def_troop()
        return fight.pvp("seige", at, Dt)
    elseif is_monster(dp) then
        local Dt = dp:init_def_troop()
        return fight.pvp("jungle", at, Dt)
    elseif is_union_building(dp) then
        local u = unionmng.get_union(dp.uid)
        if not u then return end

        local t = {action=resmng.TroopAction.Defend, aid=dp.eid, arms={}}
        local total = 0
        for _, tr in pairs(union_build_t.get_troop(dp._id) or {} ) do
            local p = getPlayer(tr.pid)
            local tt = p:get_troop(tr.idx)
            for _, v in pairs(tt.arms) do
                local arm = v[1]
                local num = v[2]
                total = total + num
                add_soldier(arm, num, t)
            end
        end

        --local s =  fight.pvp("castle", at, t)

        dp.hp = dp.hp - 100
        local u = unionmng.get_union(dp.uid)
        if not u then
            ack(self, "get_eye_info", resmng.E_NO_UNION) return
        end
        union_build_t.update_val(at,dp)
        local p = getPlayer(at.pid)
        p:troop_back(at)
    end

end

player_t.func_troop[resmng.TroopAction.Seige] = {}
player_t.func_troop[resmng.TroopAction.Seige][resmng.TroopState.Go] = function (tsn, A, At)
    LOG("[Player] troop go finish, troop:%s, player:%s", At._id, A._id)
    go_fight(At)
end


player_t.func_troop[resmng.TroopAction.Seige][resmng.TroopState.Back] = function (tsn, A, At)
    LOG("[Player] troop back finish, troop:%s, player:%s", At._id, A._id)
    A:troop_home(At)
end

player_t.func_troop[resmng.TroopAction.Gather] = {}
player_t.func_troop[resmng.TroopAction.Gather][resmng.TroopState.Go] = function (tsn, A, At)
    local t = At
    local dp = get_ety(At.did)
    if not dp then A:troop_back(At) return end
    --if not can_troop_go(A,At.action,{eid=At.did}) then A:troop_back(At) return end

    if is_res(dp) then
        dp.on = At._id
        dp.pid = A.pid
        dp.uid = A:get_uid()
        etypipe.add(dp)
        farm.mark(dp)
    elseif is_union_building(dp) then
        if union_build_t.update_val(At,dp) then
           return
        end
    end

    local v = A:get_val("GatherSpeed") / 60
    local w = A:get_weight(At)
    local t = math.ceil(math.min(dp.val, w) / v)
    At.state = resmng.TroopState.Gather
    At.tmStart = gTime
    At.tmOver = At.tmStart + t
    At.tmSn = timer.new("troop", t, A.pid, At.idx)
    troop_t.unshow(At)

end

player_t.func_troop[resmng.TroopAction.Gather][resmng.TroopState.Gather] = function (tsn, A, At)
    local dp = get_ety(At.did)
    if not dp then
        A:troop_back(At)
        return
    end

    local v = A:get_val("GatherSpeed") / 60
    local g = v * (gTime - At.tmStart)
    local w = A:get_weight(At)
    g = math.min(g, w)
    g = math.min(g, dp.val)

    if is_union_building(dp) then

         if  union_build_t.update_val(At,dp) then
            return
         end
    else
        if g >= dp.val - 1 then
            rem_ety(dp.eid)
        else
            dp.val = dp.val - g
            dp.pid = 0
            dp.uid = 0
            dp.on = 0
            farm.mark(dp)
            etypipe.add(dp)
        end
    end

    At.state = resmng.TroopState.Back
    local prop = resmng.prop_build[ dp.propid ]
    if prop then
        local hit = false
        if not At.carry then At.carry = {} end
        for k, v in pairs(At.carry) do
            if v[1] == 1 and v[2] == prop.Mode then
                hit = true
                v[3] = (v[3] or 0) + g
            end
        end

        if not hit then
            table.insert(At.carry, {1, prop.Mode, g})
        end
    end

    At.count = {}

    local content = {x=dp.x, y=dp.y, carry = At.carry, buildid=dp.propid }
    local mail = {class=MAIL_CLASS.REPORT, mode=MAIL_REPORT_MODE.GATHER, content=content}
    A:mail_new(mail)

    local t = At
    print(string.format("gather, gather %d, %d -> %d, %d", t.sx, t.sy, t.dx, t.dy))
    A:troop_back(At)
end

player_t.func_troop[resmng.TroopAction.Gather][resmng.TroopState.Back] = function (tsn, A, At)
    A:troop_home(At)
end

player_t.func_troop[resmng.TroopAction.Build] = {}
player_t.func_troop[resmng.TroopAction.Build][resmng.TroopState.Go] = function (tsn, A, At)
    local dp = get_ety(At.did)
    if not dp then A:troop_back(At) return end
    --if not can_troop_go(A,At.action,{eid=At.did}) then A:troop_back(At) return end
     union_build_t.update_val(At,dp)
end

player_t.func_troop[resmng.TroopAction.Build][resmng.TroopState.Build] = function (tsn, A, At)
    local dp = get_ety(At.did)
    if not dp then
        A:troop_back(At)
        return
    end
    union_build_t.update_val(At,dp)
end

player_t.func_troop[resmng.TroopAction.Build][resmng.TroopState.Back] = function (tsn, A, At)
    A:troop_home(At)
end


--------------------------------------------------------------------------------
-- 俘虏回城队列
player_t.func_troop[resmng.TroopAction.PRISON_BACK_HOME] = {}
player_t.func_troop[resmng.TroopAction.PRISON_BACK_HOME][resmng.TroopState.Go] = function (tsn, A, At)
    local hero_idx = At.res and At.res.hero_idx
    if hero_idx then
        local hero = A:get_hero(hero_idx)
        if hero then
            hero.status = HERO_STATUS_TYPE.FREE
        else
            ERROR("func_troop[PRISON_BACK_HOME]: get hero failed. pid = %d, hero_idx = %d.", A.pid, hero_idx)
        end
    else
        ERROR("func_troop[PRISON_BACK_HOME]: lost hero_idx. pid = %d.", A.pid)
    end
    troop_t.del(At)
end
--------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
-- Hx@2016-01-29: 集结队列
-- -----------------------------------------------------------------------------
player_t.func_troop[resmng.TroopAction.Mass] = {}
player_t.func_troop[resmng.TroopAction.Mass][resmng.TroopState.Wait] = function (tsn, A, At)
    LOG("[Player] mass wait finish, troop:%s, player:%s", At._id, At.pid)

    At.state = resmng.TroopState.Go
    local tm, speed = A:getMarchTime(At, At.sx, At.sy, At.dx, At.dy)
    At.speed = speed
    At.tmStart = gTime
    At.tmOver = gTime + tm
    At.tmSn = timer.new("troop", tm, A.pid, At.idx)
    troop_t.show(At)

    for i = #At.troops,1,-1 do
        local t = troop_t.get_by_tid(At.troops[i])
        if t.state ~= resmng.TroopState.Wait then
            LOG("[Player] At remove unarrive, troop:%s state:%s", t._id, t.state)
            table.remove(At.troops, i)
        else
            t.sx = At.sx
            t.sy = At.sy
            t.dx = At.dx
            t.dy = At.dy
            t.tmStart = At.tmStart
            t.tmOver = At.tmOver
            t.speed = At.speed
            t.state = At.state
        end
    end
end

player_t.func_troop[resmng.TroopAction.Mass][resmng.TroopState.Go] = function (tsn, A, At)
    LOG("[Player] At go finish, troop:%s, player:%s", At._id, At.pid)
    troop_t.unshow(At)

    local r = room.get_room(At.tid)
    local D = get_ety(At.did)
    if D then
        local Dt = D:init_def_troop()
        if is_ply(At.did) then
            fight.pvp("seige", At, Dt)
        elseif is_monster(At.did) then
            fight.pvp("jungle", At, Dt)
        end
    end
end

player_t.func_troop[resmng.TroopAction.Mass_node] = {}
player_t.func_troop[resmng.TroopAction.Mass_node][resmng.TroopState.Go] = function(tsn, A, At)
    INFO("--------------- join mass arrive -----------------")

    At:unshow()

    local union = A:union()

    local mass = troop_t.get_by_tid(At.parent)

    if not mass then
        A:troop_back(At)
    elseif mass.state == resmng.UNION_MASS_STATE.FINISH then
        A:troop_back(At)
    else
        troop_t.unshow(At)
        At.state = resmng.TroopState.Wait
        At.tmStart = gTime
        At.tmOver = mass.tmOver
        --union:mass_update(mass.idx)
    end
end

player_t.func_troop[resmng.TroopAction.Mass_node][resmng.TroopState.Back] = function(tsn, A, At)
    INFO("~~~~~~ troop home time over ~~~~".. At._id)
    A:troop_home(At)
end

player_t.func_troop[resmng.TroopAction.Aid] = {}
player_t.func_troop[resmng.TroopAction.Aid][resmng.TroopState.Go] = function(tsn, A, At)
    troop_t.unshow(At)
    At.state = resmng.TroopState.Arrive
end
player_t.func_troop[resmng.TroopAction.Aid][resmng.TroopState.Back] = function(tsn, A, At)
    A:troop_home(At)
end

player_t.func_troop[resmng.TroopAction.Hold] = {}
player_t.func_troop[resmng.TroopAction.Hold][resmng.TroopState.Go] = function (tsn, A, At)
    LOG("[Player] troop go finish, troop:%s, player:%s", At._id, A._id)
    local dp = get_ety(At.did)
    if not dp then ack(self, "troop_go", resmng.E_NO_UNION) return end

    troop_t.unshow(At)
    At.state = resmng.TroopState.Arrive
end
player_t.func_troop[resmng.TroopAction.Hold][resmng.TroopState.Back] = function(tsn, A, At)
    A:troop_home(At)
end

player_t.func_troop[resmng.TroopAction.Res_go] = {}
player_t.func_troop[resmng.TroopAction.Res_go][resmng.TroopState.Go] = function(tsn, A, At)
    troop_t.unshow(At)

	local dp = get_ety(At.did)
    if not dp then ack(self, "troop_go", resmng.E_NO_UNION) return end
    local u = unionmng.get_union(dp.uid)
    if not u then
        ack(self, "troop_go", resmng.E_NO_UNION) return
    end
    u:restore_add_res(At.pid,At.res)

    At.state = resmng.TroopState.Back
    A:troop_back(At)
end
player_t.func_troop[resmng.TroopAction.Res_go][resmng.TroopState.Back] = function(tsn, A, At)
    A:troop_home(At)
end

player_t.func_troop[resmng.TroopAction.Res_back] = {}
player_t.func_troop[resmng.TroopAction.Res_back][resmng.TroopState.Go] = function(tsn, A, At)
    troop_t.unshow(At)

	local dp = get_ety(At.did)
    if not dp then ack(self, "troop_go", resmng.E_NO_UNION) return end
    local u = unionmng.get_union(dp.uid)
    if not u then
        ack(self, "troop_go", resmng.E_NO_UNION) return
    end
    u:restore_del_res(At.pid,At.res)

    At.state = resmng.TroopState.Back
    A:troop_back(At)
end

player_t.func_troop[resmng.TroopAction.Res_back][resmng.TroopState.Back] = function(tsn, A, At)
    A:troop_home(At)
end


