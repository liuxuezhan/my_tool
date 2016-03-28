module("player_t")

--load db
function do_load_task(self)
    local db = self:getDb()
    local db_info = db.task:findOne({_id=self.pid})
    local task_list = {}
    for k,v in pairs(db_info) do
        if k ~= "_id" then
            if v.task_type == TASK_TYPE.TASK_TYPE_DAILY then
                self._daily_task_list[tonumber(k)] = v
            elseif v.task_type == TASK_TYPE.TASK_TYPE_TRUNK or v.task_type == TASK_TYPE.TASK_TYPE_BRANCH then
                self._life_task_list[tonumber(k)] = v
            elseif v.task_type == TASK_TYPE.TASK_TYPE_UNION then
                self._union_task_info[tonumber(k)] = v
            end
        end
    end

    return task_list
end

function init_from_db(self, data)
    for k,v in pairs(data) do
        if k ~= "_id" then
            if v.task_type == TASK_TYPE.TASK_TYPE_DAILY then
                self._daily_task_list[tonumber(k)] = v
            elseif v.task_type == TASK_TYPE.TASK_TYPE_TRUNK or v.task_type == TASK_TYPE.TASK_TYPE_BRANCH then
                self._life_task_list[tonumber(k)] = v
            elseif v.task_type == TASK_TYPE.TASK_TYPE_UNION then
                self._union_task_info[tonumber(k)] = v
            end
        end
    end
end
--save db
function do_save_task(self)
    if #self._need_save_id == 0 then
        return
    end
    local save_list = {}
    for k, v in ipairs(self._need_save_id) do
        local data = self:get_task_by_id(v)
        save_list[tostring(v)] = data
    end
    local db = self:getDb()
    db.task:update({_id=self.pid}, {["$set"]=save_list}, true)

    self._need_save_id = {}
end

function add_save_task_id(self, task_id)
    table.insert(self._need_save_id, task_id)
end

function init_task(self)
    --每日任务列表
    self._daily_task_list = {}

    --主线支线任务列表
    self._life_task_list = {}

    --军团列表
    self._union_task_info = {}

    --需要保存的任务ID数组
    self._need_save_id = {}

    --[[
    local task_info = {}
    task_info.task_id = 0
    task_info.task_status = TASK_STATUS.TASK_STATUS_INVALID
    task_info.task_type = TASK_TYPE.TASK_TYPE_INVALID
    task_info.task_current = 0
    task_info.task_manager_type = 0
    task_info.task_parm1 = 0
    task_info.task_parm2 = 0
    task_info.task_parm3 = 0
    task_info.task_parm4 = 0
    task_info.task_parm5 = 0
    --]]
end

function clear_task()
    self._daily_task_list = {}
    self._life_task_list = {}
    self._need_save_id = {}
end

function add_task_data(self, task_info)
    local has_unit = self:get_task_by_id(task_info.task_id)
    if has_unit ~= nil then
        return false
    end

    local unit = {}
    unit.task_id = task_info.ID
    unit.task_status = TASK_STATUS.TASK_STATUS_ACCEPTED
    unit.task_type = task_info.TaskType
    unit.task_manager_type = 0 --todo具体的任务功能ID
    unit.task_current_num = 0
    unit.task_parm1 = 0
    unit.task_parm2 = 0
    unit.task_parm3 = 0
    unit.task_parm4 = 0
    unit.task_parm5 = 0

    if unit.task_type == TASK_TYPE.TASK_TYPE_DAILY then
        self._daily_task_list[unit.task_id] = unit
    elseif unit.task_type == TASK_TYPE.TASK_TYPE_TRUNK or unit.task_type == TASK_TYPE.TASK_TYPE_BRANCH then
        self._life_task_list[unit.task_id] = unit
    elseif unit.task_type == TASK_TYPE.TASK_TYPE_UNION then
        self._union_task_info = {}
        self._union_task_info[unit.task_id] = unit
    end

    self:add_save_task_id(unit.task_id)
    self:do_save_task()

    return true
end

function get_task_by_id(self, task_id)
    local key = task_id
    if self._union_task_info[key] ~= nil then
        return self._union_task_info[key]
    elseif self._life_task_list[key] ~= nil then
        return self._life_task_list[key]
    elseif self._daily_task_list[key] ~= nil then
        return self._daily_task_list[key]
    end
    return nil
end

function get_task_by_type(self, task_type)
    if task_type == TASK_TYPE.TASK_TYPE_DAILY then
        return self._daily_task_list
    elseif task_type == TASK_TYPE.TASK_TYPE_TRUNK or task_type == TASK_TYPE.TASK_TYPE_BRANCH then
        return self._life_task_list
    elseif task_type == TASK_TYPE.TASK_TYPE_UNION then
        return self._union_task_info
    end
end

function get_task_by_manager_type(self, manager_type)
    local task_array = {}
    local find = function(array)
        for k, v in pairs(array) do
            if v.task_manager_type == manager_type and v.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
                table.insert(task_array, v)
            end
        end
    end

    find(self._union_task_info)
    find(self._life_task_list)
    find(self._daily_task_list)

    return task_array
