module_class("union_member_t", {
    _id = 0,
    pid = 0,            
    --uid = 0,                    --联盟id
    mark = "",                   --联盟标记
    rank = 0,                   --联盟阶级
    history = {},               --历史加入的联盟
    donate = 0,                 --可用捐献
    donate_data = {0,0,0,0},    --捐献记录
    techexp_data = {0,0,0,0},   --捐献获得的科技经验记录
    tmJoin = 0,                 --加入联盟的时间
    tmLeave = 0,                --离开联盟的时间
    donate_flag = 0,            --可否捐献
    tmDonate = 0,               --捐献cd
})

function init(self)
    self.donate_cache = self.donate_cache or {}
end

function create(pid, uid, rank)
    local data = {
        _id = pid,
        pid = pid,
        --uid = uid,
        appointment = "",
        rank = 0,
        credit = 0,
        history = {},
        donate = 0,
    }
    local db = dbmng:getOne()
    db.union_member:insert(data)
    return new(data)
end

function on_check_pending(db, _id, chgs)
    db.union_member:update({_id=_id}, {["$set"] = chgs})

end

-- Hx@2015-12-23 : 
-- 1.only primary at first time
-- 2.changed only when donated or rand out a new one
function fresh_donate_cache(self, idx, dt)
    local conf = resmng.prop_union_donate[union_tech_t.get_class(idx)]
    assert(conf, "no conf found")
    
    local cache = self.donate_cache[idx]
    if not cache then
        cache = {}
        cache[resmng.TECH_DONATE_TYPE.MEDIUM] = 0
        cache[resmng.TECH_DONATE_TYPE.SENIOR] = 0
    else
        if dt then
            cache[dt] = 0
        end
        if math.random(10000) < 2500 then
            cache[resmng.TECH_DONATE_TYPE.MEDIUM] = math.random(2, #conf.Medium)
        end
        if math.random(10000) < 1000 then
            cache[resmng.TECH_DONATE_TYPE.SENIOR] = math.random(2, #conf.Senior)
        end
    end
    cache[resmng.TECH_DONATE_TYPE.PRIMARY] = math.random(2, #conf.Primary)
    
    self.donate_cache[idx] = cache
end

function get_donate_cache(self, idx)
    if not self.donate_cache[idx] then
        self:fresh_donate_cache(idx)
    end
    return self.donate_cache[idx]
end

function get_donate_flag(self)
    if self.tmDonate <= gTime and self.donate_flag ~= 0 then
        self.donate_flag = 0
    end
    return self.donate_flag
end

function add_donate(self, num)
    assert(num > 0)
    self.donate = self.donate + num

    for i = 1, #self.donate_data do
        self.donate_data[i] = self.donate_data[i] + num
    end
    self.donate_data = self.donate_data
end

function add_techexp(self, num)
    assert(num > 0)
    for i = 1, #self.techexp_data do
        self.techexp_data[i] = self.techexp_data[i] + num
    end
    self.techexp_data = self.techexp_data
end

function clear_donate_data(self, what)
    self.donate_data[what] = 0
    self.techexp_data[what] = 0

    self.donate_data = self.donate_data
    self.techexp_data = self.techexp_data
end

function add_donate_cooldown(self, tm)
    if self.tmDonate < gTime then
        self.tmDonate = gTime
    end

    self.tmDonate = self.tmDonate + tm
    if self.tmDonate - gTime >  14400 then
        self.donate_flag = 1
    end
end

function add_history(self, data)
    table.insert(self.history, 1, data)
    local out = #self.history - 20
    for i = 1, out, 1 do
        table.remove(self.history)
    end
    self.history = self.history
end

function clear(self)
    --self.uid = 0
    self.mark = ""
    self.rank = 0
    self.tmJoin = 0
    self.donate_flag = 0
    self.tmDonate = 0
    self:clear_donate_data(resmng.DONATE_RANKING_TYPE.DAY)
    self:clear_donate_data(resmng.DONATE_RANKING_TYPE.WEEK)
    self:clear_donate_data(resmng.DONATE_RANKING_TYPE.UNION)
end
