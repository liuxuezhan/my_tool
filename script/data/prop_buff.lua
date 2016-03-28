--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_buff = {

	[BUFF_1] = { ID = BUFF_1, Class = 0, Cond = nil, Value = {Atk_R=1000,Def_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_1",},
	[BUFF_2] = { ID = BUFF_2, Class = 0, Cond = {"BMODE", 4}, Value = {Def_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_2",},
	[BUFF_3] = { ID = BUFF_3, Class = 0, Cond = nil, Value = {Atk_R=-2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_3",},
	[BUFF_4] = { ID = BUFF_4, Class = 0, Cond = nil, Value = {Atk_R=1500}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_4",},
	[BUFF_5] = { ID = BUFF_5, Class = 0, Cond = nil, Value = {Def_R=-2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_5",},
	[BUFF_6] = { ID = BUFF_6, Class = 0, Cond = nil, Value = {Def_R=2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_6",},
	[BUFF_7] = { ID = BUFF_7, Class = 0, Cond = {"BMODE", 4}, Value = {Def_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_7",},
	[BUFF_8] = { ID = BUFF_8, Class = 0, Cond = nil, Value = {Atk_R=-1500}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_8",},
	[BUFF_9] = { ID = BUFF_9, Class = 0, Cond = nil, Value = {Atk_R=1500}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_9",},
	[BUFF_10] = { ID = BUFF_10, Class = 0, Cond = {"BMODE", 2}, Value = {Atk_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_10",},
	[BUFF_11] = { ID = BUFF_11, Class = 0, Cond = nil, Value = {Atk_R=-2500}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_11",},
	[BUFF_12] = { ID = BUFF_12, Class = 0, Cond = nil, Value = {Atk_R=2500}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_12",},
	[BUFF_13] = { ID = BUFF_13, Class = 0, Cond = {"DMODE", 2}, Value = {Atk_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_13",},
	[BUFF_14] = { ID = BUFF_14, Class = 0, Cond = nil, Value = {Def_R=1500}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_14",},
	[BUFF_15] = { ID = BUFF_15, Class = 0, Cond = nil, Value = {Atk_R=-2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_15",},
	[BUFF_16] = { ID = BUFF_16, Class = 0, Cond = nil, Value = {Atk_R=-1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_16",},
	[BUFF_17] = { ID = BUFF_17, Class = 1, Cond = {"BTYPE",1,1}, Value = {FoodSpeed_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_17",},
	[BUFF_18] = { ID = BUFF_18, Class = 1, Cond = {"BTYPE",1,1}, Value = {FoodSpeed_R=2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_18",},
	[BUFF_19] = { ID = BUFF_19, Class = 1, Cond = {"BTYPE",1,1}, Value = {FoodSpeed_R=3000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_19",},
	[BUFF_20] = { ID = BUFF_20, Class = 1, Cond = {"BTYPE",1,1}, Value = {FoodSpeed_R=4000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_20",},
	[BUFF_21] = { ID = BUFF_21, Class = 1, Cond = {"BTYPE",1,1}, Value = {FoodSpeed_R=5000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_21",},
	[BUFF_22] = { ID = BUFF_22, Class = 1, Cond = {"BTYPE",1,2}, Value = {WoodSpeed_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_22",},
	[BUFF_23] = { ID = BUFF_23, Class = 1, Cond = {"BTYPE",1,2}, Value = {WoodSpeed_R=2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_23",},
	[BUFF_24] = { ID = BUFF_24, Class = 1, Cond = {"BTYPE",1,2}, Value = {WoodSpeed_R=3000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_24",},
	[BUFF_25] = { ID = BUFF_25, Class = 1, Cond = {"BTYPE",1,2}, Value = {WoodSpeed_R=4000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_25",},
	[BUFF_26] = { ID = BUFF_26, Class = 1, Cond = {"BTYPE",1,2}, Value = {WoodSpeed_R=5000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_26",},
	[BUFF_27] = { ID = BUFF_27, Class = 1, Cond = {"BTYPE",1,3}, Value = {IronSpeed_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_27",},
	[BUFF_28] = { ID = BUFF_28, Class = 1, Cond = {"BTYPE",1,3}, Value = {IronSpeed_R=2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_28",},
	[BUFF_29] = { ID = BUFF_29, Class = 1, Cond = {"BTYPE",1,3}, Value = {IronSpeed_R=3000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_29",},
	[BUFF_30] = { ID = BUFF_30, Class = 1, Cond = {"BTYPE",1,3}, Value = {IronSpeed_R=4000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_30",},
	[BUFF_31] = { ID = BUFF_31, Class = 1, Cond = {"BTYPE",1,3}, Value = {IronSpeed_R=5000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_31",},
	[BUFF_32] = { ID = BUFF_32, Class = 1, Cond = {"BTYPE",1,4}, Value = {EnergySpeed_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_32",},
	[BUFF_33] = { ID = BUFF_33, Class = 1, Cond = {"BTYPE",1,4}, Value = {EnergySpeed_R=2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_33",},
	[BUFF_34] = { ID = BUFF_34, Class = 1, Cond = {"BTYPE",1,4}, Value = {EnergySpeed_R=3000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_34",},
	[BUFF_35] = { ID = BUFF_35, Class = 1, Cond = {"BTYPE",1,4}, Value = {EnergySpeed_R=4000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_35",},
	[BUFF_36] = { ID = BUFF_36, Class = 1, Cond = {"BTYPE",1,4}, Value = {EnergySpeed_R=5000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_36",},
	[BUFF_37] = { ID = BUFF_37, Class = 1, Cond = {"BTYPE",2}, Value = {TrainSpeed_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_37",},
	[BUFF_38] = { ID = BUFF_38, Class = 1, Cond = {"BTYPE",2}, Value = {TrainSpeed_R=2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_38",},
	[BUFF_39] = { ID = BUFF_39, Class = 1, Cond = {"BTYPE",2}, Value = {TrainSpeed_R=3000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_39",},
	[BUFF_40] = { ID = BUFF_40, Class = 1, Cond = {"BTYPE",2}, Value = {TrainSpeed_R=4000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_40",},
	[BUFF_41] = { ID = BUFF_41, Class = 1, Cond = {"BTYPE",2}, Value = {TrainSpeed_R=5000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_41",},
	[BUFF_42] = { ID = BUFF_42, Class = 1, Cond = {"BTYPE",0,19}, Value = {CureSpeed_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_42",},
	[BUFF_43] = { ID = BUFF_43, Class = 1, Cond = {"BTYPE",0,19}, Value = {CureSpeed_R=2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_43",},
	[BUFF_44] = { ID = BUFF_44, Class = 1, Cond = {"BTYPE",0,19}, Value = {CureSpeed_R=3000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_44",},
	[BUFF_45] = { ID = BUFF_45, Class = 1, Cond = {"BTYPE",0,19}, Value = {CureSpeed_R=4000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_45",},
	[BUFF_46] = { ID = BUFF_46, Class = 1, Cond = {"BTYPE",0,19}, Value = {CureSpeed_R=5000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_46",},
	[BUFF_47] = { ID = BUFF_47, Class = 1, Cond = {"BTYPE",0,10}, Value = {TechSpeed_R=1000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_47",},
	[BUFF_48] = { ID = BUFF_48, Class = 1, Cond = {"BTYPE",0,10}, Value = {TechSpeed_R=2000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_48",},
	[BUFF_49] = { ID = BUFF_49, Class = 1, Cond = {"BTYPE",0,10}, Value = {TechSpeed_R=3000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_49",},
	[BUFF_50] = { ID = BUFF_50, Class = 1, Cond = {"BTYPE",0,10}, Value = {TechSpeed_R=4000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_50",},
	[BUFF_51] = { ID = BUFF_51, Class = 1, Cond = {"BTYPE",0,10}, Value = {TechSpeed_R=5000}, Group = 0, Mutex = 0, Lv = 0, Introduce = "Buff_51",},
}
