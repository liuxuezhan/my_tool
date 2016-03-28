dofile("lua/conf.lua")
dofile("lua/base.lua")
m_DB = c_connect_db(db_address,db_username,db_pwd,db_database,db_port)
function player_log(id,str)
lxz(str)
    local ret = lua_sql(0,"insert into player_log (player_id,save) VALUES(" ..id..",'"..str.."')",1,id)
end
