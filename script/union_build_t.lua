-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
module(..., package.seeall)
local op={}--需修改的数据
local troop={}--绑定到建筑的行军队列
local build_sn = 0

function set_sn(sn)
    if build_sn < (sn or 0 ) then
        build_sn = sn
    end
end

function troop_go(_id,pid,idx)
	if not troop[_id] then
		troop[_id] = {}
	end
	table.insert(troop[_id],{pid=pid,idx=idx})
end

function troop_back(_id ,pid,idx)
    for k, v in pairs(troop[_id] or {}) do
        if v.pid == pid and v.idx==idx then
	        troop[_id][k]=nil
        end
    end
end

function get_troop(_id )
	return troop[_id] 
end

function create(uid,idx, propid, x, y)

    assert(idx and propid and  uid and  x and y)
    local u = unionmng.get_union(uid)

    local cc = resmng.prop_world_unit[propid]
    if not cc and cc.Class ~= BUILD_CLASS.UNION then return end
    --TODO: 地图空位检测
    if c_map_test_pos(x, y, cc.Size) ~= 0 then
        return
    end

    local data
    build_sn = build_sn + 1
    if idx == 0 then
        idx = #u.build+1

    --    if not u:can_build(propid,x,y) then return end

        local _id = string.format("%s_%s", idx, uid)
        data = {
            _id = _id,
            eid = get_eid_uion_building(),
            idx = idx,
            uid = uid,
            hp = 0,
            x = x,
            y = y,
            size = cc.Size,
            propid = propid,
            range = 0,
            state = BUILD_STATE.CREATE,
            sn = build_sn,
            val = cc.Count or 0,
            speed = 0,
            tmStart = 0,
        }
        local db = dbmng:getOne()
        db.union_build:insert(data)
        u.build[idx] = data
    else
        u.build[idx].eid = get_eid_uion_building()
        u.build[idx].sn = build_sn
        u.build[idx].hp = 0
        u.build[idx].speed = 0
        u.build[idx].tmStart = 0
        u.build[idx].val = cc.Count or 0
        u.build[idx].state = BUILD_STATE.CREATE
        op[u.build[idx]._id]=u.build[idx]
    end

    etypipe.add(u.build[idx])
	gEtys[u.build[idx].eid] = u.build[idx]
end

