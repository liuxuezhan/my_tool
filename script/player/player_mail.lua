module("player_t")

function mail_lock_by_sn(self,sns)
    local ms = self:get_mail()
    if ms then
        local db = self:getDb(self.pid)
        for _, sn in pairs(sns) do
            local m = ms[ sn ]
            if m and m.tm_lock == 0 then
                m.tm_lock = gTime
                gPendingSave.mail[ m._id ].tm_lock = gTime
                self:reply_ok("mail_lock_by_sn", m.idx)
            end
        end
    end
end

function mail_unlock_by_sn(self,sns)
    local ms = self:get_mail()
    if ms then
        local db = self:getDb(self.pid)
        for _, sn in pairs(sns) do
            local m = ms[ sn ]
            if m and m.tm_lock > 0 then
                m.tm_lock = 0
                gPendingSave.mail[ m._id ].tm_lock = 0
                self:reply_ok("mail_unlock_by_sn", m.idx)
            end
        end
    end
end

function mail_drop_by_sn(self,sns)
    local ms = self:get_mail()
    if ms then
        local db = self:getDb(self.pid)
        for _, sn in pairs(sns) do
            local m = ms[ sn ]
            if m.tm_lock == 0 and (m.tm_fetch > 0 or m.its == 0) then
                m.tm_drop = gTime
                gPendingSave.mail[ m._id ].tm_drop = gTime
                self:reply_ok("mail_drop_by_sn", m.idx)
                INFO("[mail], drop, pid=%d, id=%s", self.pid, m._id)
            end
        end
    end
end

function mail_read_by_sn(self, sns)
    local ms = self:get_mail()
    if ms then
        local db = self:getDb(self.pid)
        for _, sn in pairs(sns) do
            local m = ms[ sn ]
            if m then
                if m.tm_read == 0 then
                    m.tm_read = gTime
                    gPendingSave.mail[ m._id ].tm_read = gTime
                    self:reply_ok("mail_read_by_sn", m.idx)
                end
            end
        end
    end
end

function mail_fetch_by_sn(self, sns)
    local ms = self:get_mail()
    if ms then
        local db = self:getDb(self.pid)
        for _, sn in pairs(sns) do
            local m = ms[ sn ]
            if m and m.its ~= 0 and m.fetch == 0 then
                m.fetch = gTime
                for k, v in pairs(m.its) do
                    self:inc_item(v[1], v[2], VALUE_CHANGE_REASON.FETCH_MAIL)
                end
                gPendingSave.mail[ m._id ].tm_fetch = gTime
                self:reply_ok("mail_fetch_by_sn", m.idx)
                INFO("[mail], fetch, pid=%d, id=%s", self.pid, m._id)
            end
        end
    end
end

function get_mail(self)
    if not self._mail then
        INFO("load mail from db, pid=%d", self.pid)
        local ms = {}
        local db = self:getDb()
        local info = db.mail:find({to=self.pid})
        if info then
            while info:hasNext() do
                local m = info:next()
                if m.tm_drop and m.tm_drop == 0 then ms[ m.idx ] = m end
            end
        end
        self._mail = ms
    end
    return self._mail
end


function mail_load(self, sn)
    local ms = self:get_mail()

    local mail_sys = self.mail_sys or 0
    if mail_sys < gSysMailSn then
        local count = #gSysMail -- the bigger sn, be post at tail
        local news = {}
        for idx = count, 1, -1 do
            local v = gSysMail[ idx ]
            if mail_sys < v.idx then table.insert(news, 1, v)
            else break end
        end

        for _, v in pairs(news) do
            local m = copyTab(v)
            m.copy = v._id
            self:mail_new(m, true)
        end
        self.mail_sys = gSysMailSn
    end

    local msn = {}
    for k, v in pairs(ms) do 
        if v.idx > sn then table.insert(msn, v.idx) end
    end
    local funSort = function(A,B) return A < B end
    table.sort(msn, funSort)

    local res = {}
    for k, v in ipairs(msn) do
        if ms[v].tm_drop == 0 then table.insert(res, ms[v]) end
        if #res >= 20 then break end
    end
    dumpTab(res, "mail_load")
    Rpc:mail_load(self, res)
end


-- p:mail_new({from=from, name=name, class=class, title="hello", content="world", its={{1001,100}}})
function mail_new(self, v, isload)
    v.its = v.its or 0
    if v.its == 0 then

    elseif type(v.its) == "table" then
        if #v.its == 0 then v.its = 0 end
    else
        return
    end

    v.idx = self.mail_max + 1
    v.to = self.pid
    v._id = string.format("%d_%d", v.idx, v.to)
    v.tm_read = 0
    v.tm_fetch = 0
    v.tm_drop = 0
    v.tm_lock = 0
    v.tm = gTime
    v.class = v.class or 1

    self.mail_max = v.idx
    
    local db = self:getDb()
    db.mail:insert(v)
    if self._mail then 
        self._mail[ v.idx ] = v 
    end
end

-- player.mail_all({ class=class, title="hello", content="world", its={{1001,100}}})
function mail_all(v)
    v._id = gSysMailSn + 1
    v.idx = v._id
    v.to = 0
    v.from = 0
    v.name = "system"
    gSysMailSn = v._id
    table.insert(gSysMail, v)

    local db = dbmng:getOne()
    db.mail:insert(v)

    Rpc:mail_sys_new({pid=-1,gid=_G.GateSid}, gSysMailSn)
end

function test_mail_all(self, class, title, content, its)
    mail_all({class=class, title=title, content=content, its=its})
end

--RPC
function mail_send_player(self, to, title, content)
    local p = getPlayer(to)
    if p then
        local m = {class=MAIL_CLASS.PLAYER, from=self.pid, name=self.name, title=title, content=content, its=0}
        p:mail_new(m)
        self:reply_ok("mail_send_player")
    end
end

