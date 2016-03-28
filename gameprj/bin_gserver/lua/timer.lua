
function get_time(add,base) --测试修改时间
    local a = add or 0
    local b = base or os.time()
    return base + a
end

function get_sort_1_time()--启动服务器初始化周排行榜时间

    local ret = lua_sql(1,"select UNIX_TIMESTAMP( update_time) from player_distance_1 order by update_time desc limit 1")
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            local t_time = 0  --距离上周一零点的日期
            if os.date("%w",tonumber(v[1])) == 0 then
                t_time = 6
            else
                t_time =  os.date("%w",tonumber(v[1])) - 1
            end

            local add_time = 60*60*24* t_time
            local time_del = os.time({year=os.date("%Y",tonumber(v[1])),month=os.date("%m",tonumber(v[1])),day=os.date("%d",tonumber(v[1])), hour=0, min=0, sec=0})
            return  (time_del - add_time )
        end
    end

    local t_time = 0  --距离上周一零点的日期
    if os.date("%w") == 0 then
        t_time = 6
    else
        t_time =  os.date("%w") - 1
    end
    local add_time = 60*60*24*t_time
    local time_del = os.time({year=os.date("%Y"),month=os.date("%m"),day=os.date("%d"), hour=0, min=0, sec=0})
    return  (time_del - add_time )

end

function get_sort_2_time()--启动服务器初始化月排行榜时间

    local ret = lua_sql(1,"select UNIX_TIMESTAMP( update_time) from player_distance_2  order by update_time desc limit 1")
    if type(ret) == "table" then
        for k,v in pairs(ret) do
             return tonumber(v[1])
        end
    end
    return os.time()

end


function on_time_get()  --读定时器

    local v = _timer_list[1]
    if os.time() > v.begin+v.sec then --统计周排行
        sort_distance_1()
        v.begin = os.time()
    end

    v = _timer_list[2]
    if os.time() > v.begin+v.sec then --统计月排行
        sort_distance_2()
        v.begin = os.time()
    end

    v = _timer_list[3]
    if os.time() > v.begin+v.sec then --统计总排行
        sort_distance()
        v.begin = os.time()
    end
end

function on_time_set() --写定时器

    local v = _timer_list[101]  --初始化周排行
    local add_time = 60*60*24*7 --一周时间
    if os.time() > (v.begin + add_time) then
        lxz()
        init_sort_1()
        v.begin =(v.begin + add_time)
    end

    v = _timer_list[102]  --初始化月排行
    lxz(os.date("%m"))
    lxz(os.date("%m",v.begin))
    if os.date("%m") ~= os.date("%m",v.begin) then
        init_sort_2()
        v.begin = os.time()
    end

end

function sort_distance()

    local _sort_distance_max     = 100 -- 排序最大数量
    _sort_disatance={}

    local ret = lua_sql(2,"select player_id, distance from player_distance order by distance desc limit ".._sort_distance_max)
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            _sort_disatance[k]={}
            local ret2 = lua_sql(3,"select name,nation,www_id from reg_info where player_id = "..tonumber(v[1]))
            if type(ret2) == "table" then
                for _,v2 in pairs(ret2) do
                    _sort_disatance[k].name=tostring(v2[1])
                    _sort_disatance[k].nation=tonumber(v2[2])
                    _sort_disatance[k].distance=tonumber(v[2])
                    _sort_disatance[k].id=tonumber(v[1])
                    _sort_disatance[k].www_id=tostring(v2[3])
                end
            end
        end
    end

end

function sort_distance_1()
    local _sort_distance_max     = 100 -- 排序最大数量
    _sort_disatance_1={}

    local ret = lua_sql(2,"select player_id, distance from player_distance_1 order by distance desc limit ".._sort_distance_max)
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            _sort_disatance_1[k]={}
            local ret2 = lua_sql(3,"select name,nation,www_id from reg_info where player_id = "..tonumber(v[1]))
            if type(ret2) == "table" then
                for _,v2 in pairs(ret2) do
                    _sort_disatance_1[k].name=tostring(v2[1])
                    _sort_disatance_1[k].nation=tonumber(v2[2])
                    _sort_disatance_1[k].distance=tonumber(v[2])
                    _sort_disatance_1[k].id=tonumber(v[1])
                    _sort_disatance_1[k].www_id=tostring(v2[3])
                end
            end
        end
    end

end

function sort_distance_2()
    local _sort_distance_max     = 100 -- 排序最大数量
    _sort_disatance_2={}

    local ret = lua_sql(2,"select player_id, distance from player_distance_2 order by distance desc limit ".._sort_distance_max)
    if type(ret) == "table" then
        for k,v in pairs(ret) do
            _sort_disatance_2[k]={}
            local ret2 = lua_sql(3,"select name,nation,www_id from reg_info where player_id = "..tonumber(v[1]))
            if type(ret2) == "table" then
                for _,v2 in pairs(ret2) do
                    _sort_disatance_2[k].name=tostring(v2[1])
                    _sort_disatance_2[k].nation=tonumber(v2[2])
                    _sort_disatance_2[k].distance=tonumber(v[2])
                    _sort_disatance_2[k].id=tonumber(v[1])
                    _sort_disatance_2[k].www_id=tostring(v2[3])
                end
            end
        end
    end
end

function init_sort_1()
    lua_sql(0,"update player_distance_1 set distance = 0  ")
end
function save_sort_file(sort,path)
    if type(sort) == "table" then
    	local buf = ""
    	for k,v in pairs(sort) do
       	 buf = buf..v['name'].."\t"..v['www_id'].."\t"..v['distance'].."\n"
   	 end
   	 save_file( "a",path,buf)
    end
end

function init_sort_2()

	sort_distance()
	sort_distance_1()
	sort_distance_2()
	save_sort_file(_sort_disatance,"sort0.xls")
	save_sort_file(_sort_disatance_1,"sort1.xls")
	save_sort_file(_sort_disatance_2,"sort2.xls")
    lua_sql(0,"update player_distance_2 set distance = 0  ")
end


