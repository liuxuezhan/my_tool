module("monster", package.seeall)

distrib = distrib or {}
scan_id = scan_id or 0

_mt = {__index = monster}

function checkin(m)
    local zx = math.floor(m.x / 16)
    local zy = math.floor(m.y / 16)
    local idx = zy * 80 + zx
    local node = distrib[ idx ]
    if not node then
        node = {}
        distrib[ idx ] = node
    end
    table.insert(node, m.eid)
end

function checkout(m)
    if m.mark then
        local db = dbmng:getOne(m.eid)
        db.monster:delete({_id=m._id})
    end
    local x = m.x
    local y = m.y
    do_check(x/16, y/16)
end

function respawn(tx, ty)
    local x, y = c_get_pos_in_zone(tx, ty, 1, 1)
    if x then
        local eid = get_eid_monster()
        if eid then
            local lv = c_get_zone_lv(tx, ty)
            local prop = get_monster_by_zone_lv(lv)
            local m = create_monster(prop)

            m._id = eid
            m.eid = eid
            m.x = x
            m.y = y
            m.born = gTime
            setmetatable(m, _mt)
            gEtys[ eid ] = m
            etypipe.add(m)

            checkin(m)
        end
    end
end

function load_from_db()
    local db = dbmng:getOne()
    local info = db.monster:find({})
    while info:hasNext() do
        local m = info:next()
        setmetatable(m, _mt)
        gEtys[ m.eid ] = m
        mark_eid(m.eid)

        print("monster m.eid =", m.eid)
        etypipe.add(m)
        checkin(m)
    end
end

function do_check(zx, zy)
    zx = math.floor(zx)
    zy = math.floor(zy)
    if zx >= 0 and zx < 80 and zy >= 0 and zy < 80 then
        local idx = zy * 80 + zx
        local node = distrib[ idx ]

        local news = {}
        for k, eid in pairs(node or {})  do
            local ety = get_ety(eid)
            if ety then
                if not is_focus(ety) and gTime - ety.born > 12 * 3600 then
                    rem_ety(ety)
                else
                    table.insert(news, eid)
                end
            end
        end
        distrib[ idx ] = news

        local num = #news
        local access = c_get_map_access(zx, zy)
        if math.abs(gTime - access) > 3600 then
            if num == 0 then
                distrib[ idx ] = nil
            end
        elseif num < 2 then
            for i = num+1, 2, 1 do
                respawn(zx, zy)
            end
        end
    end
end

function loop()
    local idx = scan_id
    for i = 1, 80, 1 do
        if idx >= 6400 then idx = 0 end
        if distrib[ idx ] then
            local zx = idx % 80
            local zy = math.floor(idx / 80)
            scan_id = idx
            do_check(zx, zy)
        end
        idx = idx + 1
    end
end

function get_monster_by_zone_lv(lv)
    if gTime % 2 == 0 then
        --return resmng.prop_monster[ resmng.MON_1001]
        return resmng.prop_world_unit[ resmng.MONSTER_1 ]
    else
        --return resmng.prop_monster[ resmng.MON_1002]
        return resmng.prop_world_unit[ resmng.MONSTER_2 ]
    end
end

function create_monster(prop)
    local arms = {
        {num=0, mode=1, objs={}},
        {num=0, mode=2, objs={}},
        {num=0, mode=3, objs={}},
        {num=0, mode=4, objs={}}
    }

    for _, v in ipairs(prop.Arms) do
        local id = v[1]
        local num = v[2]
        local p = resmng.prop_arm[ id ]
        if p then
            local arm = arms[ p.Mode ]
            table.insert(arm.objs, {id=id, num=num})
            arm.num = arm.num + num
        end
    end

    if prop.Heros then
        for mode, v in pairs(prop.Heros) do
            local p = resmng.prop_hero[ v ]
            if p then
                local arm = arms[ mode ]
                table.insert(arm.objs, {id=v, num=1, hero=1})
                arm.num = arm.num + 1
            end
        end
    end

    return {propid=prop.ID, arms=arms, born=gTime}
end

function init_def_troop(m)
    m.action = "defend"
    m.aid=m.eid
    return m
end

function mark(m)
    local db = dbmng:getOne(m.eid)
    if not m.marktm then
        m.marktm = gTime
        db.monster:insert(m)
    else
        m.marktm = gTime
        db.monster:update({_id=m._id}, m)
    end
end

function troop_home(m)
    if m.live > 0 then
        local arms = m.arms
        for _, arm in pairs(arms) do
            for _, obj in pairs(arm.objs) do
                obj.hurt = 0
                obj.dead = 0
            end
        end
        m:mark()
    else
        rem_ety(m.eid)
    end
end

