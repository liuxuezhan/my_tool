module_class("union_tech_t", {
    _id = 0,
    uid = 0,
    id = 0,
    exp = 0,
    tmStart = 0,
    tmOver = 0,
    tmSn = 0,
})
--module("union_tech_t", package.seeall)
--
--_cache = _cache or {}
--
--_example = {
--    _id = 0,
--    uid = 0,
--    id = 0,
--    exp = 0,
--    tmStart = 0,
--    tmOver = 0,
--    tmSn = 0,
--}
--
--local mt = {
--    __index = function(t, k)
--        return t._pro[k] or _example[k] or union_tech_t[k] or rawget(t, k)
--    end,
--    __newindex = function(t, k, v)
--        if _example[k] then
--            t._pro[k] = v
--            if not _cache[t._id] then
--                _cache[t._id] = {}
--            end
--            _cache[t._id][k] = v
--        else
--            rawset(t, k, v)
--        end
--    end
--}
--
--function new(t)
--    local self = {_pro = t}
--    setmetatable(self, mt)
--
--    return self
--end

function init(self)
end

function get_conf(class, mode, lv)
    for _, v in pairs(resmng.prop_union_tech) do
        if v.Class == class and v.Mode == mode and v.Lv == lv then
            return v
        end
    end
    return nil
end

function create(idx, uid)
    local conf = get_conf(get_class(idx), get_mode(idx), 0)
    assert(conf, "conf not found")
    --local idx = conf.class * 1000 + conf.mode
    local idx = conf.Idx
    local data = {
        _id = string.format("%s_%s", uid, idx),
        idx = idx,
        uid = uid,
        id = conf.ID,
        exp = 0,
        tmOver = 0,
        tmSn = 0,
    }
    local db = dbmng:getOne()
    db.union_tech:insert(data)
    return new(data)
end

--function check_pending()
--    for id, chgs in pairs(_cache) do
--        local db = dbmng:getOne()
--        db.union_tech:update({_id=id}, {["$set"] = chgs})
--    end
--    _cache = {}
--end

function on_check_pending(db, _id, chgs)
    db.union_tech:update({_id=id}, {["$set"] = chgs})
end

function get_class(idx)
    assert(idx, debug.stack())
    return math.floor(idx / 1000)
end

function get_mode(idx)
    return idx % 1000
end

function get_pro(self)
    return self._pro
end

function add_exp(self, num)
    self.exp = self.exp + num
end

function is_exp_full(self)
    local conf = resmng.prop_union_tech[self.id]
    if self.exp >= conf.Exp * conf.Star then
        return true
    else
        return false
    end
end

function get_lv(self)
    local conf = resmng.prop_union_tech[self.id]
    assert(conf, "conf not found")
    return conf.Lv
end
