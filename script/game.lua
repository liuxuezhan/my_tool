
function load_game_module()
    gMapID = getMap()
    gMapNew = 1
    c_map_init()
    c_roi_init()
    c_roi_set_block("common/map_block.bytes")
    gSysMailSn = 0
    gSysMail = {}
    gSysStatus = {}
    do_reload()
end


function do_reload()
    do_load("game")

    do_load("resmng")
    do_load("common/define")
    do_load("common/tools")
    do_load("common/protocol")

    do_load("timerfunc")

    do_load("public_t")

    do_load("player_t")
    do_load("player/player_item")
    do_load("player/player_mail")
    do_load("player/player_union")
    do_load("player/player_res")
    do_load("player/player_hero")
    do_load("player/player_build")
    do_load("player/player_troop")
    do_load("player/player_task")

    do_load("build_t")
    do_load("troop_t")

    do_load("heromng")
    do_load("hero/hero_t")

    do_load("fight")
    do_load("farm")
    do_load("restore_handler")

    do_load("unionmng")
    do_load("union_t")
    do_load("union_member_t")
    do_load("union_tech_t")
    do_load("union_build_t")

    do_load("monster")
    do_load("crontab")
    do_load("room")
    do_load("triggers")

    --do_load("frame/zset")
    --require("test")


    --c_start_debug(10023)
    
    do_load("gmmng")
end

function reload()
    action(do_reload)
end

function restore_game_data()
    restore_handler.action()
    gInit = "InitGameDone"
    begJob()

end


function do_roi_msg(msg, d0, d1, d2, d3, d4, d5, d6, d7)
    if msg == ROI_MSG.NTY_NO_RES then
        farm.do_check(d0, d1)
        monster.do_check(d0, d1)
    else
        print("roi_msg", msg, d0, d1, d2, d3, d4, d5, d6, d7)
    end
end

-------------------------------------------
--the above should be here
--
--

g_eid_idx = {}
function get_eid(mode)
    local base = mode * 0x010000
    local idx = g_eid_idx[ mode ] or 0
    for i = 1, 65530, 1 do
        idx = idx + 1
        if idx >= 0x010000 then idx = 0 end
        local id = base + idx
        if not gEtys[ id ] then 
            g_eid_idx[ mode ] = idx
            return id 
        end
    end
end

function mark_eid(eid)
    local mode = math.floor(eid / 65536)
    local idx = math.floor(eid % 65536)
    local cur = g_eid_idx[ mode ]

    if not cur then
        g_eid_idx[ mode ] = idx
    else
        if idx > cur then g_eid_idx[ mode ] = idx end
    end
end

function add_ety(ety)
    gEtys[ ety.eid ] = ety
end

function get_ply(eid)
    local e = get_ety(eid)
    if is_ply(e) then return e end
end

function get_mon(eid)
    local e = get_ety(eid)
    if is_monster(e) then return e end
end

function get_eid_ply()
    return get_eid(EidType.Player)
end

function get_eid_res()
    return get_eid(EidType.Res)
end

function get_eid_troop()
    return get_eid(EidType.Troop)
end

function get_eid_monster()
    return get_eid(EidType.Monster)
end

function get_eid_uion_building()
    return get_eid(EidType.UnionBuild)
end

function get_eid_npc_city()
    return get_eid(EidType.NpcCity)
end

function get_mode_by_eid(eid)
    return math.floor(eid / 65536)
end

function get_ety(eid)
    return gEtys[ eid ]
end

function rem_ety(eid)
    local e = gEtys[ eid ]
    if e then
        if is_res(e) then
            gEtys[ eid ] = nil
            c_rem_ety(eid)
            local db = dbmng:getOne()
            db.farm:delete({_id=e.eid})
        elseif is_monster(e) then
            gEtys[ eid ] = nil
            c_rem_ety(eid)
            e:checkout()
        elseif is_union_building(e) then
            local u = unionmng.get_union(e.uid)
            u:remove_build(e.idx)
        else
            gEtys[ eid ] = nil
            c_rem_ety(eid)
        end
    end
end

function is_focus(ety)
    --todo
end


function test()
    --196649,1250,304
    c_add_scan(196649,1)
    c_add_actor(1, 1240, 304, 1260, 304, 0.4)

    local e = gEtys[ 196649 ]
    monster.mark(e)


    --local ply = getPlayer(270130)
    --ply:mail_unlock_by_sn({1})
    --ply:mail_unlock_by_sn({2})
    --ply:mail_unlock_by_sn({300})
    --ply:mail_unlock_by_sn({4})
    --ply:mail_unlock_by_sn({5})
    --ply:mail_unlock_by_sn({6})
    --ply:mail_unlock_by_sn({1})

    --gPendingSave.mail[ "6_270130" ]._id = "4_270130"
    --gPendingSave.mail[ "1_270130" ].tm_lock = gTime
    --gPendingSave.mail[ "2_270130" ].tm_lock = gTime
    --gPendingSave.mail[ "3_270130" ].tm_lock = gTime
    --gPendingSave.mail[ "4_270130" ].tm_lock = gTime
    --gPendingSave.mail[ "5_270130" ].tm_lock = gTime
    --gPendingSave.mail[ "7_270130" ].tm_lock = gTime
