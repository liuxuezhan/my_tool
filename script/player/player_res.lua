module("player_t")
function check_resm_conf(p)
    local lv = 0
    local conf={}
    local num
    for _, v in pairs(p:get_build()) do
        local base = resmng.prop_build[ v.propid ]
        if base then
            if base.Class == 0 and base.Mode == 7 and resmng.prop_resm[v.propid] then
                local t = resmng.prop_resm[v.propid].Conf
                for k2, _ in pairs(t) do
                    conf[k2]=t[k2]+p.buy_num
                end
                num = resmng.prop_resm[v.propid].Num
            elseif base.Class == 0 and base.Mode == 0 then
                lv = base.Lv
            end
        end
    end

    if lv < 15 then
        conf[5]=nil
    end

    if lv < 10 then
        conf[4]=nil
    end

    local rmb = resmng.prop_resm_num[p.buy_num+1].RMB
    return conf,rmb,num
end

function get_resm_conf(self)

    local conf,rmb,num = check_resm_conf(self)
    local time = os.date("*t",gTime)
    if time.yday ~=self.buy_time then
        self.res_num =  num
        self.buy_time = time.yday
    end

    local t = {}
    for k, v in pairs(conf) do
       local n=#t+1
       t[n]={k,v}
    end

    Rpc:get_resm_conf(self,rmb,t)
end

function buy_res(self, id)
    local conf,num

    if id ~= resmng.DEF_RES_FOOD
        and id ~= resmng.DEF_RES_WOOD
        and id ~= resmng.DEF_RES_IRON
        and id ~= resmng.DEF_RES_STEEL
        and id ~= resmng.DEF_RES_ENERGY then

            WARN(id)
            return
    end


    local conf,rmb=check_resm_conf(self)

    if (conf[id] or 0 )then
        if self.res_num > 0 then
            self.res_num = self.res_num - 1
        else
            if self.rmb >= rmb then
                self.rmb = self.rmb - rmb
                self.buy_num = self.buy_num + 1
            else
                WARN("buy_res %s : %s < %s ",self.pid,self.rmb,rmb)
                return
            end
        end

        local mu = 1
        if id == self.resm_type1 then
            mu = self.resm_type1_mu
        elseif id == self.resm_type2 then
            mu = self.resm_type2_mu
        end

        if id == resmng.DEF_RES_FOOD then
            self.food = self.food + conf[id]*mu
        elseif id == resmng.DEF_RES_WOOD then
            self.wood = self.wood + conf[id]*mu
        elseif id == resmng.DEF_RES_IRON then
            self.iron = self.iron + conf[id]*mu
        elseif id == resmng.DEF_RES_STEEL then
            self.steel = self.steel + conf[id]*mu
        elseif id == resmng.DEF_RES_ENERGY then
            self.energy = self.energy + conf[id]*mu
        end

--暴击处理
        self.resm_type1     = 0
        self.resm_type1_mu  = 0
        self.resm_type2     = 0
        self.resm_type2_mu  = 0
        math.randomseed(os.clock()*123456789)

        --随机命中暴击第一件资源
        local r = math.random(10)
        r=1
        if r == 1 then
            r = math.random(5)
            if r ==1 then
                self.resm_type1  = resmng.DEF_RES_FOOD
            elseif r==2 then
                self.resm_type1  = resmng.DEF_RES_WOOD
            elseif r==3 then
                self.resm_type1  = resmng.DEF_RES_IRON
            elseif r==4 then
                self.resm_type1  = resmng.DEF_RES_STEEL
            elseif r==5 then
                self.resm_type1  = resmng.DEF_RES_ENERGY
            end
            self.resm_type1_mu  = math.random(2,10)
        end

        --随机命中暴击第二件资源
        local r = math.random(20)
        if r == 1 then
            r = math.random(5)
            if r ==1 then
                self.resm_type2  = resmng.DEF_RES_FOOD
            elseif r==2 then
                self.resm_type2  = resmng.DEF_RES_WOOD
            elseif r==3 then
                self.resm_type2  = resmng.DEF_RES_IRON
            elseif r==4 then
                self.resm_type2  = resmng.DEF_RES_STEEL
            elseif r==5 then
                self.resm_type2  = resmng.DEF_RES_ENERGY
            end

            if  self.resm_type2  == self.resm_type1 then
              self.resm_type2_mu  = math.random(2,10)
            else
              self.resm_type2  = 0
            end
        end

        if self.resm_type1_mu ==10 or self.resm_type2_mu ==10 then
            self:chat( resmng.ChatChanelEnum.Union,string.format("%s在市场狂扫物资，获得十倍暴击！",self.account))
        end
    else
        WARN("buy_res:conf err ")
    end

end
