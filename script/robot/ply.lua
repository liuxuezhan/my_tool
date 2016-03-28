module("Ply", package.seeall)
dofile("robot/preload.lua")

local _mt = {__index = Ply}

function new(acc)
    local t = {acc=acc, action={{"login"}}}
    return setmetatable(t, _mt)
end

function handle_network(self, sid, pktype)
    if pktype == 10 then -- connect complete
        self.gid = sid
        Rpc:firstPacket(self, 6, self.acc, "1")
    elseif pktype == 11 then -- connect fail
        
    elseif pktype == 6 then -- close

    end
end

function onLogin(self, pid, name )
    self.pid = pid
    self.name = name
    self.tmLogin = gTime
end

function loadData(self, data)
    if data.key == "pro" then
        for k, v in pairs(data.val) do self[k] = v end
    else
        self[ "_" .. data.key ] = data.val
    end
end

function stateTroop(self,data)
    if data.state == resmng.TroopState.Back then
        self._troop[data.idx] = nil 
        self.troop_num =  self.troop_num - 1 
    else
        self._troop[data.idx] = data 
    end
end

local _union_list_all = 0
local _cur_union_num = 0

function union_list(self, pack)

    _union_list_all = {}
    for k, v in pairs(pack) do
        _union_list_all[#_union_list_all+1] = v.uid
    end
    _cur_union_num = #_union_list_all
end

function union_on_create(self, pack)
    self.union.id = pack.uid
    _union_list_all[#_union_list_all+1]  = pack.uid
end

function union_reply(self, id,stat)
end

function union_add_member(self, pack)
    Rpc:union_add_member(self,pack.pid)
end

function union_load(self, pack)

    if pack.key == "info" then--军团基本信息
       if not self.union then self.union = {} end
       self.union.id = pack.val.uid or 0
       self.union.leader = pack.val.leader or 0
    elseif pack.key =="apply" then--军团成员加入同意
        self._union_apply = pack.val
        for k, v in pairs(pack.val) do
            Rpc:union_add_member(self,v.pid)
        end
    elseif pack.key =="build" then--军团建筑
        if not self.union.build then self.union.build = {} end
        for k, v in pairs(pack.val) do
            self.union.build[v.idx]=v
        end
    elseif pack.key =="buildlv" then--军团建筑捐献
        if not self.union.buildlv then self.union.buildlv = {} end
        for k, v in pairs(pack.val) do
            self.union.buildlv[v.class]=v
        end
    elseif pack.key =="fight" then--军队集结
    lxz(pack)
        if not self.union.mass then self.union.mass = {} end
        for k, v in pairs(pack.val) do
            self.union.mass[v.class]=v
        end
    end
end

function union_build_donate(self,info) 
    if not self.union.buildlv then self.union.buildlv = {} end
    self.union.buildlv[info.class]=info
end

function union_broadcast(self,what,mode,info) 
    if what == "build" then
        if mode == 2 and info.state == resmng.DEF_STATE_IDLE then
            self.union.build[info.idx]= info
        end
    elseif what =="fight" then--军队集结
        if not self.union.mass then self.union.mass = {} end
        if mode == 1 then
            self.union.mass[info.id]= info
        elseif mode == 3 then
            self.union.mass[info.id]= nil
        end
    end
end

function addEtys(self, info)
    if not self._eye then
        self._eye = {}
    end

    for _, v in pairs(info) do 
        local pack = etypipe.parse(v)
        if math.floor(pack.eid/65536)== 2 then
            return 
        end

        if not self._eye[pack.y] then
            self._eye[pack.y] = {}
        end

        self._eye[pack.y][pack.x] = pack 
    end
end


function stateBuild(self, vs)
    local idx = vs.idx
    local b = self:get_build(idx)
    if b then
        for k, v in pairs(vs) do b[k] = v end
    else
        self._build[ idx ] = vs
    end
end

function statePro(self, vs)
    dumpTab(vs, "statePro")
    for k, v in pairs(vs) do self[k] = v end
end

function get_build(self, idx)
    if not idx then return self._build end
    if not self._build[idx] then 
        return nil
    end
    return self._build[ idx ]
end

function get_build_x(self, x)
    for _, v in pairs(self._build) do 
        if v.x == x then
            return v
        end
    end
end


function checkBuild(self)

end

function getRes(self, mode)
    if mode == resmng.DEF_RES_FOOD then
        return self.food - (gTime-self.foodTm) * self.foodUse/3600
    elseif mode == resmng.DEF_RES_WOOD then
        return self.wood
    end
end

function doCondCheck(self, class, mode, lv, ...)
    if class == "or" then
        local f,c,m,l 
        for _, v in pairs({mode, lv, ...}) do
            if self:doCondCheck(unpack(v)) then return true end
        end
        return false

    elseif class == "and" then 
        for _, v in pairs({mode, lv, ...}) do
            if not self:doCondCheck(unpack(v)) then return false, class, mode, lv end
        end
        return true

    elseif class == resmng.CLASS_RES then
        if mode == resmng.DEF_RES_FOOD then
            if self.food - (gTime-self.foodTm)*self.foodUse / 3600 >= lv then return true end
        elseif mode == resmng.DEF_RES_WOOD then
            if self.wood >= lv then return true end
        end
    elseif class == resmng.CLASS_BUILD then
        local t = resmng.prop_build[ mode ]
        if t then
            local c = t.class
            local m = t.mode
            local l = t.lv
            for _, v in pairs(self:get_build()) do
                local n = resmng.prop_build[ v.propid ]
                if n and n.class == c and n.mode == m and n.lv >= l then return true end
            end
        end
    elseif class == resmng.CLASS_GENIUS then
        local t = Data.propGenius[ mode ]
        if t then
            local c = t.class
            local m = t.mode
            local l = t.lv
            for _, v in pairs(self.genius) do
                local n = Data.propGenius[ v ]
                if n and n.class == c and n.mode == m and n.lv >= l then return true end
            end
        end
    elseif class == remsng.CLASS_TECH then
        local t = Data.propTech[ mode ]
        if t then
            local c = t.class
            local m = t.mode
            local l = t.lv
            for _, v in pairs(self.tech) do
                local n = Data.propTech[ v ]
                if n and n.class == c and n.mode == m and n.lv >= l then return true end
            end
        end
    end
    -- default return false
    return false, class, mode, lv
end

function condCheck(self, tab)
    if tab then
        for _, v in pairs(tab) do
            local flag, class, mode, lv = self:doCondCheck(unpack(v))
            if not flag then 
                return flag, class, mode, lv 
            end
        end
    end
    return true
end


function doAction(self)
    local as = self.action
    if #as > 0 then
        while #as > 0 do
            local a = as[1]
            if funcAction[ a[1] ] then
                local rt = funcAction[a[1]](self, unpack(a[2] or {}))
                if rt then
                    table.remove(as, 1)
                else
                    return
                end
            else
                print("not found action", a[1])
               -- return
            end
        end
        --return
    end
    makePlan(self)
end

function addAction(self, act, ...)
    for k, v in pairs(self.action) do
        if v[1] == act then
            WARN("recursion !!!! add act, %s", act)
            return
        end
    end

    table.insert(self.action, 1, {act, {...}})
    gActive[ self.gid ] = self
    --self:doAction()
end

function makePlan(self)
    math.randomseed(os.clock()*123456789)
    local r = math.random(9,10) 
    if r == 1 then
    elseif r == 2 then
        self:addAction("construct", 1, 1, self:getBuildNum(1, 1) + 1)
    elseif r == 3 then
        self:addAction("construct", 1, 2, self:getBuildNum(1, 2)+1)
    elseif r == 4 then
        self:addAction("construct", 0, 18, self:getBuildNum(0, 18)+1)
    elseif r == 5 then
        self:build_up(1, 1)
    elseif r == 6 then
        self:build_up(1, 2)
    elseif r == 7 then
        self:build_up(0, 18)
    elseif r == 8 then
        for _, yv in pairs(self._eye) do
            for k, v in pairs(yv) do
                local type = math.floor(v.eid/65536) 
                if type == 3 and not v.on then
                    self:fight("union_mass_create",v.eid,{{1001,1},} )
                    return
                end
            end
        end
    elseif r == 9 then
        self:union_build_up_pre(1,1)
    elseif r == 10 then
        self:union_build_up_pre(3,4)
    end

  --  lxz(self.pid,self.action)
end

function union_build_up_pre(self,class,mode)

    if self.union.id == 0 then
        self:addAction("union_add")
        return 
    end

    if class == resmng.CLASS_UNION_BUILD_CASTLE then
        if self.name ~=  self.union.leader then
            return
        end
    elseif class == resmng.CLASS_UNION_BUILD_MINE_CASTLE then
    elseif class == resmng.CLASS_UNION_BUILD_TUTTER then
    elseif class == resmng.resmng.CLASS_UNION_BUILD_MINE then
    end

    --查询玩家建筑
    local cc = nil 
    local idx = 0 
    for _, v in pairs(self.union.build) do
        cc = resmng.prop_union_build[v.id]
        if cc.Class == class and cc.Mode==mode then
            idx = v.idx 
            break
        end
    end
    

--没有建筑
    if idx == 0 then
        self:union_build_setup_pre(class,mode)
        return
    end

    if cc.Lv == 3 then
       return true
    end
--查询玩家建筑捐献等级
    local lv = nil
    if self.union.buildlv[class] and self.union.buildlv[class].id then 
        lv = self.union.buildlv[class].id 
    else
        Rpc:union_build_donate(self,class)
        return 
    end

    local lvcc = resmng.prop_union_buildlv[lv] 
    if cc.Lv >= lvcc.Lv then
        Rpc:union_build_donate(self,class)
        return 
    end

    Rpc:union_build_upgrade(self,idx)
end

function union_build_setup_pre(self,class,mode)
    local num = 0

    if self.union.id == 0 then
        self:addAction("union_add")
        return 
    end

    if class == resmng.CLASS_UNION_BUILD_CASTLE then
        if self.name ~=  self.union.leader then
            return
        end
    elseif class == resmng.CLASS_UNION_BUILD_MINE_CASTLE then
    elseif class == resmng.CLASS_UNION_BUILD_TUTTER then
    elseif class == resmng.resmng.CLASS_UNION_BUILD_MINE then
    end


    for _, v in pairs(self.union.build) do
        local cc = resmng.prop_union_build[v.id]
        if cc.Class == class and cc.Mode==mode then
            num = num +1
        end
    end

    local lv = nil
    if self.union.buildlv[class] and self.union.buildlv[class].id then 
        lv = self.union.buildlv[class].id 
    else
        Rpc:union_build_donate(self,class)
        return 
    end

    local lvcc = resmng.prop_union_buildlv[lv] 
    if num >= lvcc.Num then
        Rpc:union_build_donate(self,class)
        return 
    end

    local id = class*1000*1000+mode*1000+1
    self:addAction("union_build_setup",id,self.x+5*(class+1),self.y+5*(mode+1))
end

function getBuildNum(self, class, mode)
    local num = 0
    local new = 0
    for k, v in pairs(self:get_build()) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
            if p.class == class and p.mode == mode then
                num = num + 1
                if v.state and v.state > 0 then
                    new = new + 1
                end
            end
        end
    end
    return num, new
end

funcAction = {}
funcAction.login = function(self)
    if not self.lv then return Rpc:loadData(self, "pro") end
    if not self._build then return Rpc:loadData(self, "build") end
    if not self._item then return Rpc:loadData(self, "item") end
    if not self._eye then return Rpc:addEye(self ) end
    if not self._ef then return Rpc:loadData(self, "ef") end
    if not self.union then return Rpc:union_load(self,"info") end
    if not self._union_apply then return Rpc:union_load(self,"apply") end
    if not self.union.build then return Rpc:union_load(self,"build") end
    if not self.union.buildlv then return Rpc:union_load(self,"buildlv") end
    if not self.union.mass then return Rpc:union_load(self,"fight") end
    self.union.mass_num = 0 
    if _union_list_all  == 0 then 
        return Rpc:union_list(self) 
    end
    if not self._troop then return Rpc:loadData(self, "troop") end

    if self._troop then 
        self.troop_num = #self._troop 
        return true 
    end
end

local _UNION_NUM=200
funcAction.union_add = function(self)
    if self.union.id == 0 then
        if _cur_union_num < _UNION_NUM then 
            Rpc:union_create(self,self.name,self.name,10,1)
            self.union.id = 1 
            _cur_union_num = 1 + _cur_union_num 
        else 
            local id = _union_list_all[self.pid%_UNION_NUM+1]  
            if  id  then 
                Rpc:union_apply(self,id)
                self.union.id = id  
            end
        end
    end

    return true
end

funcAction.union_build_setup = function(self,id,x,y)
    Rpc:union_build_setup(self,id,x,y)
    return true
end

function build_up(self, class, mode,lv)
    for k, v in pairs(self:get_build()) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
            local l = lv or p.lv+1
            if l < 31 then
                if p.class == class and p.mode == mode then
                    self:upgrade( v, l)
                    return 
                end
            end
        end
    end
    self:addAction("construct", class, mode,  1)
end

function upgrade (self, b, tolv)
    if b.state ~= resmng.DEF_STATE_IDLE then return end
    local prop = resmng.prop_build[ b.propid ]
    if prop.lv >= tolv then return true end
    local nprop = resmng.prop_build[ math.floor(prop.class * 1000000 + prop.mode * 1000 + prop.lv + 1) ]
    if nprop then
        if nprop.cond then
            local flag, class, mode, lv = self:condCheck(nprop.cond)
            if not flag then
                if class == resmng.CLASS_RES then
                    self:addAction("get", class, mode, lv)
                    return
                elseif class == resmng.CLASS_BUILD then
                    local t = resmng.prop_build[ mode ]
                    self:build_up( t.class,t.mode,t.lv)
                    return
                end
            end
        end

        if nprop.cons then
            local flag, class, mode, lv = self:condCheck(nprop.cons)
            if not flag then
                self:addAction("get", class, mode, lv)
                return
            end
        end
        self:addAction("upgrade", b.idx) 
    end
end

funcAction.upgrade = function(self, idx)
    Rpc:upgrade(self, idx)
    return true
end

function build_train(self, class, mode,a_lv)

    local f = 0 

    for k, v in pairs(self:get_build()) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
           if p.class == class and p.mode == mode and p.trainLv >= a_lv then
                return 1
           end

        end
    end

    self:build_up(class,mode)
    return 0
end

function fight(self, cmd, eid,arms)
--收兵
    for k, v in pairs(self:get_build()) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
            if p.class == 0 and p.mode == 18 then
                Rpc:draft( self,v.idx)
            end
        end
    end
    --造兵
    for _, v in pairs(arms) do
        for sk, sv in pairs(self.arms) do
            if v[1]==sv[1] and sv[2] < v[2] then
               self:train(math.floor(v[1]/1000),math.floor(v[1]%1000),v[2]-sv[2] )--造兵 
               return true
            end
        end
    end

    if self.union.id ~= 0 then
        local mid = 0
        for k, v in pairs(self.union.mass) do 
            mid = k
            for _, v2 in pairs(v.A) do 
                if v2.pid == self.pid  then
                    mid = -1
                    break
                end
            end
        end

        if mid == 0 then
            self:addAction("fight","union_mass_create",eid,30,arms ) 
        elseif mid == -1 then
        else
            self:addAction("fight","union_mass_join",mid,arms ) 
        end
    else
        self:addAction("fight","seige",eid,arms ) 
    end
    return true
end

funcAction.fight = function(self,cmd,...)
    if self.troop_num > 3 then
        return true
    end

    lxz(self.pid,self.troop_num)
    self.troop_num = self.troop_num + 1 
    Rpc[cmd](Rpc,self,...)
end

function train(self,a_mode,a_lv,num )
    local id = math.floor(a_mode * 1000 + a_lv)

    local prop = resmng.prop_arm[ id ]
    if prop.cons then
        local flag, class, mode, lv = self:condCheck(prop.cons)
        if not flag then
            if class == resmng.CLASS_RES then
                self:addAction("get", class, mode, lv)
                return
            end
        end
    end

    if self:build_train( 2,a_mode,a_lv) == 1 then --前提建筑
        local n = self:getBuildNum(0, 18)
        if n==0 then
            self:addAction("construct", 0, 18,  1)
            return 
        end

        self:addAction("train",id,num )--造兵 
        return
    end
end


funcAction.train = function(self, id,num)
    local cur_num = num
    for k, v in pairs(self:get_build()) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
            if p.class == 0 and p.mode == 18  and cur_num > 0 then
                    if cur_num < p.effect.TrainCount then
                        Rpc:train(self,v.idx,id, cur_num) 
                        cur_num = 0
                        break
                    else
                        Rpc:train(self,v.idx,id, p.effect.TrainCount)
                        cur_num = cur_num - p.effect.TrainCount
                    end
            end
        end
    end

    return  true 
end

funcAction.construct = function(self, class, mode, num)
    num = num or 1

    local cur = self:getBuildNum(class, mode)
    print(string.format("pid=%d, class=%d, mode=%d, cur=%d", self.pid, class, mode, cur))
    if cur >= num then return true end

    for k, v in pairs(self:get_build()) do
        if v.state == 0 or v.state == 3 then return end
    end

    local propid = math.floor(class * 1000000 + mode * 1000 + 1)
    local prop = resmng.prop_build[ propid ]
    if prop.cond then
        local flag, class, mode, lv = self:condCheck(prop.cond)
        if not flag then
            self:addAction("get", class, mode, lv)
            return
        end
    end

    if prop.cons then
        local flag, class, mode, lv = self:condCheck(prop.cons)
        if not flag then
            self:addAction("get", class, mode, lv)
            return
        end
    end

    for x = 100, 150, 1 do
        if not self:get_build_x( x ) then
            Rpc:construct(self, x, 0, propid)
            return 
        end
    end
    return true
end


funcAction.get = function(self, class, mode, lv)
    if class == resmng.CLASS_RES then
        if self:getRes(mode) >= lv then return true end
        for k, v in pairs(self:get_build()) do
            local p = resmng.prop_build[ v.propid ]
            if p then 
                if p.class == 1 and p.mode == mode then
                    if v.state == resmng.DEF_STATE_IDLE then
                        if gTime - v.tmStart > 10 then
                            Rpc:reap(self, v.idx)
                            v.tmStart = gTime
                        end
                    end
                end
            end
        end

--收城外田
        for _, yv in pairs(self._eye) do
            for k, v in pairs(yv) do
                local type = math.floor(v.eid/65536) 
                if type == 1 and v.val ~= 0 and not v.on then
                    self:addAction("gather", v.eid,{{1001,1},} )
                return
            end
        end
    end


    elseif class == resmng.CLASS_BUILD then

    end
end

funcAction.gather = function(self, eid,arms)
--收兵
    for k, v in pairs(self:get_build()) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
            if p.class == 0 and p.mode == 18 then
                Rpc:draft( self,v.idx)
            end
        end
    end
    --造兵
    for _, v in pairs(arms) do
        for sk, sv in pairs(self.arms) do
            if v[1]==sv[1] and sv[2] < v[2] then
                self:addAction("train",1,1,v[2]-sv[2] )--造兵 
                return true
            end
        end
    end

   cur_num = Rpc:gather( self,eid,arms)
   return true
end



