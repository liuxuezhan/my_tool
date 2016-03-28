module("restore_handler", package.seeall)

function load_player()
    local db = dbmng:getOne()
    local info = db.player:find({})
    local count = 0
    local total = 0
    while info:hasNext() do
        local p = player_t.new(info:next())
        p.propid = resmng.PLY_CITY_ROME_1
        p.size = 4
        etypipe.add(p)
        gEtys[ p.eid ] = p
        mark_eid(p.eid)
        rawset(p, "eid", p.eid)
        count = count + 1
        if count >= 1000 then
            total = total + 1000
            LOG("load player %d", total)
            mem_info()
            count = 0
        end
    end
    total = total + count
    INFO("total player %d", total)
end


function load_build()
    local db = dbmng:getOne()
    local info = db.build:find({})
    while info:hasNext() do
        local b = info:next()
        local p = getPlayer(b.pid)
        if p then
            local bs = p._build
            if not bs then
                bs = {}
                p._build = bs
            end
            bs[ b.idx ] = build_t.new(b)
        end
    end
end

function load_troop()
    local db = dbmng:getOne()
    local info = db.troop:find({})
    while info:hasNext() do
        local b = troop_t.new(info:next())
        local p = getPlayer(b.pid)
        if p then
            if not p._troop then
                p._troop = {}
            end
            p._troop[ b.idx ] = b

            mark_eid(b.eid)

            local Au = p:union()
            if Au then Au:enroll_fight(b) end

            local dp = get_ety(b.did)

            if b.action == resmng.TroopAction.Aid then
                if dp then
                    if not dp.aid then dp.aid = {} end
                    table.insert(dp.aid, b)
                end
            end

            if is_union_building(dp) and b.state ~= resmng.TroopState.Back then
                local u = unionmng.get_union(dp.uid or 0 )
                if u then
                    unoin_build_t.troop_go(dp._id,b.pid,b.idx)
                end
            end
            if b.show and b.show > 0 then
                troop_t.do_show(b)
            end
        end
    end
end

function load_npc_city()
    local db = dbmng:getOne()
    local info = db.npc_city:find({})
    local have = {}
    while info:hasNext() do
        local c = info:next()
        local n = resmng.prop_world_unit[ c.propid ]
        if n then
            gEtys[ c.eid ] = c
            mark_eid(c.eid)
            etypipe.add(c)
            have[ n.ID ] = c
        end
    end

    for k, v in pairs(resmng.prop_world_unit) do
        if v.Class == CLASS_UNIT.NPC_CITY then
            if not have[ v.ID ] then
                if c_map_test_pos(v.X, v.Y, v.Size) == 0 then
                    local eid = get_eid_npc_city()
                    if eid then
                        print(eid)
                        local c = {_id=eid, eid=eid, x=v.X, y=v.Y, propid=k, size=v.Size, uid=0}
                        gEtys[ eid ] = c

                        mark_eid(eid)
                        etypipe.add(c)
                        db.npc_city:insert(c)
                    end
                end
            end
        end
    end
end

function load_hero()
    local db = dbmng:getOne()
    local info = db.hero:find({})
    while info:hasNext() do
        local b = info:next()
        local p = getPlayer(b.pid)
        if p then
            if not p._hero then
                p._hero = {}
            end
            local hero = hero_t.wrap(b)
            p._hero[ b.idx ] = hero
            heromng.add_hero(hero)
        end
    end
end

function load_union()
    local db = dbmng:getOne()
    local info = db.union:find({})
    while info:hasNext() do
        local union = union_t.new(info:next())
        unionmng._us[union.uid] = union
    end

    info = db.union_log:find({})
    while info:hasNext() do
        local log = union_t.new(info:next())
        local csn = 0
        for _, v in pairs(log.log) do
            if csn < v.sn then
                csn = v.sn
            end
        end

        unionmng._us[log._id].log = log
        unionmng._us[log._id].log_csn = csn
    end

end

function load_union_member()
    local db = dbmng:getOne()
    local info = db.union_member:find({})
    while info:hasNext() do
        local data = info:next()
        local p = getPlayer(data.pid)
        if p then
            p._union = union_member_t.new(data)
            local union = unionmng.get_union(p:get_uid())
            if union then
                union._members[p.pid] = p
            end
        else
            print("load_union_member, not found player", data.pid)
        end
    end
end

function load_union_tech()
    local db = dbmng:getOne()
    local info = db.union_tech:find({})
    while info:hasNext() do
        local data = info:next()
        local union = unionmng.get_union(data.uid)
        if union then
            union._tech[data.idx] = union_tech_t.new(data)
        end
    end
end

function load_union_build()
    local db = dbmng:getOne()
    local info = db.union_build:find({})
    while info:hasNext() do
        local data = info:next()
        local u = unionmng.get_union(data.uid)
        if u then
            u.build[data.idx] = data
            gEtys[ data.eid ] = data 

            print("union_build,", data.eid)
            mark_eid(data.eid)
            etypipe.add(data)
            union_build_t.set_sn(data.sn)
        end
    end
end

function load_sys_status()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id=gMapID})
    dumpTab(info, "SysStatus")
    if not info then
        info = {_id=gMapID, start=gTime, ids={}}
        db.status:insert(info)
    end
    gSysStatus = info
