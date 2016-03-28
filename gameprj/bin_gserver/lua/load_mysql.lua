
function load_mysql()--入口函数
    --全局加载
    MAX_USER_NUM      = 20000000 --最大注册用户数
    START_USER_ID     = 10000 -- 玩家ID开始值
    _cur_player_max_id = START_USER_ID
    MAX_USER_ID       = MAX_USER_NUM - START_USER_ID - 2 --最大玩家ID

--玩家注册数据

    local ret = lua_sql(1,"select player_id from reg_info order by player_id desc limit 1")
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            _cur_player_max_id = tonumber( v[1])
        end
    end

    local ret = lua_sql(1,"select count(player_id) from reg_info ")
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            _cur_player_num = tonumber( v[1])
        end
    end


    return 0

end