end

function check_pending()
    player_t.check_pending()
    build_t.check_pending()
    troop_t.check_pending()
    hero_t.check_pending()
    union_member_t.check_pending()
    union_t.check_pending()
    union_tech_t.check_pending()
    union_build_t.check_pending()
    room.check_pending()
    --dirty_sync()
end

function mem_info()
    local heap, mem, mlua, mbuf, mobj, nbuf, nply, nres, ntroop, nmonster, nothers, neye = c_get_engine_mem()
    INFO("[MEM_INFO], heap=%d, mem=%d, lua=%d, mbuf=%d, mobj=%d", heap, mem, mlua, mbuf, mobj)
    INFO("[MEM_DETAIL], mem=%d, lua=%d, mbuf=%d, mobj=%d, nbuf=%d, nply=%d, nres=%d, ntroop=%d, nmonster=%d, neye=%d", mem, mlua, mbuf, mobj ,nbuf, nply, nres, ntroop, nmonster, neye)
end


-- Hx@2015-12-03 :
function ack(self, funcname, code, reason)
    assert(self)
    assert(funcname)
    assert(code)
    code = code or resmng.E_OK
    reason = reason or resmng.E_OK
    if not Rpc.localF[funcname] then
        ERROR("[Rpc]: onError, not found, func:%s, code:%s, reason:%s", funcname, code, reason)
        return
    end
    local hash = Rpc.localF[funcname].id
    Rpc:onError(self, hash, code, reason)
    INFO("[Rpc]:onError, %s, %s, %s, %s", funcname, code, reason, debug.stack(1))
end

-- -----------------------------------------------------------------------------
-- Hx@2016-01-25 : 模块类
-- 因为module 中找不到时会去全局找，所以对象局部变量找不到时很可能在全局找
-- 如：
-- local data = {module_class=nil}
-- local obj = name_t.new(data)
-- local k = obj.module_class
-- 如果obj中不存在class则会去全局找module_class，因此找到本全局函数，造成错误
-- 所以一定类成员不要和全局函数同名!!!!
-- -----------------------------------------------------------------------------
function module_class(name, example)
    assert(example._id, "must have _id as pk")
    module(name, package.seeall)
    setfenv(2, getfenv(1))
    _cache = _cache or {}
    _example = example
    local mt = {
        __index = function(t, k)
            if t._pro[k] ~= nil then return t._pro[k] end
            if _example[k] ~= nil then
                if type(_example[k]) == "table" then
                    t._pro[k] = copyTab(_example[k])
                    return t._pro[k]
                else
                    return _example[k]
                end
            end
            if _G[name][k] ~= nil then return _G[name][k] end
        end,
        __newindex = function(t, k, v)
            if _example[k] then
                t._pro[k] = v
                if not _cache[t._id] then _cache[t._id] = {} end
                _cache[t._id][k] = v
                _cache[t._id]._n_ = nil
            else
                rawset(t, k, v)
            end
        end
    }

    function new(t)
        local self = {_pro=t}
        setmetatable(self, mt)
        self:init()

        --in order to detect add event when check_pending()
        -- Hx@2016-01-07 : do it in init() by your self. some module did not want that
        --_cache[self._id] = self._pro

        return self
    end

    function init(self)
        --override
    end

    function check_pending()
        local db = dbmng:tryOne(1)
        if not db then return end
        local hit = false
        local cur = gFrame
        for _id, chgs in pairs(_cache) do
            if not chgs._n_ then
                on_check_pending(db, _id, chgs)
                chgs._n_ = cur
                hit = true
            end
        end
        if hit then get_db_checker(db, cur)() end
    end

    function on_check_pending(db, _id, chgs)
        WARN("override this!!!")
        --override
    end

    function get_db_checker(db, frame)
        local f = function()
            local info = db:runCommand("getPrevError")
            if info.ok then
                local dels = {}
                for k, v in pairs(_cache) do
                    local n = v._n_
                    if n then
                        if n == frame then
                            table.insert(dels, k)
                        elseif n < frame - 100 then
                            v._n_ = nil
                        end
                    end
                end
                if #dels > 0 then
                    for _, v in pairs(dels) do
                        _cache[v] = nil
                    end
                end
            end
        end
        return coroutine.wrap(f)
    end
end


function get_material_group_by_rare(rare)
    if gItemGroupRare and gItemGroupRare[ rare] then return gItemGroupRare[ rare ] end

    local its = {}
    local class = ITEM_CLASS.MATERIAL
    for k, v in pairs(resmng.prop_item) do
        if v.Class == class and v.Rare == rare then
            table.insert(its, k)
        end
    end

    if not gItemGroupRare then gItemGroupRare = {} end
    gItemGroupRare[ rare ] = its
    return its
end



