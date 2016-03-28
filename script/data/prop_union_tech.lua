--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_union_tech = {

	[UNION_TECH_10101] = { ID = UNION_TECH_10101, Class = 1, Mode = 1, Lv = 0, Idx = 1001, TmLevelUp = 60, Exp = 100, Star = 2, Condition = nil, Effect = {EF_GATHERSPEED_R=10}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10102] = { ID = UNION_TECH_10102, Class = 1, Mode = 1, Lv = 1, Idx = 1001, TmLevelUp = 60, Exp = 100, Star = 3, Condition = {8,10101}, Effect = {EF_GATHERSPEED_R=20}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10103] = { ID = UNION_TECH_10103, Class = 1, Mode = 1, Lv = 2, Idx = 1001, TmLevelUp = 60, Exp = 100, Star = 4, Condition = {8,10102}, Effect = {EF_GATHERSPEED_R=30}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10104] = { ID = UNION_TECH_10104, Class = 1, Mode = 1, Lv = 3, Idx = 1001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10103}, Effect = {EF_GATHERSPEED_R=40}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10105] = { ID = UNION_TECH_10105, Class = 1, Mode = 1, Lv = 4, Idx = 1001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10104}, Effect = {EF_GATHERSPEED_R=50}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10106] = { ID = UNION_TECH_10106, Class = 1, Mode = 1, Lv = 5, Idx = 1001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10105}, Effect = {EF_GATHERSPEED_R=60}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10107] = { ID = UNION_TECH_10107, Class = 1, Mode = 1, Lv = 6, Idx = 1001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10106}, Effect = {EF_GATHERSPEED_R=70}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10108] = { ID = UNION_TECH_10108, Class = 1, Mode = 1, Lv = 7, Idx = 1001, TmLevelUp = 60, Exp = 100, Star = 6, Condition = {8,10107}, Effect = {EF_GATHERSPEED_R=80}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10109] = { ID = UNION_TECH_10109, Class = 1, Mode = 1, Lv = 8, Idx = 1001, TmLevelUp = 60, Exp = 100, Star = 6, Condition = {8,10108}, Effect = {EF_GATHERSPEED_R=90}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10110] = { ID = UNION_TECH_10110, Class = 1, Mode = 1, Lv = 9, Idx = 1001, TmLevelUp = 60, Exp = 0, Star = 0, Condition = nil, Effect = {EF_GATHERSPEED_R=100}, Name = UNION_TECH_NAME_10101, Desc = UNION_TECH_DESC_10101, DescARG = nil,},
	[UNION_TECH_10201] = { ID = UNION_TECH_10201, Class = 1, Mode = 2, Lv = 0, Idx = 1002, TmLevelUp = 60, Exp = 100, Star = 2, Condition = {8,10101}, Effect = {EF_GATHERSPEED_R=50}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_10202] = { ID = UNION_TECH_10202, Class = 1, Mode = 2, Lv = 1, Idx = 1002, TmLevelUp = 60, Exp = 100, Star = 3, Condition = {8,10102}, Effect = {EF_GATHERSPEED_R=51}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_10203] = { ID = UNION_TECH_10203, Class = 1, Mode = 2, Lv = 2, Idx = 1002, TmLevelUp = 60, Exp = 100, Star = 4, Condition = {8,10103}, Effect = {EF_GATHERSPEED_R=52}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_10204] = { ID = UNION_TECH_10204, Class = 1, Mode = 2, Lv = 3, Idx = 1002, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10104}, Effect = {EF_GATHERSPEED_R=53}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_10205] = { ID = UNION_TECH_10205, Class = 1, Mode = 2, Lv = 4, Idx = 1002, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10105}, Effect = {EF_GATHERSPEED_R=54}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_10206] = { ID = UNION_TECH_10206, Class = 1, Mode = 2, Lv = 5, Idx = 1002, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10106}, Effect = {EF_GATHERSPEED_R=55}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_10207] = { ID = UNION_TECH_10207, Class = 1, Mode = 2, Lv = 6, Idx = 1002, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10107}, Effect = {EF_GATHERSPEED_R=56}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_10208] = { ID = UNION_TECH_10208, Class = 1, Mode = 2, Lv = 7, Idx = 1002, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10108}, Effect = {EF_GATHERSPEED_R=57}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_10209] = { ID = UNION_TECH_10209, Class = 1, Mode = 2, Lv = 8, Idx = 1002, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10109}, Effect = {EF_GATHERSPEED_R=58}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_10210] = { ID = UNION_TECH_10210, Class = 1, Mode = 2, Lv = 9, Idx = 1002, TmLevelUp = 60, Exp = 0, Star = 0, Condition = nil, Effect = {EF_GATHERSPEED_R=59}, Name = UNION_TECH_NAME_10201, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_20101] = { ID = UNION_TECH_20101, Class = 2, Mode = 1, Lv = 0, Idx = 2001, TmLevelUp = 60, Exp = 100, Star = 2, Condition = {8,10101}, Effect = {Atk1R=100}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_10201, DescARG = nil,},
	[UNION_TECH_20102] = { ID = UNION_TECH_20102, Class = 2, Mode = 1, Lv = 1, Idx = 2001, TmLevelUp = 60, Exp = 100, Star = 3, Condition = {8,10102}, Effect = {Atk1R=200}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_20101, DescARG = nil,},
	[UNION_TECH_20103] = { ID = UNION_TECH_20103, Class = 2, Mode = 1, Lv = 2, Idx = 2001, TmLevelUp = 60, Exp = 100, Star = 4, Condition = {8,10103}, Effect = {Atk1R=300}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_20101, DescARG = nil,},
	[UNION_TECH_20104] = { ID = UNION_TECH_20104, Class = 2, Mode = 1, Lv = 3, Idx = 2001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10104}, Effect = {Atk1R=400}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_20101, DescARG = nil,},
	[UNION_TECH_20105] = { ID = UNION_TECH_20105, Class = 2, Mode = 1, Lv = 4, Idx = 2001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10105}, Effect = {Atk1R=500}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_20101, DescARG = nil,},
	[UNION_TECH_20106] = { ID = UNION_TECH_20106, Class = 2, Mode = 1, Lv = 5, Idx = 2001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10106}, Effect = {Atk1R=600}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_20101, DescARG = nil,},
	[UNION_TECH_20107] = { ID = UNION_TECH_20107, Class = 2, Mode = 1, Lv = 6, Idx = 2001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10107}, Effect = {Atk1R=700}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_20101, DescARG = nil,},
	[UNION_TECH_20108] = { ID = UNION_TECH_20108, Class = 2, Mode = 1, Lv = 7, Idx = 2001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10108}, Effect = {Atk1R=800}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_20101, DescARG = nil,},
	[UNION_TECH_20109] = { ID = UNION_TECH_20109, Class = 2, Mode = 1, Lv = 8, Idx = 2001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10109}, Effect = {Atk1R=900}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_20101, DescARG = nil,},
	[UNION_TECH_20110] = { ID = UNION_TECH_20110, Class = 2, Mode = 1, Lv = 9, Idx = 2001, TmLevelUp = 60, Exp = 0, Star = 0, Condition = nil, Effect = {Atk1R=1000}, Name = UNION_TECH_NAME_20101, Desc = UNION_TECH_DESC_20101, DescARG = nil,},
	[UNION_TECH_30101] = { ID = UNION_TECH_30101, Class = 3, Mode = 1, Lv = 0, Idx = 3001, TmLevelUp = 60, Exp = 100, Star = 2, Condition = {8,10101}, Effect = {Atk2R=100}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
	[UNION_TECH_30102] = { ID = UNION_TECH_30102, Class = 3, Mode = 1, Lv = 1, Idx = 3001, TmLevelUp = 60, Exp = 100, Star = 3, Condition = {8,10102}, Effect = {Atk2R=200}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
	[UNION_TECH_30103] = { ID = UNION_TECH_30103, Class = 3, Mode = 1, Lv = 2, Idx = 3001, TmLevelUp = 60, Exp = 100, Star = 4, Condition = {8,10103}, Effect = {Atk2R=300}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
	[UNION_TECH_30104] = { ID = UNION_TECH_30104, Class = 3, Mode = 1, Lv = 3, Idx = 3001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10104}, Effect = {Atk2R=400}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
	[UNION_TECH_30105] = { ID = UNION_TECH_30105, Class = 3, Mode = 1, Lv = 4, Idx = 3001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10105}, Effect = {Atk2R=500}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
	[UNION_TECH_30106] = { ID = UNION_TECH_30106, Class = 3, Mode = 1, Lv = 5, Idx = 3001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10106}, Effect = {Atk2R=600}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
	[UNION_TECH_30107] = { ID = UNION_TECH_30107, Class = 3, Mode = 1, Lv = 6, Idx = 3001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10107}, Effect = {Atk2R=700}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
	[UNION_TECH_30108] = { ID = UNION_TECH_30108, Class = 3, Mode = 1, Lv = 7, Idx = 3001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10108}, Effect = {Atk2R=800}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
	[UNION_TECH_30109] = { ID = UNION_TECH_30109, Class = 3, Mode = 1, Lv = 8, Idx = 3001, TmLevelUp = 60, Exp = 100, Star = 5, Condition = {8,10109}, Effect = {Atk2R=900}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
	[UNION_TECH_30110] = { ID = UNION_TECH_30110, Class = 3, Mode = 1, Lv = 9, Idx = 3001, TmLevelUp = 60, Exp = 0, Star = 0, Condition = nil, Effect = {Atk2R=1000}, Name = UNION_TECH_NAME_30101, Desc = UNION_TECH_DESC_30101, DescARG = nil,},
}
