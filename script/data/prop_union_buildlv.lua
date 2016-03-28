--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_union_buildlv = {

	[UNION_BUILD_CASTLE_LEVEL_1] = { ID = UNION_BUILD_CASTLE_LEVEL_1, Class = 10, Mode = 1, Lv = 1, Cons = {{2,1000},{2,10000},{2,10000}}, Cond = nil, Num = 1,},
	[UNION_BUILD_CASTLE_LEVEL_2] = { ID = UNION_BUILD_CASTLE_LEVEL_2, Class = 10, Mode = 1, Lv = 2, Cons = {{2,1000},{2,10000},{2,10001}}, Cond = {{9,1001}}, Num = 1,},
	[UNION_BUILD_CASTLE_LEVEL_3] = { ID = UNION_BUILD_CASTLE_LEVEL_3, Class = 10, Mode = 1, Lv = 3, Cons = {{2,1000},{2,10000},{2,10002}}, Cond = {{9,1002}}, Num = 1,},
	[UNION_BUILD_TUTTER_LEVEL_1] = { ID = UNION_BUILD_TUTTER_LEVEL_1, Class = 10, Mode = 3, Lv = 1, Cons = {{2,1000},{2,10000},{2,10009}}, Cond = {{9,1001}}, Num = 2,},
	[UNION_BUILD_TUTTER_LEVEL_2] = { ID = UNION_BUILD_TUTTER_LEVEL_2, Class = 10, Mode = 3, Lv = 2, Cons = {{2,1000},{2,10000},{2,10010}}, Cond = {{9,1002},{9,2001}}, Num = 3,},
	[UNION_BUILD_TUTTER_LEVEL_3] = { ID = UNION_BUILD_TUTTER_LEVEL_3, Class = 10, Mode = 3, Lv = 3, Cons = {{2,1000},{2,10000},{2,10011}}, Cond = {{9,1003},{9,2002}}, Num = 4,},
	[UNION_BUILD_MINE_LEVEL_1] = { ID = UNION_BUILD_MINE_LEVEL_1, Class = 10, Mode = 4, Lv = 1, Cons = {{2,1000},{2,10000},{2,10018}}, Cond = {{9,1001}}, Num = 1,},
	[UNION_BUILD_MINE_LEVEL_2] = { ID = UNION_BUILD_MINE_LEVEL_2, Class = 10, Mode = 4, Lv = 2, Cons = {{2,1000},{2,10000},{2,10019}}, Cond = {{9,1002},{9,3001}}, Num = 2,},
	[UNION_BUILD_MINE_LEVEL_3] = { ID = UNION_BUILD_MINE_LEVEL_3, Class = 10, Mode = 4, Lv = 3, Cons = {{2,1000},{2,10000},{2,10020}}, Cond = {{9,1003},{9,3002}}, Num = 2,},
}
