-- Hx@2015-11-25 : common functions

function string.split(str, delimiter)
    if str == nil or str == "" or delimiter == nil then
        return nil
    end

    local results = {}
    for match in (str ..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(results, match)
    end
    return results
end

-- Zhao@2016年1月28日:字符串扩展
function string.starts_with(str,start_str)
    if str == start_str then return true end
    if not str or not start_str then return false end
    return start_str == string.sub(str,1,string.len(start_str))
end

function string.ends_with(str,end_str)
    if str == end_str then return true end
    if not str or not end_str then return false end
    return end_str == string.sub(str,-string.len(end_str))
end

-- Zhao@2016年2月16日：数学库扩展
function math.clamp(max,min,value)
    if min > max then max,min = min,max end
    if value > max then value = max end
    if value < min then value = min end
    return value
end

function basename(path)
    if type(path) ~= "string" then
        INFO("basename: %s not a string")
        return nil
    end

    return ((path):gsub(".*[\\/]", ""))
end

--清理table数据
function table.clear(tb)
    for k,v in pairs(tb) do
        tb[k] = nil
    end
end

function table.index_of(tb,o)
    for k,v in ipairs(tb) do
        if v == o then
            return k
        end
    end

    return -1
end
--[[
-- >stack>stack>[file:line]
function debug.stack(level)
    level = level or 0
    level = level + 2
    local info = debug.getinfo(level)

    local result = ""

    local dep = 3
    repeat
        result = result.. string.format("@%s:%s:%s",
            basename(info.short_src or ""), info.name or "", info.currentline or ""
        )

        level = level + 1
        info = debug.getinfo(level)
        dep = dep - 1
    until not info or dep < 0

    return result
end
--]]

-- Hx@2015-11-30 :
function handler(obj, method)
    assert(obj)
    assert(method)
    return function(...)
        method(obj, ...)
    end
end

function class(base, _ctor)
    local c = {}    -- a new class instance
    if not _ctor and type(base) == 'function' then
        _ctor = base
        base = nil
    elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
        for i,v in pairs(base) do
            c[i] = v
        end
        c._base = base
    end

    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c

    -- expose a constructor which can be called by <classname>(<args>)
    local mt = {}

    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj,c)

        if _ctor then
            _ctor(obj,...)
        end
        return obj
    end

    c._ctor = _ctor
    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    setmetatable(c, mt)
    return c
end

function tojson(tbl,indent)
    assert(tal==nil)
    if not indent then indent = 0 end

    local tab=string.rep("  ",indent)
    local havetable=false
    local str="{"
    local sp=""
    if tbl then
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                havetable=true
                if(indenct==0) then
                    str=str..sp.."\r\n  "..tostring(k)..":"..tojson(v,indent+1)
                else
                    str=str..sp.."\r\n"..tab..tostring(k)..":"..tojson(v,indent+1)
                end
            else
                str=str..sp..tostring(k)..":"..tostring(v)
            end
            sp=";"
        end
    end

    if(havetable) then      str=str.."\r\n"..tab.."}"   else        str=str.."}"    end

    return str
end


--------------------------------------------------------------------------------
-- Function : 检查元素是否在 table 中
-- Argument : tab value
-- Return   : succ - k / fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function is_in_table(tab, value)
    if type(tab) ~= "table" then
        ERROR("Argument error: tab isn't a table, type(tab) = %s", type(tab))
        return false
    end

    for k, v in pairs (tab) do
        if v == value then
            return k
        end
    end

    return false
end


--------------------------------------------------------------------------------
-- Function : 获取 table 元素个数
-- Argument : table
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function get_table_valid_count(tab)
    if not tab then
        return 0
    end

    local count = 0
    for k, v in pairs(tab) do
        if v then count = count + 1 end
    end

    return count
end


--------------------------------------------------------------------------------
-- Function : 时间戳转字符串
-- Argument : timestamp
-- Return   : NULL
-- Others   : timestamp 为空则取当前时间
--------------------------------------------------------------------------------
function timestamp_to_str(timestamp)
    return os.date("%Y-%m-%d %X", timestamp or 0)