function update_val(at,dp) --更新军团建筑多军队事件

    local u = unionmng.get_union(dp.uid)
    if not u then
        return false
    end

    if at.action == resmng.TroopAction.Gather then --采集
        local time = 0
        if dp.tmStart and dp.tmStart ~= 0 then
            time = gTime - dp.tmStart
        end

        for k, v in pairs(troop[dp._id] or {} ) do
            local p = getPlayer(v.pid)
            local t = p:get_troop(v.idx)
            local g = math.ceil(p:get_val("GatherSpeed") / 60) * time

            --todo, why should calculate the state GO ?
            --挂载已采集的数量
            if t.state == resmng.TroopState.Go or resmng.TroopState.Gather then
                local c = resmng.prop_world_unit[ dp.propid ]
                local mode
                if  c.Mode == resmng.CLASS_UNION_BUILD_FARM then
                    mode = resmng.DEF_RES_FOOD
                elseif  c.Mode == resmng.CLASS_UNION_BUILD_LOGGINGCAMP then
                    mode = resmng.DEF_RES_WOOD
                elseif  c.Mode == resmng.CLASS_UNION_BUILD_MINE then
                    mode = resmng.DEF_RES_IRON
                elseif  c.Mode == resmng.CLASS_UNION_BUILD_QUARRY then
                    mode = resmng.DEF_RES_ENERGY
                end

                local hit = false
                if not t.carry then t.carry = {} end
                for k, v in pairs(t.carry) do
                    if v[1] == resmng.CLASS_RES and v[2] == mode then
                        hit = true
                        v[3] = (v[3] or 0) + g
                    end
                end

                if not hit then
                    table.insert(t.carry, {resmng.CLASS_RES , mode, g})
                end

            end

        end

        --计算新速度
        if dp.val >= (time*(dp.speed or 0 ))then --没采完
            dp.val = dp.val - time* (dp.speed or 0)
            dp.speed = 0
            dp.tmStart = gTime
            for k, v in pairs(troop[dp._id] or {} ) do
                local p = getPlayer(v.pid)
                local t = p:get_troop(v.idx)
                if t.state == resmng.TroopState.Go or resmng.TroopState.Gather then
                    dp.speed = (dp.speed or 0 )+ math.ceil(p:get_val("GatherSpeed") / 60)--新速度
                end
            end

            --重新计算行军队列时间
            for k, v in pairs(troop[dp._id] or {} ) do
                    local p = getPlayer(v.pid)
                    local t = p:get_troop(v.idx)
                if t.state == resmng.TroopState.Go or resmng.TroopState.Gather then
                    time = math.ceil(dp.val/dp.speed)
                    t.state = resmng.TroopState.Gather
                    t.tmStart = gTime
                    t.tmOver = t.tmStart + time
                    t.tmSn = timer.new("troop", time, v.pid, t.idx)
                    troop_t.unshow(t)
                end
            end
        else --采完了
            dp.val = 0
            dp.speed = 0
            --返回所有部队
            for k, v in pairs(troop[dp._id] or {} ) do
                local p = getPlayer(v.pid)
                local t =p:get_troop(v.idx)
                if t then
                    t.state = resmng.TroopState.Back
                    p:troop_back(t)
                end
                v=nil
            end
            u.build[dp.idx] = dp
            op[dp._id]=dp
            etypipe.add(dp)
            return true
        end
    elseif at.action == resmng.TroopAction.Build then --建造
        local c = resmng.prop_world_unit[ dp.propid]
        local time = 0
        if dp.tmStart and dp.tmStart ~= 0 then
            time = gTime - dp.tmStart
        end

        --计算新速度
        if dp.hp +(time*(dp.speed or 0 ))< c.Hp then --没建好
            dp.hp = dp.hp + time* (dp.speed or 0)
            dp.speed = 0
            dp.tmStart = gTime
            for k, v in pairs(troop[dp._id] or {} ) do
                local p = getPlayer(v.pid)
                local t = p:get_troop(v.idx)
                if t.state == resmng.TroopState.Go or resmng.TroopState.Build then
                    dp.speed = (dp.speed or 0 )+ p:get_build_speed(t.arms) --新速度
                end
            end

            --todo why not just set one timer for the building ?
            --重新计算行军队列时间
            for k, v in pairs(troop[dp._id] or {} ) do
                local p = getPlayer(v.pid)
                local t = p:get_troop(v.idx)
                if t.state == resmng.TroopState.Go or resmng.TroopState.Build then
                    time = math.ceil((c.Hp-dp.hp)/dp.speed)
                    t.state = resmng.TroopState.Build
                    t.tmStart = gTime
                    t.tmOver = t.tmStart + time
                    t.tmSn = timer.new("troop", time, v.pid, t.idx)
                    troop_t.unshow(t)
                end
            end
        else --建好了
            dp.hp = c.Hp
            dp.speed = 0
            dp.state =  BUILD_STATE.WAIT

            --返回所有军队

            for k, v in pairs(troop[dp._id] or {} ) do
                local p = getPlayer(v.pid)
                local t =p:get_troop(v.idx)
                if t then
                    t.state = resmng.TroopState.Back
                    p:troop_back(t)
                end
                v=nil
            end

            u.build[dp.idx] = dp
            op[dp._id]=dp
            etypipe.add(dp)
            return true
        end
    end
    u.build[dp.idx] = dp
    op[dp._id]=dp
    etypipe.add(dp)
    return false
end

function get_by_id(_id)
    local x = string.split(_id, "_")
    return unionmng.get_union(tonumber(x[2])).build[tonumber(x[1])]
end