end

function init_effect()
    for _, v in pairs(gPlys) do
        v:initEffect()
    end
end

function load_sys_mail()
    local db = dbmng:getOne()
    local info = db.mail:find({to=0})
    local mails = {}
    local sn = 0
    while info:hasNext() do
        local v = info:next()
        table.insert(mails, v)
        if v.idx > sn then sn = v.idx end
    end
    table.sort(mails,function(l, r) return l.idx < r.idx end)
    _G.gSysMailSn = sn
    _G.gSysMail = mails
end

--任务
function load_task()
    local db = dbmng:getOne()
    local info = db.task:find({})
    while info:hasNext() do
        local line = info:next()
        local player = getPlayer(line._id)
        if player ~= nil then
            player:init_task()
            player:init_from_db(line)
        end
    end
end


function restore_timer()

    local ghostNewTimer = timer.newTimer
    timer.newTimer = function() end

    local db = dbmng:getOne()
    local info = db.timer:find({})

    while info:hasNext() do
        local t = info:next()
        timer._sns[ t._id ] = t
    end

    local funMin = function()
        local min = math.huge
        local k = false
        for sn, v in pairs(timer._sns) do
            if v.over < min then
                k = sn
                min = v.over
            end
        end
        return k
    end

    _G.gTime = 0
    _G.gMsec = 0
    local start = 0

    while true do
        local id = funMin()
        if not id then break end
        local node = timer.get(id)

        print(string.format("over:%d, real:%d, action=%s", node.over, real_gTime, node.what))

        if node.over > real_gTime then break end

        if _G.gTime == 0 then
            _G.gTime = node.over
            start = node.over
        end

        _G.gTime = node.over
        _G.gMsec = (node.over - start) * 1000

        timer.callback(node._id, node.tag)
    end

    timer.newTimer = ghostNewTimer
    _G.gTime = real_gTime
    _G.gMsec = real_gMsec

    for k, node in pairs(timer._sns) do
        if node.what == "cron" then
            timer.del(node._id)
        else
            addTimer(node._id, (node.over-gTime)*1000, node.tag or 0)
        end
    end
end

function renewTimer()
    for _, p in pairs(gPlys) do
        local bs = p._build
        if bs then
            for _, b in pairs(bs) do
                if b.tmOver and b.tmOver > 0 then
                    b.tmSn = timer.new("build", b.tmOver - _G.gTime, p.pid, b.idx)
                else
                    if b.tmSn ~= 0 then b.tmSn = 0 end
                end
            end
        end

        local ts = p:get_troop()
        if ts then
            for _, t in pairs(ts) do
                if t.tmOver and t.tmOver > 0 then
                    t.tmSn = timer.new("troop", t.tmOver - _G.gTime, t.pid, t.idx)
                end
            end
        end
    end

    for _, union in pairs(unionmng.get_all()) do
        for _, t in pairs(union.mass or {}) do
            if t.tmOver and t.tmOver > 0 then
                t.tmSn = timer.new("mass", t.tmOver - _G.gTime, union.uid, t.idx)
            end
        end

        for _, t in pairs(union._tech) do
            if t.tmOver and t.tmOver > 0 then
                t.tmSn = timer.new("uniontech", t.tmOver - _G.gTime, union.uid, t.idx)
            end
        end

        for _, t in pairs(union.build) do
            if t.tmOver and t.tmOver > 0 then
                t.tmSn = timer.new("unionbuild", t.tmOver - _G.gTime, t._id)
            end
        end
    end
end

function post_init()
    c_roi_view_start()
end

function action()

    INFO("-- load_union --------------")
    load_union()
    INFO("-- load_union done ---------")

    INFO("-- load_player -------------")
    load_player()
    INFO("-- load_player done --------")

    INFO("-- load_build --------------")
    load_build()
    INFO("-- load_build done ---------")

    INFO("-- load_union_member -------")
    load_union_member()
    INFO("-- load_union_member done --")

    INFO("-- load_union_tech ---------")
    load_union_tech()
    INFO("-- load_union_tech done ----")

    INFO("-- load_npc_city -----------")
    load_npc_city()
    INFO("-- load_npc_city -----------")

    INFO("-- load_troop --------------")
    load_troop()
    INFO("-- load_troop done ---------")

    INFO("-- load_union_build --------")
    load_union_build()
    INFO("-- load_union_build done ---")

    INFO("-- load_hero ---------------")
    load_hero()
    INFO("-- load_hero done ----------")

    INFO("-- init_effect -------------")
    init_effect()
    INFO("-- init_effect done --------")

    INFO("-- load_monster ------------")
    monster.load_from_db()
    INFO("-- load_monster done--------")

    INFO("-- restore_load_farm -----")
    farm.load_from_db()
    INFO("-- restore_load_farm done-")

    INFO("-- restore_timer -----------")
    restore_timer()
    INFO("-- restore_timer done ------")

    INFO("-- restore_system_mail -----")
    load_sys_mail()
    INFO("-- restore_system_mail done-")

    INFO("-- restore_room -----")
    room.load()--在troop之后
    INFO("-- restore_room done-")

    INFO("-- restore_task -----")
    load_task()
    INFO("-- restore_task done -----")

    post_init()
    INFO("-- done done done ----------")

end