end


-- Hx@2016-01-15 : ety format
etypipe = {}
etypipe._monster =      {"eid", "x", "y", "propid"}
etypipe._npccity =      {"eid", "x", "y", "propid", "uid"}
etypipe._res =          {"eid", "x", "y", "propid", "uid", "pid", "val"}
etypipe._player =       {"eid", "x", "y", "propid", "uid", "pid", "photo", "name"}
etypipe._unionbuild =   {"eid", "x", "y", "propid", "uid", "sn","idx","val"}
etypipe._troop =        {"eid","aid","uid","sx","sy","dx","dy","tmStart", "tmOver", "action", "state", "count", "events"}

etypipe[EidType.Player] =   {"eid", "x", "y", "propid", "uid", "pid", "photo", "name"}
etypipe[EidType.Res]    =   {"eid", "x", "y", "propid", "uid", "pid", "val"}
etypipe[EidType.Troop]  =   {"eid","aid","uid","sx","sy","dx","dy","tmStart", "tmOver", "action", "state", "count", "events"}
etypipe[EidType.Monster]=   {"eid", "x", "y", "propid"}
etypipe[EidType.UnionBuild] =   {"eid", "x", "y", "propid", "uid", "sn","idx","hp","state","val"}
etypipe[EidType.NpcCity]=   {"eid", "x", "y", "propid", "uid"}


function etypipe.pack(filter, xs)
    local val = {}
    for k, v in pairs(filter) do
        assert(xs[v], "ety add lack key: ".. v)
        val[k] = xs[v]
    end
    return cmsgpack.pack(val)
end

function etypipe.unpack(filter, data)
    local val = {}
    for k, v in pairs(filter) do
        val[v] = data[k]
    end
    return val
end
-- api
function etypipe.parse(data)
    local eid = data[1]
    local mode = math.floor(eid / 0x010000)
    local node = etypipe[ mode ]
    if node then
        return etypipe.unpack(node, data)
    else
        WARN("no etypipid, eid=0x%08x", eid)
        return data
    end
end

function etypipe.add(data)
    assert(data.eid, data.x, data.y)

    local mode = math.floor(data.eid / 0x010000)
    local node = etypipe[ mode ]
    if not node then
        WARN("what type, etypipe.add??")
        dumpTab(data, "etypipe.add error")
    end

    if is_monster(data.eid) then c_add_ety(data.eid, data.x, data.y, 1, 0, etypipe.pack(node, data))
    elseif is_ply(data.eid) then c_add_ety(data.eid, data.x, data.y, 4, 1, etypipe.pack(node, data))
    elseif is_res(data.eid) then c_add_ety(data.eid, data.x, data.y, data.size, 0, etypipe.pack(node, data))
    elseif is_troop(data.eid) then c_add_troop(data.eid, data.sx, data.sy, data.dx, data.dy, etypipe.pack(node, data))
    elseif is_union_building(data.eid) then c_add_ety(data.eid, data.x, data.y, data.size, 0, etypipe.pack(node, data))
    elseif is_npc_city(data.eid) then c_add_ety(data.eid, data.x, data.y, data.size, 1, etypipe.pack(node, data))
    else
        WARN("what type, etypipe.add??")
    end
end

function get_val_by(what, ...)
    local node = resmng.get_conf("prop_effect_type", what)
    if not node then WARN("effect %s not found in prop_effect_type", what) end

    local bidx = what
    local ridx = string.format("%s_R", what)
    local eidx = string.format("%s_A", what)
    local b, r, e = 0, 0, 0 -- base, multiple, add
    for _, v in pairs({...}) do
        b = b + (v[ bidx ] or 0)
        r = r + (v[ ridx ] or 0)
        e = e + (v[ eidx ] or 0)
    end
    return b * (1 + r * 0.0001) + e
end


--------------------------------------------------------------------------------
-- 常用调试函数，简写函数名
p = dumpTab

