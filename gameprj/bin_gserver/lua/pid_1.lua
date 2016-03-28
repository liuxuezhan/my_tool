--ﾖﾃ
dofile("lua/base.lua")
dofile("lua/msg.lua")
dofile("lua/conf.lua")
lxz( collectgarbage("count") )---检测内存
lxz()
m_DB = c_connect_db(db_address,db_username,db_pwd,db_database,db_port)
lxz(m_DB)