end

function get_union_task_num(self)
    return self._union_num
end

function packet_list(self, src)
    local list = {}
    for k, v in pairs(src) do
        local unit = {}
        unit.task_id = v.task_id
        unit.task_type = v.task_type
        unit.current_num = v.task_current_num
        table.insert(list, unit)
    end
    return list
end

function packet_daily_task(self)
    local msg_send = self:packet_list(self._daily_task_list)
    Rpc:daily_task_list_resp(self, msg_send)
end

function packet_life_task(self)
    local msg_send = self:packet_list(self._life_task_list)
    Rpc:life_task_list_resp(self, msg_send)
end

function packet_union_task(self)
    local msg_send = self:packet_list(self._union_task_info)
    Rpc:union_task_list_resp(self, msg_send)
end

function get_award(self, task_id)
    local info = self:get_task_by_id(self, task_id)
    if info.task_status ~= TASK_STATUS.TASK_STATUS_CAN_FINISH then
        return false
    end
    local bonus_id = resmng.prop_task_detail[task_id].Bonus
    --todo 得奖励

    info.task_status = TASK_STATUS.TASK_STATUS_FINISHED

    local res = 0
    rpc:finish_task_resp(res)
end

function accept_task(task_id_array)
    local msg_send = {}
    for k, v in pairs(task_id_array) do
        local pre_task_id = resmng.prop_task_detail[v].PreTask
        local pre_task_data = self:get_task_by_id(pre_task_id)
        if pre_task_data == nil or pre_task_data.task_status ~= TASK_STATUS_FINISHED then
            break
        end

        --todo 验证条件
    end

    if #msg_send == #task_id_array then
        for k, v in pairs(task_id_array) do
            self:check_task_pre_finish(unpack(resmng.prop_task_detail[v].FinishCondition))
        end

        rpc:accept_task_resp(0)
    else
        rpc:accept_task_resp(1)
    end
end

function can_take_task(self, task_id)
    local pre_task_id = resmng.prop_task_detail[task_id].PreTask
    local pre_task_condition = resmng.prop_task_detail[task_id].PreCondition

    --判断这个任务是否已接
    local task_data = self:get_task_by_id(task_id)
    if task_data ~= nil then
        return false
    end

    --判断前置任务
    if pre_task_id ~= 0 then
        local pre_task_data = self:get_task_by_id(pre_task_id)
        if task_data == nil or task_data.task_status ~= TASK_STATUS.TASK_STATUS_FINISHED then
            return false
        end
    end

    --判断前置条件
    --return self:doCondCheck(unpack(pre_task_condition))
    return true
end

function take_daily_task(self, is_need_reset)
    if is_need_reset == true then
        self._daily_task_list = {}
    end

    for k, v in pairs(resmng.prop_task_detail) do
        if v.TaskType == TASK_TYPE.TASK_TYPE_DAILY then
            --前置任务是否完成了
            local can_take = self:can_take_task(v.ID)
            if can_take == true then
                self:add_task_data(v)
            end
        end
    end

end

function take_life_task(self)
    for k, v in pairs(resmng.prop_task_detail) do
        if v.TaskType == TASK_TYPE.TASK_TYPE_TRUNK or v.TaskType == TASK_TYPE.TASK_TYPE_BRANCH then
            --前置任务是否完成了
            local can_take = self:can_take_task(v.ID)
            if can_take == true then
                self:add_task_data(v)
            end
        end
    end
end

function take_union_task(self)

end

function change_union_task(self)
    self._union_task_info = {}

end

function task_on_day_pass(self)
    self.union_task_num = 0
    self._union_task_info = {}
    self:take_daily_task(true)
end



------------------------------------------------------------------------------------
------以下是任务具体逻辑
------------------------------------------------------------------------------------
function process_task(self, manager_type, ...)
    local task_data_array = self:get_task_by_manager_type(manager)
    for k, v in pairs(task_data_array) do
        local res = self:distribute_operation(v, unpack(v.FinishCondition), ...)
        if res == true then
            self:add_save_task_id(v.task_id) 
        end
    end
    self:do_save_task()
end

function distribute_operation(self, task_data, func, ...)
    local key = g_task_func_relation[func]
    if do_task[key] ~= nil then 
        return do_task[key](task_data, ...)
    end
end

do_task = {}

------------------------------
--攻击特定ID的怪物

do_task[TASK_MANAGER_TYPE.ATTACK_SPECIAL_MONSTER] = function(task_data, con_mid, con_num, con_acc, real_mid, real_num)
    if con_mid ~= 0 and con_mid ~= real_mid then 
        return false
    end
    if con_acc == 1 then
        if con_mid == 0 then
            return false
        end
        --判断成就
    else
        task_data.task_current_num = task_data.task_current_num + 1
        if task_data.task_current_num >= con_num then
            task_data.task_current_num = con_num
            task_data.task_status = TASK_STATUS_CAN_FINISH
        end
    end

    return true
end

-------------------------------




