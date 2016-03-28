--ﾖﾃ
dofile("lua/base.lua")
dofile("lua/load_mysql.lua")
dofile("lua/msg.lua")
dofile("lua/timer.lua")
dofile("lua/conf.lua")

m_DB = c_connect_db(db_address,db_username,db_pwd,db_database,db_port)
--定时器处理
_timer_list = {
                [1]={sec=30,begin=os.time()}, --统计周排行
                [2]={sec=30,begin=os.time()}, --统计月排行
                [3]={sec=30,begin=os.time()}, --总排行
                [101]={sec=0,begin=get_sort_1_time()}, --初始化周排行
                [102]={sec=0,begin=get_sort_2_time()}, --初始化月排行

                }
lxz(os.date("%c",_timer_list[101].begin))
sort_distance()
sort_distance_1()
sort_distance_2()

--load_file ("conf/test.csv")
local script="local ee={[1]={id=0,lv=5,text='yy'},[2]={id=1,lv=3,text='zz'},[3]=2,} return ee"
local tb=assert(loadstring(script))()
lxz(tb)

print(os.time())
print(os.date("%Y-%m-%d %H:%M:%S"))
print(os.time({year=2015,month=3,day=5, hour=22, min=47, sec=42}))
--lxz(MSG1_CS_GET_PLAYER_INFO_fun(10001,{}))
lxz( collectgarbage("count") )---检测内存





