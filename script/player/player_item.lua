module("player_t")
_cache_items = _cache_items or {}

function get_item(self, idx)
    if not self._item then
        local ms = {}
        local db = self:getDb()
        local info = db.item:findOne({_id=self.pid})
        if info then
            for k, v in pairs(info) do
                if k ~= "_id" then
                    ms[ tonumber(k) ] = v
                end
            end
        else
            db.item:insert({_id=self.pid})
        end
        --self._item = ms
        rawset(self, "_item", ms)
    end
    if not idx then return self._item
    else return self._item[ idx ] end
end

-- one item = {idx, id, num, extra ...}
function inc_item(self, id, num, reason)
    local its = self:get_item()
    local hit = false
    local idx = 0
    for k, v in pairs(its) do
        if v[2] == id and not v[4] then
            v[3] = v[3] + num
            hit = true
            idx = k
            break
        end
    end

    if not hit then
        for i = 1, 500, 1 do
            if not its[ i ] then
                its[ i ] = {i, id, num}
                idx = i
                break
            end
        end
    end

    self:add_item_pend(idx)

    reason = reason or VALUE_CHANGE_REASON.DEFAULT
    if reason == VALUE_CHANGE_REASON.DEFAULT then
        ERROR("inc_item: pid = %d, don't use the default reason.", self.pid)
    end
    LOG("inc_item: pid = %d, item_id = %d, num = %d, reason = %d.", self.pid, id, num, reason)
end

function add_item_pend(self, idx)
    local pid = self.pid
    local node = _cache_items[ pid ]
    if not node then
        node = {}
        _cache_items[ pid ] = node
    end
    local k = tostring(idx)
    node[ k ] = self._item[ idx ]
    node[ k ]._n_ = nil
end


--------------------------------------------------------------------------------
-- Function : 根据格子索引 idx 从 self 的背包中扣除 num 个物品
-- Argument : self, idx, num, reason
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function dec_item(self, idx, num, reason)
    if not self or not idx or not num or num <= 0 then
        ERROR("dec_item: pid = %d, idx = %d, num = %d", self and self.pid or -1, idx or -1, num or -1)
        return false
    end


    local item = self:get_item(idx)
    if item and item[3] >= num then
        item[3] = item[3] - num
        self:add_item_pend(idx)

        reason = reason or VALUE_CHANGE_REASON.DEFAULT
        if reason == VALUE_CHANGE_REASON.DEFAULT then
            ERROR("dec_item: pid = %d, don't use the default reason.", self.pid)
        end
        LOG("dec_item: pid = %d, idx = %d, item_id = %d, num = %d, reason = %d.", self.pid, idx, item[2], num, reason)
        return true
    else
        LOG("dec_item: pid = %d, idx = %d, item_id = %d, num = %d > have = %d", self.pid, idx, item[2], num, item and item[3] or -1)
        return false
    end
end


--------------------------------------------------------------------------------
-- Function : 根据 item_id 从 self 的背包中扣除 num 个物品
-- Argument : self, item_id, num, reason
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function dec_item_by_item_id(self, item_id, num, reason)
    if not self or not item_id or not num or num <= 0 then
        ERROR("dec_item_by_item_id: pid = %d, item_id = %d, num = %d", self and self.pid or -1, item_id or -1, num or -1)
        return false
    end

    local item_have = self:get_item_num(item_id)
    if num > item_have then
        LOG("dec_item_by_item_id: pid = %d, item_id = %d, num = %d > have = %d", self.pid, item_id, num, item_have)
        return false
    end

    -- TODO: 之后估计会添加物品有效期，到时这里的代码需要修改，优先删除快过期的
    local item_list = self:get_item()
    local item_need_del = num
    for idx, item in pairs(item_list) do
        if item[2] == item_id then
            if item[3] >= item_need_del then
                item[3] = item[3] - item_need_del
                item_need_del = 0
            else
                item[3] = 0
                item_need_del = item_need_del - item[3]
            end
            self:add_item_pend(idx)
        end

        if item_need_del == 0 then
            break
        end
    end

    reason = reason or VALUE_CHANGE_REASON.DEFAULT
    if reason == VALUE_CHANGE_REASON.DEFAULT then
        ERROR("dec_item_by_item_id: pid = %d, don't use the default reason.", self.pid)
    end
    INFO("dec_item_by_item_id: pid = %d, item_id = %d, num = %d, reason = %d.", self.pid, item_id, num, reason)
    return true
