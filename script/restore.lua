module("restore", package.seeall)

function load_player()
    local db = dbmng:getOne()
    local info = db.player:find({})
    local count = 0
    local total = 0
    while info:hasNext() do
        local p = player_t.new(info:next())
        --local vobj = {eid=p.eid, x=p.x, y=p.y, name=p.name, lv=p.lv, photo=p.photo, pid=p.pid}
        --c_add_ety(p.eid, p.x, p.y, 4, 1, MsgPack.pack(vobj))
        etypipe.add(p)
        gEtys[ p.eid ] = p
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

    --[[
    local info = db.item:find({})
    while info:hasNext() do
        local its = info:next()
        local pid = false

        local ts = {}
        for k, v in pairs(its) do
            if k == "_id" then
                pid = v
            else
                ts[ tonumber(k) ] = v
            end
        end
        local p = getPlayer(pid)
        rawset(p, "_item", ts)
    end

    local info = db.build:find({})
    while info:hasNext() do
        local b = build_t.new(info:next())
        local p = getPlayer(b.pid)
        if p then
            if not p._build then p._build = {} end
            p._build[ b.idx ] = b
        end
    end
    ]]
end


function load_build()
    local db = dbmng:getOne()
    local info = db.build:find({tmSn={["$gt"]=0} }, {pid=1, propid=1, tmOver=1, tmSn=1})

    local pids = {}
    while info:hasNext() do
        local t = info:next()
        pids[ t.pid ] = 1
        print(string.format("pid=%d, propid=%d, tmOver=%d, tmSn=%d", t.pid, t.propid, t.tmOver, t.tmSn))
    end

    for pid, _ in pairs(pids) do
        INFO("load_build for player %d", pid)
        local p = getPlayer(pid)
        if p then
            p:get_build()
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
            if b.show and b.show > 0 then
                troop_t.do_show(b)
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
            u.build[data.idx] = union_build_t.new(data)
            etypipe.add(u.build[data.idx])
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
        if v._id > sn then sn = v._id end
    end
    table.sort(mails,function(l, r) return l._id < r._id end)
    _G.gSysMailSn = sn
    _G.gSysMail = mails
end

function restore_timer()
    local db = dbmng:getOne()
    local info = db.build:find({tmSn={["$gt"]=0} }, {pid=1, propid=1, tmOver=1, tmSn=1})

    local pids = {}
    while info:hasNext() do
        local t = info:next()
        dumpTab(t, "loadbuild")
        pids[ t.pid ] = 1
    end

   for pid, _ in pairs(pids) do
        INFO("load_build for player %d", pid)
        local p = getPlayer(pid)
        if p then
            p:get_build()
        end
    end

    local info = db.troop:find({})
    while info:hasNext() do
        local b = troop_t.new(info:next())
        local p = getPlayer(b.pid)
        if p then
            INFO("load_troop for player %d", p.pid)
            if not p._troop then p._troop = {} end
            p._troop[ b.idx ] = b

            --
            local Au = p:union()
            if Au then Au:enroll_fight(b) end
            if is_ply(b.did) then
                local Du = get_ety(b.did):union()
                if Du then Du:enroll_fight(b) end
            end

            --
            if b.action == resmng.TroopAction.Aid then
                local pb = get_ety(b.did)
                if pb then
                    if not pb.aid then pb.aid = {} end
                    table.insert(pb.aid, b)
                end
            end

            if b.show and b.show > 0 then
                troop_t.do_show(b)
            end
        end
    end

    local ghostNewTimer = timer.newTimer
    timer.newTimer = function() end

    print("gTime = ", gTime)
    print("_G.gTime = ", _G.gTime)

    _G.gTime = 0
    _G.gMsec = 0

    print("gTime = ", gTime)
    print("_G.gTime = ", _G.gTime)

    renewTimer()

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

    while true do
        local sn = funMin()
        if not sn then break end
        local node = timer.get(sn)

        print(string.format("over:%d, real:%d, action=%s", node.over, real_gTime, node.what))
        if node.over > real_gTime then break end
        if _G.gTime == 0 then
            _G.gTime = node.over
            _G.gMsec = 0
        end
        _G.gMsec = (node.over - _G.gTime) * 1000 + _G.gMsec
        _G.gTime = node.over
        timer.callback(node.sn, node.tag)
    end

    _G.gTime = real_gTime
    _G.gMsec = real_gMsec

    timer.newTimer = ghostNewTimer
    timer._sns = {}
    renewTimer()
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

    INFO("-- load_union_member -------")
    load_union_member()
    INFO("-- load_union_member done --")

    INFO("-- load_union_tech -------")
    load_union_tech()
    INFO("-- load_union_tech done --")

    INFO("-- load_union_build -------")
    load_union_build()
    INFO("-- load_union_build done --")

    --INFO("-- load_build --------------")
    --load_build()
    --INFO("-- load_build done ---------")

    --INFO("-- load_troop --------------")
    --load_troop()
    --INFO("-- load_troop done ---------")

    INFO("-- load_hero ---------------")
    load_hero()
    INFO("-- load_hero done ----------")

    --INFO("-- init_effect -------------")
    --init_effect()
    --INFO("-- init_effect done --------")

    INFO("-- restore_load_monster -----")
    monster.load_from_db()
    INFO("-- restore_load_monster done-")

    INFO("-- restore_load_farm -----")
    farm.load_from_db()
    INFO("-- restore_load_farm done-")

    INFO("-- restore_timer -----------")
    restore_timer()
    INFO("-- restore_timer done ------")

    INFO("-- restore_system_mail -----")
    load_sys_mail()
    INFO("-- restore_system_mail done-")


    post_init()
    INFO("-- done done done ----------")

end


