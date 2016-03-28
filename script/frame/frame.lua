local thanksgiving = [[
                   _ooOoo_
                  o8888888o
                  88" . "88
                  (| -_- |)
                  O\  =  /O
               ____/`---'\____
             .'  \\|     |//  `.
            /  \\|||  :  |||//  \
           /  _||||| -:- |||||-  \
           |   | \\\  -  /// |   |
           | \_|  ''\---/''  |   |
           \  .-\__  `-`  ___/-. /
         ___`. .'  /--.--\  `. . __
      ."" '<  `.___\_<|>_/___.'  >'"".
     | | :  `- \`.;`\ _ /`;.`/ - ` : | |
     \  \ `-.   \_ __\ /__ _/   .-` /  /
======`-.____`-.___\_____/___.-`____.-'======
                   `=---='
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
]]

gNetPt = {
    NET_PING        = 1,
    NET_PONG        = 2,
    NET_ADD_LISTEN  = 3,
    NET_ADD_INCOME  = 4,
    NET_CMD_CLOSE   = 5,
    NET_MSG_CLOSE   = 6 ,
    NET_CMD_STOP    = 7,
    NET_SET_MAP_ID  = 8,
    NET_SET_SRV_ID  = 9,
    NET_MSG_CONN_COMP = 10 ,
    NET_MSG_CONN_FAIL  = 11,
    NET_ECHO = 12,
    NET_CHG_SRV = 13,
    NET_CERTIFY = 14,
    NET_SEND_MUL = 15,
}

gDbNum = 16

function loadMod()
    require("frame/tools")
    require("frame/debugger")
    require("frame/conn")
    require("frame/crontab")
    require("frame/dbmng")
    require("frame/timer")
    require("frame/socket")

    _G.mongo = require("frame/mongo")

    -- rpc
    require("frame/class")

    doLoadMod("packet", "frame/rpc/packet")
    doLoadMod("MsgPack", "frame/MessagePack")
    doLoadMod("Array", "frame/rpc/array")
    doLoadMod("Struct", "frame/rpc/struct")
    doLoadMod("RpcType", "frame/rpc/rpctype")
    doLoadMod("Rpc", "frame/rpc/rpc")

    require("frame/player_t")

end

function handle_dbg(sid)
    local co = getCoroPend("dbg", sid)
    if not co then
        co = createCoro("dbg")
        gCoroPend[ "dbg" ][ sid ] = co
    end
end

function handle_network(sid)
    local pktype = pullInt()
    local p = gConns[ sid ]
    if p then
        if pktype ==  gNetPt.NET_MSG_CLOSE then
            LOG("handle_network, sid=%d, pktype=NET_MSG_CLOSE", sid)
            gConns[ sid ] = nil
            p:onClose()

        elseif pktype == gNetPt.NET_MSG_CONN_COMP then
            p:onConnectOk()

        elseif pktype == gNetPt.NET_MSG_CONN_FAIL then
            LOG("handle_network, sid=%d, pktype=NET_MSG_CONN_FAIL", sid)
            gConns[ sid ] = nil
            p:onConnectFail()

        end
    end
end

function handle_db(sid)
    mongo.recvReply(sid)
end

gTagFun = {}
gTagFun[1] = handle_network
gTagFun[2] = handle_db
gTagFun[3] = handle_dbg

function action(func, ...)
    table.insert(gActions, {func, arg})
    begJob()
end


function do_threadAction()
    local co = coroutine.running()
    while true do
        while #gActions > 0 do
            local node = table.remove(gActions, 1)
            if node[2] then
                node[1](unpack(node[2]))
            else
                node[1]()
            end
        end
        if gCoroBad[ co ] then
            gCoroBad[ co ] = nil
            LOG("Coro, threadAction, i should go away, %s", co)
            return
        end
        putCoroPool("action")
    end
end

function do_threadTimer()
    local co = coroutine.running()

    local sn, tag
    while true do
        sn = false
        while true do
            sn, tag = pullTimer()
            if not sn then
                putCoroPool("timer")
            else
                --LOG("threadTimer, sn=%d", sn)
                break
            end
        end
        timer.callback(sn, tag)

        if gCoroBad[ co ] then
            gCoroBad[ co ] = nil
            LOG("Coro, threadTimer, i should go away, %s", co)
            return
        end

    end
end

gActionQue = {}
gActionCur = {}
function do_threadPK()
    local co = coroutine.running()

    while true do
        local gateid, tag
        while true do
            gateid, tag = pullNext()
            if gateid then
                break
            else
                local dels = {}
                for pid, as in pairs(gActionQue) do
                    local tmMark = gActionCur[ pid ]
                    if not tmMark or gTime - tmMark > 2 then -- maybe something wrong, so leave the gActionCur unclear
                        if #as == 0 then
                            table.insert(dels, pid)
                        else
                            while #as > 0 do
                                local v = table.remove(as, 1)
                                gActionCur[ pid ] = gTime
                                LOG("%d, RpcR, pid=%d, func=%s, delay do", gFrame, pid, v[1])
                                LOG("RpcR, pid=%d, func=%s", pid, v[1])
                                local p = getPlayer(pid)
                                if p then player_t[ v[1] ](p, unpack(v[2]) ) end
                                gActionCur[ pid ] = nil
                            end
                            table.insert(dels, pid)
                        end
                    end
                end
                for k, v in pairs(dels) do
                    gActionQue[ v ] = nil
                end
                putCoroPool("pk")
            end
        end

        if tag then
            if gTagFun[ tag ] then
                gTagFun[ tag ](gateid)
            end
        else
            local pid = pullInt()
            local pktype = pullInt()
            local fname, args = Rpc:parseRpc(packet, pktype)
            if fname then
                local p = getPlayer(pid)
                if p then
                    p.gid = gateid
                    if pid == 0 then
                        LOG("RpcR, pid=%d, func=%s", pid, fname)
                        --public_t[ fname ](p, gateid, unpack(args))
                        player_t[ fname ](p, unpack(args) )
                    else
                        if gActionQue[ pid ] then
                            table.insert(gActionQue[ pid ], {fname, args})
                            LOG("%d, RpcR, pid=%d, func=%s, in queue", gFrame, pid, fname)
                        elseif gActionCur[ pid ] then
                            gActionQue[ pid ] = { {fname, args} }
                            LOG("%d, RpcR, pid=%d, func=%s, new queue", gFrame, pid, fname)
                        else
                            gActionCur[ pid ] = gTime
                            player_t[ fname ](p, unpack(args) )
                            gActionCur[ pid ] = nil
                            LOG("RpcR, pid=%d, func=%s", pid, fname)
                        end
                    end
                else
                    LOG("RpcR, pid=%d, func=%s, no player", pid, Rpc.localF[pktype].name)
                end
            end
        end

        if gCoroBad[ co ] then
            gCoroBad[ co ] = nil
            LOG("Coro, threadPk, i should go away, %s", co)
            return
        end
    end
end


function threadAction()
    if _ENV then
        xpcall(do_threadAction, function(e)
            WARN("[ERROR]%s", e)
            print(c_get_top())
        end)
    else
        do_threadAction()
    end
end

function threadTimer()
    if _ENV then
        xpcall(do_threadTimer, function(e) WARN("[ERROR]%s", e) end)
    else
        do_threadTimer()
    end
end

function threadPk()
    if _ENV then
        xpcall(do_threadPK, function(e) WARN("[ERROR]%s", e) end)
    else
        do_threadPK()
    end
end

function wait_db_connect()
    for k, v in pairs(gConns) do
        if v.state ~= 1 then
            wait(1)
        end
    end
end

function frame_init()
    wait_db_connect()
    INFO("$$$ done wait_db_connect")
    load_sys_config()
    INFO("$$$ done load_sys_config")
    load_uniq()
    INFO("$$$ done load_uniq")
    gInit = "InitFrameDone"
    begJob()
end

function main_loop(sec, msec, fpk, ftimer, froi, deb)
    gFrame = gFrame + 1
    LOG("gFrame = %d, fpk=%d, ftimer=%d, froi=%d, deb=%d, gInit=%s", gFrame, fpk, ftimer, froi, deb, gInit or "unknown")

    if deb > 0 then
        if pause then
            pause("debug in main_loop")
        else
            os.exit(-1)
        end
    end

    if gInit then
        real_gTime = sec
        real_gMsec = msec

        if gInit == "StateBeginInit" then
            gInit = "InitFrameAction"
            action(frame_init)
        elseif gInit == "InitFrameDone" then
            gInit = "InitGameAction"
            action(restore_game_data)
        elseif gInit == "InitGameDone" then
            conn.toGate(config.GateHost, config.GatePort)

            crontab.initBoot()

            local nextCron = 60 - (gTime % 60) + 30
            timer.new("cron", nextCron)

            INFO("")
            INFO("========================")
            INFO("------------------------")
            INFO(":-)  done_done_done  (-:")
            INFO("------------------------")
            INFO("========================")
            INFO("")
    
local thanksgiving = [[
                   _ooOoo_
                  o8888888o
                  88" . "88
                  (| -_- |)
                  O\  =  /O
               ____/`---'\____
             .'  \\|     |//  `.
            /  \\|||  :  |||//  \
           /  _||||| -:- |||||-  \
           |   | \\\  -  /// |   |
           | \_|  ''\---/''  |   |
           \  .-\__  `-`  ___/-. /
         ___`. .'  /--.--\  `. . __
      ."" '<  `.___\_<|>_/___.'  >'"".
     | | :  `- \`.;`\ _ /`;.`/ - ` : | |
     \  \ `-.   \_ __\ /__ _/   .-` /  /
======`-.____`-.___\_____/___.-`____.-'======
                   `=---='
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
]]
        print(thanksgiving)

INFO([[                   _ooOoo_]])
INFO([[                  o8888888o]])
INFO([[                  88" . "88]])
INFO([[                  (| -_- |)]])
INFO([[                  O\  =  /O]])
INFO([[               ____/`---'\____]])
INFO([[             .'  \\|     |//  `.]])
INFO([[            /  \\|||  :  |||//  \]])
INFO([[           /  _||||| -:- |||||-  \]])
INFO([[           |   | \\\  -  /// |   |]])
INFO([[           | \_|  ''\---/''  |   |]])
INFO([[           \  .-\__  `-`  ___/-. /]])
INFO([[         ___`. .'  /--.--\  `. . __]])
INFO([[      ."" '<  `.___\_<|>_/___.'  >'"".]])
INFO([[     | | :  `- \`.;`\ _ /`;.`/ - ` : | |]])
INFO([[     \  \ `-.   \_ __\ /__ _/   .-` /  /]])
INFO([[======`-.____`-.___\_____/___.-`____.-'======]])
INFO([[                   `=---=']])
INFO([[^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^]])


            gInit = nil
        end

        begJob()
    else
        gTime = sec
        gMsec = msec
    end

    if fpk == 1 then
        while true do
            local co = getCoroPool("pk")
            local flag, what, id = coroutine.resume(co)
            if flag then
                if what == "ok" then break end
            else
                LOG("ERROR %s", what)
            end
        end
    end

    if ftimer == 1 then
        while true do
            local co = getCoroPool("timer")
            local flag, what, id = coroutine.resume(co)
            if flag then
                if what == "ok" then break end
            else
                LOG("ERROR %s", what)
            end
        end
    end

    if froi == 1 then
        while true do
            local msg, d0, d1, d2, d3, d4, d5, d6, d7 = c_pull_msg_roi()
            if not msg then break end
            if do_roi_msg then do_roi_msg(msg, d0, d1, d2, d3, d4, d5, d6, d7) end
        end
    end

    if #gActions > 0 then
        local co = getCoroPool("action")
        local flag = coroutine.resume(co)
    end

    while #gCoroWait > 0 do
        local t = gCoroWait[1]
        if t[2] > gFrame then break end
        LOG("dowait, %d, %d", t[2], gFrame)
        table.remove(gCoroWait,1)
        coroutine.resume(t[1])
    end

    check_pending()

    global_save()
end


--so when you want to save data, just write down like
--gPendingSave.mail[ "1_270130" ].tm_lock = gTime
function global_save()
    local db = dbmng:tryOne(1)
    if db then
        local update = false
        for tab, doc in pairs(gPendingSave) do
            local cache = doc.__cache
            for id, chgs in pairs(doc) do
                if chgs ~= cache then
                    db[ tab ]:update({_id=id}, {["$set"] = chgs }, true)
                    print("update", tab, id, gFrame)
                    update = true
                    chgs._n_ = gFrame
                    doc[ id ] = nil
                    cache[ id ] = chgs
                end
            end
        end
        if update then check_save(db, gFrame)() end
    end
end


function check_save(db, frame)
    local f = function()
        local info = db:runCommand("getLastError")
        --dumpTab(info, "check_save")
        if info.ok then
            local code = info.code
            for tab, doc in pairs(gPendingSave) do
                local cache = doc.__cache
                local dels = {}
                for id, chgs in pairs(cache) do
                    if chgs._n_ == frame then
                        print("ack", id, frame, gFrame)
                        table.insert(dels, id)
                        if code then dumpTab(chgs, "maybe error") end
                    elseif chgs._n_ < frame - 10 then
                        chgs._n_ = nil
                        doc[ id ] = chgs
                        print("retry", id, frame, gFrame)
                        table.insert(dels, id)
                    end
                end
                if #dels > 0 then
                    for _, v in pairs(dels) do
                        cache[ v ] = nil
                    end
                end
            end

            if info.code then
                dumpTab(info, "check_save")
            end
        end
    end
    return coroutine.wrap(f)
end


function wait(nframe)
    nframe = nframe or 1
    if nframe < 1 then nframe = 1 end
    nframe = nframe + gFrame

    local co = coroutine.running()
    for k, v in ipairs(gCoroWait) do
        if nframe <= v[2] then
            table.insert(gCoroWait, k, {co, nframe})
            coroutine.yield("wait")
            return
        end
    end
    table.insert(gCoroWait, {co, nframe})
    coroutine.yield("wait")
end

function init(sec, msec)
    gTime = math.floor(sec)
    gMsec = math.floor(msec)
    gMapID = getMap()
    gMapNew = 1

    math.randomseed(sec)

    gCoroPool = { ["pk"] = {}, ["timer"] = {}, ["action"] = {} }
    gCoroPend = { ["db"] = {}, ["rpc"] = {} }
    gCoroWait = {}

    gActions = {}
    gSns = {}
    gFrame = 0
    gConns = {}
    gPlys = {}
    gAccs = {}
    gEtys = {}
    gPendingSave = {}

    __mt_rec = {
        __index = function (self, recid) 
            local t = self.__cache[ recid ]
            if t then 
                self.__cache[ recid ] = nil
                t._n_ = nil 
            else 
                t = {} 
            end
            self[ recid ] = t
            return t
        end
    }
    __mt_tab = {
        __index = function (self, tab) 
            local t = { __cache={} }
            setmetatable(t, __mt_rec)
            self[ tab ] = t
            return t
        end
    }
    setmetatable(gPendingSave, __mt_tab)

    gInit = "StateBeginInit"
    loadMod()
    require("game")

    load_game_module()

    LOG("start: gTime = %d, gMsec = %d", gTime, gMsec)

    Rpc:init("server")
    Rpc.localF[ 6 ] = Rpc.localF[ hashStr("onBreak") ]

    dofile("../etc/config.lua")

    if config.Tips then
        c_init_log(config.Tips)
    end

    --local dbname = string.format("warx_%d", gMapID)
    local name = config.Game or "warx"
    local dbname = string.format("%s_%d", name, gMapID)
    for i = 1, gDbNum, 1 do
        conn.toMongo(config.DbHost, config.DbPort, dbname)
    end

    local dbnameG = string.format("%sG", name)
    if config.DbHostG then
        conn.toMongo(config.DbHostG, config.DbPortG, dbnameG, "Global")
    end

    begJob()

    return 1
end


function createCoro(what)
    if what == "pk" then
        return coroutine.create(threadPk)
    elseif what == "timer" then
        return coroutine.create(threadTimer)
    elseif what == "action" then
        return coroutine.create(threadAction)
    end
end

function getCoroPool(what)
    if #gCoroPool[ what ] > 0 then
        local co = table.remove(gCoroPool[ what ])
        return co
    else
        local co = createCoro(what)
        return co
    end
end

function putCoroPool(what)
    local co = coroutine.running()
    table.insert(gCoroPool[ what ], co)
    coroutine.yield("ok")
end

function getCoroPend(what, id)
    local co = gCoroPend[ what ][ id ]
    if co then
        gCoroPend[ what ][ id ] = nil
        if type(co) == "table" then return unpack(co)
        else return co end
    end
end


function putCoroPend(what, id, extra)
    local co = coroutine.running()
    if extra then gCoroPend[ what ][ id ] = { co, extra }
    else gCoroPend[ what ][ id ] = co end
    return coroutine.yield(what)
end


function addPendSave(tab, id, key, val)
    local g = gPendingSave
    if not g then
        g = {}
        gPendingSave = g
    end

    local t = g[ tab ]
    if not t then
        t = {}
        g[ tab ] = t
    end

    local r = t[ id ]
    if not r then
        r = {}
        t[ id ] = r
    end

    r[ key ] = val
end

function getPlayer(pid)
    if pid then
        return gPlys[ pid ]
    end
end

function load_sys_config()
    local db = dbmng:getByTips("Global")
    local info = db.config:findOne({_id=gMapID})
    if info then
        gSysConfig = info
    else
        gSysConfig = {_id=gMapID, create=gTime}
        db.config:insert(gSysConfig)
    end
end

function load_uniq()
    local db = dbmng:getOne()
    local info = db.uniq:find({})
    gUniqs = {}
    if info then
        while info:hasNext() do
            local b = info:next()
            gUniqs[ b._id ] = b
        end
    end
end

function getId(what)
    local t = gUniqs[ what ]
    if not t then
        t = {_id=what, at=0, sn=0, wait=1}
        gUniqs[ what ] = t
        local idx = getAutoInc(what)
        t.at=idx
        t.wait = 0
        db = dbmng:getOne()
        db.uniq:insert(t)
    end

    for i = 1, 1000, 1 do
        if t.wait == 0 then break end
        wait(1)
    end

    if t.wait == 1 then return end

    if t.sn >= 10000 then
        t.wait = 1
        local idx = getAutoInc(what)
        t.at=idx
        t.sn = 0
        t.wait = 0
    end

    local id = t.at * 10000 + t.sn
    t.sn = t.sn + 1

    --addPendSave("uniq", what, "sn", t.sn)
    --addPendSave("uniq", what, "at", t.at)
    --addPendSave("uniq", what, "state", t.state)

    local n = gPendingSave.uniq[ what ]
    n.sn = t.sn
    n.at = t.at
    n.state = t.state

    return id
end

function getAutoInc(what)
    --local db = dbmng:getOne(0)
    local db = dbmng:getByTips("Global")
    LOG("getAutoInc, getdb after")
    local r = db:runCommand("findAndModify", "uniq", "query", {_id=what}, "update", {["$inc"]={sn=1}}, "new", true, "upsert", true)
    LOG("getAutoInc, runCommand after")
    dumpTab(r, "getAutoInc")
    return r.value.sn
end