function get_ef(self)
    if self.ef then return self.ef end

    local ef = {}
    self.ef = ef

    local u = unionmng.get_union(self.uid)
    assert(u, string.format("[Troop] get_ef, uid:%s", self.uid))
    local cc = resmng.prop_world_unit[self.propid] or {}

    -- calc range first
    for _, buff in pairs(cc.Buff or {} ) do
        if type(buff)=="table" and buff[2] == "Range" then
            for _, bl in pairs(u.build) do
                local conf = resmng.prop_world_unit[bl.propid]
                if conf.Mode == buff[1] then
                    if self.x < bl.x
                        and bl.x + conf.Size < self.x + cc.Size + cc.Range
                        and self.y < bl.y
                        and bl.y + conf.Size < self.y + cc.Size + cc.Range then
                        ef[buff[2]] = (ef[buff[2]] or 0) + (buff[3] or 0)
                    end
                end
            end
        end
    end
    self.ef.Range = (self.ef.Range or 0) + (cc.Range or 0)

    --PATCH: 为了简化c_add_ety的格式化工作
    self.range = self.ef.Range

    -- then others
    for _, buff in pairs(cc.Buff or {}) do
        if type(buff)=="table" and buff[2] ~= "Range" then
            for _, bl in pairs(u.build) do
                local conf = resmng.prop_world_unit[bl.propid]
                if conf.Mode == buff[1] then
                    if self.x < bl.x
                        and bl.x + conf.Size < self.x + cc.Size + cc.Range
                        and self.y < bl.y
                        and bl.y + conf.Size < self.y + cc.Size + cc.Range then
                        ef[buff[2]] = (ef[buff[2]] or 0) + (buff[3] or 0)
                    end
                end
            end
        end
    end

    return self.ef
end

function get_def(self)
    local ef = self:get_ef()
    local cc = resmng.prop_world_unit[self.propid]
    local xs = {}
    for buff, val in pairs(cc.Debuff) do
        xs[buff] = val + ef[buff]
    end
    return xs
end

function get_class(self)
    local cc = resmng.prop_world_unit[self.propid]
    if not cc then return end
    self.cls = cc.Class
    return self.cls,cc.Mode
end

function check_pending()--帧结尾统一保存数据库
    if next(op) then 
        local db = dbmng:tryOne(1)
        if not db then return end
        for k, v in pairs(op) do
            db.union_build:update({_id=k},{["$set"]=v })
            --广播建筑变化
            local u = unionmng.get_union(v.uid)
            u:notifyall("build", resmng.OPERATOR.UPDATE, v)
            op[k]=nil
        end
    end

end

function get_buildlv_conf(class, lv)
    for _, v in pairs(resmng.prop_union_buildlv) do
        if v.Mode == class and v.Lv == lv then
            return v
        end
    end
end

function on_destory(self)
    local db = dbmng:getOne()
    db.union_build:delete({_id=self._id})
end

function get_range(self)
    assert(self)
    return self:get_ef().Range or 0
end

function get_cross_point(self, x1, y1, x2, y2)
    local cc = resmng.prop_world_unit[self.propid]
    local l, r = self.x - self:get_range(), self.x + self:get_range() + cc.Size
    local d, u = self.y - self:get_range(), self.y + self:get_range() +  cc.Size

    local points = {}
    local function point(x, y)
        for _, v in pairs(points) do
            if v.x == x and v.y == y then
                return
            end
        end
        points[#points + 1] = {x=x,y=y}
    end
    local function con(x, l, r)
        if l <= r then
            return l <= x and x <= r
        else
            return r <= x and x <= l
        end
    end

    if con(x1, l, r) and con(y1, d, u) then point(x1, y1) end
    if con(x2, l, r) and con(y2, d, u) then point(x2, y2) end

    local s = (y1 -y2) / (x1 - x2)

    local ly = s * (l - x1) + y1
    if con(ly, d, u) and con(ly, y1, y2) then point(l,ly) end

    local ry = s * (r - x1) + y1
    if con(ry, d, u) and con(ry, y1, y2) then point(r,ry) end

    local ux = 1 / s * (u - y1) + x1
    if con(ux, l, r) and con(ux, x1, x2) then point(ux,u) end

    local dx = 1 / s * (d - y1) + x1
    if con(dx, l, r) and con(dx, x1, x2) then point(dx,d) end

    assert(#points <= 2)

    return points[1], points[#points]
end

