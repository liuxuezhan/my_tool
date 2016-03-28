--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_union_build = {

	[UNION_BUILD_CASTLE_1] = { ID = UNION_BUILD_CASTLE_1, Class = 1, Mode = 1, Lv = 1, Name = "奇迹", Cond = nil, Dura = 400, Range = 12, Buff = {WoodSpeed=3000,FoodSpeed=3000}, Debuff = nil, Speed = 10, Count = 20000,},
	[UNION_BUILD_CASTLE_2] = { ID = UNION_BUILD_CASTLE_2, Class = 1, Mode = 1, Lv = 2, Name = "奇迹", Cond = nil, Dura = 400, Range = 12, Buff = {WoodSpeed=3000,FoodSpeed=3000}, Debuff = nil, Speed = 10, Count = 20000,},
	[UNION_BUILD_CASTLE_3] = { ID = UNION_BUILD_CASTLE_3, Class = 1, Mode = 1, Lv = 3, Name = "奇迹", Cond = nil, Dura = 400, Range = 12, Buff = {WoodSpeed=3000,FoodSpeed=3000}, Debuff = nil, Speed = 10, Count = 20000,},
	[UNION_BUILD_MINI_CASTLE_1] = { ID = UNION_BUILD_MINI_CASTLE_1, Class = 2, Mode = 2, Lv = 1, Name = "小奇迹", Cond = nil, Dura = 400, Range = 6, Buff = nil, Debuff = nil, Speed = nil, Count = nil,},
	[UNION_BUILD_TUTTER1_1] = { ID = UNION_BUILD_TUTTER1_1, Class = 3, Mode = 3, Lv = 1, Name = "联盟箭塔1", Cond = nil, Dura = 300, Range = 4, Buff = {{4,"Range",1},{2,"AtkSpeed",10},{3,"Atk",100}}, Debuff = {Atk=100,AtkSpeed=100}, Speed = 10, Count = 20000,},
	[UNION_BUILD_TUTTER1_2] = { ID = UNION_BUILD_TUTTER1_2, Class = 3, Mode = 3, Lv = 2, Name = "联盟箭塔1", Cond = nil, Dura = 300, Range = 4, Buff = {{4,"Range",1},{2,"AtkSpeed",10},{3,"Atk",100}}, Debuff = {Atk=100,AtkSpeed=100}, Speed = 10, Count = 20000,},
	[UNION_BUILD_TUTTER1_3] = { ID = UNION_BUILD_TUTTER1_3, Class = 3, Mode = 3, Lv = 3, Name = "联盟箭塔1", Cond = nil, Dura = 300, Range = 4, Buff = {{4,"Range",1},{2,"AtkSpeed",10},{3,"Atk",100}}, Debuff = {Atk=100,AtkSpeed=100}, Speed = 10, Count = 20000,},
	[UNION_BUILD_TUTTER2_1] = { ID = UNION_BUILD_TUTTER2_1, Class = 3, Mode = 4, Lv = 1, Name = "联盟箭塔2", Cond = nil, Dura = 300, Range = 4, Buff = {{4,"Range",1},{2,"AtkSpeed",10},{3,"Atk",100}}, Debuff = {SpeedRate=-5000,Atk=100,AtkSpeed=100}, Speed = 10, Count = 20000,},
	[UNION_BUILD_TUTTER2_2] = { ID = UNION_BUILD_TUTTER2_2, Class = 3, Mode = 4, Lv = 2, Name = "联盟箭塔2", Cond = nil, Dura = 300, Range = 4, Buff = {{4,"Range",1},{2,"AtkSpeed",10},{3,"Atk",100}}, Debuff = {SpeedRate=-5000,Atk=100,AtkSpeed=101}, Speed = 10, Count = 20000,},
	[UNION_BUILD_TUTTER2_3] = { ID = UNION_BUILD_TUTTER2_3, Class = 3, Mode = 4, Lv = 3, Name = "联盟箭塔2", Cond = nil, Dura = 300, Range = 4, Buff = {{4,"Range",1},{2,"AtkSpeed",10},{3,"Atk",100}}, Debuff = {SpeedRate=-5000,Atk=100,AtkSpeed=102}, Speed = 10, Count = 20000,},
	[UNION_BUILD_FARM_1] = { ID = UNION_BUILD_FARM_1, Class = 4, Mode = 5, Lv = 1, Name = "联盟农田", Cond = nil, Dura = 500, Range = nil, Buff = nil, Debuff = nil, Speed = nil, Count = nil,},
	[UNION_BUILD_FARM_2] = { ID = UNION_BUILD_FARM_2, Class = 4, Mode = 5, Lv = 2, Name = "联盟农田", Cond = nil, Dura = 500, Range = nil, Buff = nil, Debuff = nil, Speed = nil, Count = nil,},
	[UNION_BUILD_FARM_3] = { ID = UNION_BUILD_FARM_3, Class = 4, Mode = 5, Lv = 3, Name = "联盟农田", Cond = nil, Dura = 500, Range = nil, Buff = nil, Debuff = nil, Speed = nil, Count = nil,},
	[UNION_BUILD_LOGGINGCAMP_1] = { ID = UNION_BUILD_LOGGINGCAMP_1, Class = 4, Mode = 6, Lv = 1, Name = "联盟伐木场", Cond = nil, Dura = 500, Range = nil, Buff = nil, Debuff = nil, Speed = nil, Count = nil,},
	[UNION_BUILD_LOGGINGCAMP_2] = { ID = UNION_BUILD_LOGGINGCAMP_2, Class = 4, Mode = 6, Lv = 2, Name = "联盟伐木场", Cond = nil, Dura = 500, Range = nil, Buff = nil, Debuff = nil, Speed = nil, Count = nil,},
	[UNION_BUILD_LOGGINGCAMP_3] = { ID = UNION_BUILD_LOGGINGCAMP_3, Class = 4, Mode = 6, Lv = 3, Name = "联盟伐木场", Cond = nil, Dura = 500, Range = nil, Buff = nil, Debuff = nil, Speed = nil, Count = nil,},
}
