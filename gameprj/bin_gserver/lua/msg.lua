--消息处理

function msg_to_lua(player_id,msg,input)--入口函数
  --  lxz( {collectgarbage("count"),msg,player_id} )---检测内存
 --   lxz(input)
    local ret =  _G[msg](player_id,input)
    lxz(ret)
    return ret
end

function OnLogin(player_id,input)--上线

    local id = input[1]  or  0

    return id
end

function OffLine(player_id,input)--下线

    return 0
end

function get_player_num1(player_id,input)--周排行击败多少玩家

    local t_distance = 0
    local ret = lua_sql(1,"select distance from player_distance_1 where player_id = "..player_id )
    if type(ret) == "table" then
        for _,v in pairs(ret) do
            t_distance = tonumber(v[1])
        end
    end

    local ret = lua_sql(1,"select count(*) from player_distance_1 where distance < "..t_distance)
    if type(ret) == "table" then
        for _,v in pairs(ret) do
            return {tonumber(v[1])*100/ _cur_player_num,t_distance}
        end
    end

    return {0,t_distance}

end

function get_player_num2(player_id,input)--月排行击败多少玩家

    local t_distance = 0
    local ret = lua_sql(1,"select distance from player_distance_2 where player_id = "..player_id )
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            t_distance = tonumber(v[1])
        end
    end

    local ret = lua_sql(1,"select count(*) from player_distance_2 where distance < "..t_distance)
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            return {tonumber(v[1])*100/ _cur_player_num,t_distance}
        end
    end

    return {0,t_distance}
end

function get_player_num3(player_id,input)--总排行击败多少玩家

    local t_distance = 0
    local ret = lua_sql(1,"select distance from player_distance where player_id = "..player_id )
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            t_distance = tonumber(v[1])
        end
    end

    local ret = lua_sql(1,"select count(*) from player_distance where distance < "..t_distance)
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            return {tonumber(v[1])*100 / _cur_player_num,t_distance}
        end
    end

    return {0,t_distance}
end

function OnRegister(id,input)--注册

    local player = 0
    local ret = lua_sql(1,"select player_id from reg_info where www_id = '"..input[4].."'")
    if type(ret) == "table" then
        for _,v in pairs(ret) do
            player = tonumber(v[1])
        end
    end

    if player ~= 0 then  --已有账号重装游戏后注册
        local ret = lua_sql(0,"update reg_info set nation="..input[3]..", name = '"..input[1].."'  where player_id = "..player )
        return player
    else
        _cur_player_max_id = _cur_player_max_id + 1

        local ret = lua_sql(0,"insert into reg_info (player_id,name,pwd,nation,www_id) VALUES(" .._cur_player_max_id..",'"..input[1].."',AES_ENCRYPT('"..input[2].."','key'), "..input[3]..",'"..input[4].."' )")

        if ret~=0 then
            _cur_player_max_id = _cur_player_max_id - 1
            return 2
        else
            lua_sql(0,"insert into player_distance (player_id,distance) VALUES(" .._cur_player_max_id..",0 )")
            lua_sql(0,"insert into player_distance_1 (player_id,distance) VALUES(" .._cur_player_max_id..",0 )")
            lua_sql(0,"insert into player_distance_2 (player_id,distance) VALUES(" .._cur_player_max_id..",0 )")
            _cur_player_num = _cur_player_num + 1
            return _cur_player_max_id
        end
    end



end

function MSG1_CS_PLAYER_INFO_fun(player_id,input) --保存玩家数据
   local ret = 0

   on_time_set()

   local distance=tonumber(input.distance)

    lxz(distance)

    ret = lua_sql(1,"select distance from player_distance where player_id = "..player_id)
    if type(ret) == "table" then
        for _,v in pairs(ret) do
            if tonumber(v[1]) < distance then
                ret = lua_sql (0,"update player_distance set distance = " ..distance.." where player_id = "..player_id )
            end
        end
    end

    ret = lua_sql(1,"select distance from player_distance_1 where player_id = "..player_id)
    if type(ret) == "table" then
        for _,v in pairs(ret) do
            if tonumber(v[1]) < distance then
                ret = lua_sql (0,"update player_distance_1 set distance = " ..distance.." where player_id = "..player_id )
            end
        end
    end

    ret = lua_sql(1,"select distance from player_distance_2 where player_id = "..player_id)
    if type(ret) == "table" then
        for _,v in pairs(ret) do
            if tonumber(v[1]) < distance then
                ret = lua_sql (0,"update player_distance_2 set distance = " ..distance.." where player_id = "..player_id )
            end
        end
    end

    return 0
end
--[[
function MSG1_CS_GET_OTHER_PLAYER_fun(player_id,input) --获取其他玩家数据
    local ret={}
    local sql = "select  player_id,distance from reg_info where player_id in ( "
    local distance = 0
    local list ={}
    local b=0;

    for i,v in pairs(input) do

       local id = _list_reg[v].id

        if _list_player[id].online ==1 then
            if _list_player[id].other ~=nil then
                distance = _list_player[id].other.distance or 0
            end
            local row ={v, distance}
            table.insert(list, row )
        else
            if b~=0 then
                sql =","..sql
            else
                sql =sql..id
            end
        end

    end

     local ret = lua_sql(0,2,sql..")")
    if type(ret) == "table" then
        for i,v in pairs(ret) do
             local row ={v[1], v[2]}
            table.insert(list, row )
        end
    end
    return list
end
--]]
function MSG1_CS_GET_PLAYER_INFO_fun(player_id,input) --获取自己数据


    return 0
end

function MSG1_CS_GET_PLAYER_ORDER_fun(player_id,input) --获取周排行
    on_time_get()

    return _sort_disatance_1
end

function MSG1_CS_GET_PLAYER_ORDER2_fun(player_id,input) --获取月排行
    on_time_get()
    return _sort_disatance_2
end

function MSG1_CS_GET_PLAYER_ORDER3_fun(player_id,input) --获取总排行
    on_time_get()
    return _sort_disatance
end