end


function addItem(self, id, num)
    self:inc_item(id, num, VALUE_CHANGE_REASON.DEBUG)
end


function get_item_num(self, id)
    local its = self:get_item()
    local total = 0
    for k, v in pairs(its) do
        if v[2] == id then
            total = total + v[3]
        end
    end
    return total
end


function use_item(self, idx, num)
    local item = self:get_item(idx)
    if self:dec_item(idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
        local conf = resmng.get_conf("prop_item", item[2])
        if conf then
            -- 此接口屏蔽英雄技能物品的使用，被扣除了道具活该 ^_^
            if conf.Class ~= ITEM_CLASS.SKILL then
                item_func[conf.Action](self, num, unpack(conf.Param or {}))
            else
                ERROR("use_item: conf.Class = %d", conf.Class)
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 清空背包
-- Argument : NULL
-- Return   : NULL
-- Others   : debug func.
--------------------------------------------------------------------------------
function clear_item(self)
    local item_list = self:get_item()
    for idx, item in pairs(item_list) do
        self:dec_item(idx, item[3], VALUE_CHANGE_REASON.DEBUG)
    end
end


--------------------------------------------------------------------------------
-- Function : 使用英雄技能物品(特定技能书、通用技能书、技能重置书)
-- Argument : self, hero_idx, item_idx, num
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function use_hero_skill_item(self, hero_idx, skill_idx, item_idx, num)
    -- 参数校验
    if not hero_idx or not skill_idx or not item_idx or not num or num <= 0 then
        ERROR("use_hero_skill_item: pid = %d, hero_idx = %d, skill_idx = %d, item_idx = %d, num = %d",
               self.pid or -1, hero_idx or -1, skill_idx or -1, item_idx or -1, num or -1)
        return
    end

    -- 物品类型校验
    local item = self:get_item(item_idx)
    if not item then
        ERROR("use_hero_skill_item: get_item() failed. pid = %d, item_idx = %d", self.pid or -1, item_idx)
        return
    end

    local conf = resmng.get_conf("prop_item" ,item[2])
    if not conf or conf.Class ~= ITEM_CLASS.SKILL then
        ERROR("use_hero_skill_item: not skill item. pid = %d, item_idx = %d, item_id = %d, item_class = %d",
               self.pid or -1, item_idx, item[2], conf and conf.Class or -1)
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero or not hero:is_valid() then
        ERROR("use_hero_skill_item: hero isn't valid. pid = %d, hero_idx = %d", self.pid, hero_idx)
        return
    end

    if is_in_table(ITEM_SKILL_MODE, conf.Mode) then
        item_func[conf.Action](self, hero_idx, skill_idx, item_idx, num, unpack(conf.Param or {}))
    else
        ERROR("use_hero_skill_item: unknown item mode. item_idx = %d, item_mode = %d", item_idx, conf.Mode or -1)
    end
end

--------------------------------------------------------------------------------
item_func = {}

item_func.addItem = function(A, num, ...)
    for k, v in pairs({...}) do
        A:inc_item(v[1], v[2]*num, VALUE_CHANGE_REASON.USE_ITEM)
    end
end

item_func.addRes = function(A, num, ...)
    for k, v in pairs({...}) do
        A:doUpdateRes(v[1], v[2]*num, VALUE_CHANGE_REASON.USE_ITEM)
    end
end

--------------------------------------------------------------------------------
-- Hero begin

-- 使用英雄卡
item_func.useHeroCard = function(self, num, hero_propid)
    if not self or not num or not hero_propid then
        ERROR("item_func.useHeroCard: pid = %d, num = %d, hero_propid = %d",
               self and self.pid or -1, num or -1, hero_propid or -1)
        return
    end

    if num > 1 then
        WARN("item_func.useHeroCard: pid = %d, hero_propid = %d, num = %d > 1 !!!", self.pid, hero_propid, num)
    end

    if self:get_hero_by_propid(hero_propid) then
        -- 已有：换成碎片
        self:convert_hero_card_2_piece(hero_propid, num)
    else
        -- 没有：一张用于召唤，其余转换成碎片
        self:make_hero(hero_propid)
        if num > 1 then
            self:convert_hero_card_2_piece(hero_propid, num - 1)
        end
    end
end

-- 使用英雄特定技能书
item_func.useHeroSkillSpecialBook = function(self, hero_idx, skill_idx, item_idx, num, skill_id, exp)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("item_func.useHeroSkillSpecialBook: get_hero() failed. pid = %d, hero_idx = %d", self.pid or -1, hero_idx)
        return
    else
        local skill = hero.basic_skill[skill_idx]
        if not skill then
            ERROR("item_func.useHeroSkillSpecialBook: hero._id = %s, basic_skill[%d] is still locked.", hero._id or "nil", skill_idx)
            return
        else
            local conf = resmng.get_conf("prop_skill", skill_id)
            if not conf then
                return
            end

            -- TODO: 校验 num 是否过大，超过升到顶级所需的经验值

            if conf.Class == skill_idx then
                if skill[1] == 0 then
                    -- 尚无: 首张用于获得该技能，其余用于升级
                    if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
                        hero:change_basic_skill(skill_idx, skill_id, 0)
                        if num > 1 then
                            hero:gain_skill_exp(skill_idx, (num - 1) * exp)
                        else
                            hero:basic_skill_changed(skill_idx)
                        end
                        LOG("item_func.useHeroSkillSpecialBook: hero._id = %s, skill_idx = %d", hero._id, skill_idx)
                    else
                        return
                    end
                elseif heromng.is_same_skill(skill[1], skill_id) then
                    -- 校验能否升级
                    if not heromng.get_next_skill(skill[1]) then
                        LOG("item_func.useHeroSkillSpecialBook: get_next_skill() failed. hero._id = %s, skill_idx = %d, skill_id = %d",
                             hero._id or "nil", skill_idx, skill[1])
                        return
                    end

                    -- 增加技能经验
                    if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
                        hero:gain_skill_exp(skill_idx, num * exp)
                    else
                        return
                    end
                else
                    -- 被其它技能占据，不能使用
                    ERROR("item_func.useHeroSkillSpecialBook: hero._id = %s, basic_skill[%d][1] = %d ~= skill_id = %d",
                           hero._id or "nil", skill_idx, skill[1] or -1, skill_id)
                    return
                end
            else
                -- skill_idx 与 skill_id 不匹配
                ERROR("item_func.useHeroSkillSpecialBook: pid = %d, hero_idx = %s, skill_id = %d, conf.Class(%d) ~= skill_idx(%d)",
                      self and self.pid or -1, hero_idx, skill_id, conf.Class or -1, skill_idx)
                return
            end
        end
    end
end

-- 使用英雄通用技能书
item_func.useHeroSkillCommonBook = function(self, hero_idx, skill_idx, item_idx, num, skill_id, exp)
    -- skill_id === 0
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("item_func.useHeroSkillCommonBook: get_hero() failed. pid = %d, hero_idx = %d", self.pid or -1, hero_idx)
        return
    else
        local skill = hero.basic_skill[skill_idx]
        if not skill then
            ERROR("item_func.useHeroSkillCommonBook: hero._id = %s, basic_skill = %d is still locked.", hero._id or "nil", skill_idx)
            return
        else
            if not heromng.get_next_skill(skill[1]) then
                LOG("item_func.useHeroSkillCommonBook: get_next_skill() failed. hero._id = %s, skill_idx = %d, skill_id = %d",
                     hero._id or "nil", skill_idx, skill[1])
                return
            end

            -- 增加经验
            if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
                hero:gain_skill_exp(skill_idx, num * exp)
            end
        end
    end
end

-- 使用英雄技能重置书
item_func.useHeroSkillResetBook = function(self, hero_idx, skill_idx, item_idx, num)
    if num ~= 1 then
        ERROR("item_func.useHeroSkillResetBook: pid = %d, num = %d ~= 1", self.pid or -1, num)
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("item_func.useHeroSkillResetBook: get_hero() failed. pid = %d, hero_idx = %d", self.pid or -1, hero_idx)
        return
    else
        local skill = hero.basic_skill[skill_idx]
        if not skill then
            ERROR("item_func.useHeroSkillResetBook: hero._id = %s, basic_skill[%d] is still locked.", hero._id or "nil", skill_idx)
            return
        else
            if skill[1] == 0 then
                -- 尚无: 不能使用
                ERROR("item_func.useHeroSkillResetBook: hero._id = %s, basic_skill[%d] is empty.", hero._id or "nil", skill_idx)
                return
            else
                -- 已有: 重置技能
                if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
                    hero:reset_skill(skill_idx)
                    return
                end
            end
        end
    end
end

--使用英雄个性重置卡
item_func.use_hero_reset_personality_card = function(self, hero_idx, item_idx, num)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("use_hero_reset_personality_card: get_hero failed, pid = %d, hero_idx = %d", self.pid or -1, hero_idx)
        return
    else
        if hero:is_valid() == false then
            return
        end
        if self:dec_item(item_idx, 1, VALUE_CHANGE_REASON.USE_ITEM) then
            hero:change_personality()
        end
    end
end

--使用英雄改名卡
item_func.use_hero_reset_name_card = function(self, hero_idx, item_idx, num)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("use_hero_reset_name_card: get_hero failed, pid = %d, hero_idx = %d", self.pid or -1, hero_idx)
        return
    else
        if hero:is_valid() == false then
            return
        end
        if self:dec_item(item_idx, 1, VALUE_CHANGE_REASON.USE_ITEM) then
            hero:rename_hero()
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 将英雄卡转换成碎片发放
-- Argument : self, hero_propid, num
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function convert_hero_card_2_piece(self, hero_propid, num)
    if not self or not hero_propid or not num or num <=0 then
        ERROR("convert_hero_card_2_piece: pid = %d, hero_propid = %d, num = %d", self and self.pid or -1, hero_propid or -1, num or -1)
        return
    end

    local conf = resmng.prop_hero_basic[ hero_propid ]
    if not conf then
        ERROR("convert_hero_card_2_piece: get prop_hero_basic failed, propid = %d", hero_propid)
        return
    else
        local piece_total = math.floor(conf.CallPrice * num * HERO_CARD_2_PIECE_RATIO)
        self:inc_item(conf.PieceID, piece_total, VALUE_CHANGE_REASON.CONVERT_HERO_CARD)
        LOG("convert_hero_card_2_piece: pid = %d, hero_propid = %d, num = %d", self.pid, hero_propid, num)
    end
end

-- Hero end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Function : 将 cons 按照已有和需要购买进行拆分
-- Argument : self; cons = {{resmng.CLASS_ITEM, item_id, item_num}, {resmng.CLASS_RES, res_id, res_num}, ...}
-- Return   : succ - cons_have, cons_need_buy; fail - nil, nil
-- Others   : cons 中只能是道具或者资源
--------------------------------------------------------------------------------
function split_cons(self, cons)
    if not cons then
        ERROR("split_cons: no cons.")
        return
    end

    local cons_have = {}
    local cons_need_buy = {}
    for _, con in pairs(cons) do
        if con[3] > 0 then
            if con[1] == resmng.CLASS_RES then
                local res_have = self:get_res_num(con[2])
                if not res_have then
                    ERROR("split_cons: wrong resource type, con[2] = %d", con[2] or -1)
                    return
                end

                if res_have > con[3] then
                    table.insert(cons_have, con)
                else
                    table.insert(cons_need_buy, {con[1], con[2], con[3] - res_have})
                    if res_have > 0 then
                        table.insert(cons_have, {con[1], con[2], res_have})
                    end
                end
            elseif con[1] == resmng.CLASS_ITEM then
                local have = self:get_item_num(con[2])
                if have >= con[3] then
                    table.insert(cons_have, con)
                else
                    table.insert(cons_need_buy, {con[1], con[2], con[3] - have})
                    if have > 0 then
                        table.insert(cons_have, {con[1], con[2], have})
                    end
                end
            else
                ERROR("split_cons: wrong con, neither resmng.CLASS_ITEM nor resmng.CLASS_RES, but %d", con[1] or -1)
                return
            end
        end
    end

    return cons_have, cons_need_buy
end


--------------------------------------------------------------------------------
-- Function : 统计 cons_list 总共值多少金币
-- Argument : cons = {{resmng.CLASS_ITEM, item_id, item_num}, {resmng.CLASS_RES, res_id, res_num}, ...}
-- Return   : succ - gold_num; fail - math.huge
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_cons_value(cons_list)
    if not cons_list then
        ERROR("calc_cons_value: no cons_list.")
        return math.huge
    end

    local gold_num = 0
    for _, v in pairs(cons_list) do
        gold_num = gold_num + get_con_price(v[1], v[2]) * v[3]
    end

    return gold_num
end


--------------------------------------------------------------------------------
-- Function : 查询 con 价值
-- Argument :  _class, id
-- Return   : gold_num
-- Others   : NULL
--------------------------------------------------------------------------------
function get_con_price(_class, id)
    -- TODO: 数值未定，这里返回1作测试用
    do return 1 end

    if _class == resmng.CLASS_RES then
    elseif _class == resmng.CLASS_ITEM then
    end
end


--------------------------------------------------------------------------------
-- Function : 扣除 cons_list 中的资源和道具
-- Argument : self, cons_list, reason, not_check_num(跳过数量校验)
-- Return   : succ - true; fail - false
-- Others   : not_check_num = true 时，调用者需要自己保证数量足够扣除!!!
--            cons_list = {{resmng.CLASS_ITEM, item_id, item_num}, {resmng.CLASS_RES, res_id, res_num}, ...}
--------------------------------------------------------------------------------
function dec_cons(self, cons_list, reason, not_check_num)
    if not cons_list then
        ERROR("dec_cons: no cons_list. pid = %d.", self.pid)
        return false
    end

    if not not_check_num then
        for _, con in pairs(cons_list) do
            if con[1] == resmng.CLASS_RES then
                local res_have = self:get_res_num(con[2])
                if not res_have then
                    ERROR("dec_cons: wrong resource type, con[2] = %d", con[2] or -1)
                    return false
                end

                if res_have < con[3] then
                    LOG("dec_cons: resouce(%d) not enough. need = %d, have = %d", con[2], con[3], res_have)
                    return false
                end
            elseif con[1] == resmng.CLASS_ITEM then
                local item_have = self:get_item_num(con[2])
                if item_have < con[3] then
                    LOG("dec_cons: item(%d) not enough. need = %d, have = %d.", con[2], con[3], item_have)
                    return false
                end
            end
        end
    end

    for _, con in pairs(cons_list) do
        if con[1] == resmng.CLASS_RES then
            self:doUpdateRes(con[2], -con[3], reason)
        elseif con[1] == resmng.CLASS_ITEM then
            self:dec_item_by_item_id(con[2], con[3], reason)
        end
    end

    return true
end


--------------------------------------------------------------------------------
-- Function : 发放 cons_list 中的资源和道具，与 dec_cons 对应
-- Argument : self, cons_list, reason
-- Return   : NULL
-- Others   : cons_list = {{resmng.CLASS_ITEM, item_id, item_num}, {resmng.CLASS_RES, res_id, res_num}, ...}
--------------------------------------------------------------------------------
function inc_cons(self, cons_list, reason)
    if not cons_list then
        ERROR("inc_cons: no cons_list. pid = %d.", self.pid)
        return false
    end

    for _, con in pairs(cons_list) do
        if con[1] == resmng.CLASS_RES then
            self:doUpdateRes(con[2], con[3], reason)
        elseif con[1] == resmng.CLASS_ITEM then
            self:inc_item(con[2], con[3], reason)
        end
    end
end

function material_compose(self, id)
    local node = resmng.get_conf("prop_item", id)
    if not node then return ack(self, "material_compose", resmng.E_FAIL) end
    if node.Class ~= ITEM_CLASS.MATERIAL then return ack(self, "material_compose", resmng.E_FAIL) end
    local prenode = resmng.get_conf("prop_item", id-1)
    if not prenode then return ack(self, "material_compose", resmng.E_FAIL) end
    if not self:dec_item_by_item_id(prenode.ID, resmng.MATERIAL_COMPOSE_COUNT, VALUE_CHANGE_REASON.COMPOSE) then return ack(self, "material_compose", resmng.E_FAIL) end
    self:inc_item(id, 1, VALUE_CHANGE_REASON.COMPOSE)
    self:reply_ok("material_compose", id)
end


function material_decompose(self, id)
    local node = resmng.get_conf("prop_item", id)
    if not node then return ack(self, "material_decompose", resmng.E_FAIL) end
    if node.Class ~= ITEM_CLASS.MATERIAL then return ack(self, "material_decompose", resmng.E_FAIL) end
    local prenode = resmng.get_conf("prop_item", id-1)
    if not prenode then return ack(self, "material_decompose", resmng.E_FAIL) end
    if not self:dec_item_by_item_id(node.ID, 1, VALUE_CHANGE_REASON.DECOMPOSE) then return ack(self, "material_decompose", resmng.E_FAIL) end
    self:inc_item(prenode.ID, resmng.MATERIAL_COMPOSE_COUNT, VALUE_CHANGE_REASON.DECOMPOSE)
    self:reply_ok("material_decompose", id)
end


