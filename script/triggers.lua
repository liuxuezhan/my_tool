module("triggers_t")


triggers_funcs = {} 

-----------------------------
--event_id:触发器事件
--x,y:出发事件的坐标
--aid:带有范围的对象eid
--did:进入某个范围的对象eid
--parm1,parm2,parm3,parm4:保留参数，根据功能不同定义不同
-----------------------------
function triggers_recv(event_id, x, y, aid, did, parm1, parm2, parm3, parm4)
    if event_id == RANGE_EVENT_ID.ENTER_RANGE then
        enter_range(x, y, aid, did, parm1, parm2, parm3, parm4) 
    elseif event_id == RANGE_EVENT_ID.LEAVE_RANGE then 
        leave_range(x, y, aid, did, parm1, parm2, parm3, parm4)
    elseif event_id == RANGE_EVENT_ID.ARRIVED_TARGET then
        arrived_target(x, y, aid, did, parm1, parm2, parm3, parm4)
    else
        --do nothing
    end
end

--进入区域
function enter_range(x, y, aid, did, parm1, parm2, parm3, parm4)
    local mode = get_mode_by_eid(aid)
    if mode == EidType.Troop then
        triggers_enter_troop(x, y, aid, did, parm1, parm2, parm3, parm4)
    else
        triggers_enter_world_unit(x, y, aid, did, parm1, parm2, parm3, parm4)
    end
end

--离开区域
function leave_range(x, y, aid, did, parm1, parm2, parm3, parm4)
    local mode = get_mode_by_eid(aid)
    if mode == EidType.Troop then
        triggers_leave_troop(x, y, aid, did, parm1, parm2, parm3, parm4)
    else
        triggers_leave_world_unit(x, y, aid, did, parm1, parm2, parm3, parm4)
    end
end

--到达目的地
function arrived_target(x, y, aid, did, parm1, parm2, parm3, parm4)
    local troop = get_ety(did)
end


function triggers_enter_troop(x, y, aid, did, ...)
    
end

function triggers_leave_troop(x, y, aid, did, ...)
end

function triggers_enter_world_unit(x, y, aid, did, ...)
    local world_unit = get_ety(aid)
    if world_unit == nil then return end

    local prop_unit = resmng.prop_world_unit[world_unit.propid]
    if prop_unit == nil then return end

    local troop_unit = get_ety(did)
    if troop_unit == nil then return end
end

function triggers_leave_world_unit(x, y, aid, did, ...)
end

triggers_funcs[TRIGGERS_EVENT_ID.TRIGGERS_ACK] = function(troop)
end

triggers_funcs[TRIGGERS_EVENT_ID.TRIGGERS_SLOW] = function(troop)
    troop.speed = troop.speed - 2;
    --c_update_actor(troop.eid, troop.speed)  --更新引擎速度
end




