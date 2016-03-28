--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_arm = {

	[ARM_BU_1] = { ID = ARM_BU_1, Mode = 1, Lv = 1, Atk = 10, Def = 7, Imm = 0.2, Hp = 204, Speed = 11, BuildSpeed = 1, Weight = 9, Cons = {{1,1,60}}, Consume = 0.208, Pow = 1, TrainTime = 20,},
	[ARM_BU_2] = { ID = ARM_BU_2, Mode = 1, Lv = 2, Atk = 14, Def = 10, Imm = 0.2, Hp = 286, Speed = 11, BuildSpeed = 2, Weight = 9, Cons = {{1,1,100}}, Consume = 0.416, Pow = 1.4, TrainTime = 24,},
	[ARM_BU_3] = { ID = ARM_BU_3, Mode = 1, Lv = 3, Atk = 19, Def = 13, Imm = 0.2, Hp = 388, Speed = 11, BuildSpeed = 3, Weight = 9, Cons = {{1,1,120},{1,2,30}}, Consume = 0.624, Pow = 1.9, TrainTime = 32,},
	[ARM_BU_4] = { ID = ARM_BU_4, Mode = 1, Lv = 4, Atk = 25, Def = 18, Imm = 0.2, Hp = 510, Speed = 11, BuildSpeed = 4, Weight = 10, Cons = {{1,1,168},{1,3,9}}, Consume = 0.832, Pow = 2.5, TrainTime = 42,},
	[ARM_BU_5] = { ID = ARM_BU_5, Mode = 1, Lv = 5, Atk = 32, Def = 22, Imm = 0.2, Hp = 653, Speed = 11, BuildSpeed = 5, Weight = 10, Cons = {{1,1,170},{1,2,57},{1,3,11}}, Consume = 1.04, Pow = 3.2, TrainTime = 56,},
	[ARM_BU_6] = { ID = ARM_BU_6, Mode = 1, Lv = 6, Atk = 40, Def = 28, Imm = 0.2, Hp = 816, Speed = 11, BuildSpeed = 6, Weight = 10, Cons = {{1,1,144},{1,2,36},{1,3,22},{1,4,4}}, Consume = 1.248, Pow = 4, TrainTime = 72,},
	[ARM_BU_7] = { ID = ARM_BU_7, Mode = 1, Lv = 7, Atk = 49, Def = 34, Imm = 0.2, Hp = 1000, Speed = 11, BuildSpeed = 7, Weight = 11, Cons = {{1,1,173},{1,2,43},{1,3,28},{1,4,5}}, Consume = 1.456, Pow = 4.9, TrainTime = 90,},
	[ARM_BU_8] = { ID = ARM_BU_8, Mode = 1, Lv = 8, Atk = 59, Def = 41, Imm = 0.2, Hp = 1204, Speed = 11, BuildSpeed = 8, Weight = 11, Cons = {{1,1,210},{1,2,52},{1,3,34},{1,4,6}}, Consume = 1.664, Pow = 5.9, TrainTime = 110,},
	[ARM_BU_9] = { ID = ARM_BU_9, Mode = 1, Lv = 9, Atk = 70, Def = 49, Imm = 0.2, Hp = 1428, Speed = 11, BuildSpeed = 9, Weight = 12, Cons = {{1,1,254},{1,2,64},{1,3,40},{1,4,8}}, Consume = 1.872, Pow = 7, TrainTime = 132,},
	[ARM_BU_10] = { ID = ARM_BU_10, Mode = 1, Lv = 10, Atk = 82, Def = 57, Imm = 0.2, Hp = 1673, Speed = 11, BuildSpeed = 10, Weight = 12, Cons = {{1,1,302},{1,2,76},{1,3,47},{1,4,9}}, Consume = 2.08, Pow = 8.2, TrainTime = 156,},
	[ARM_QI_1] = { ID = ARM_QI_1, Mode = 2, Lv = 1, Atk = 10, Def = 7, Imm = 0.2, Hp = 204, Speed = 15, BuildSpeed = 1, Weight = 6, Cons = {{1,1,60}}, Consume = 0.208, Pow = 1, TrainTime = 20,},
	[ARM_QI_2] = { ID = ARM_QI_2, Mode = 2, Lv = 2, Atk = 14, Def = 10, Imm = 0.2, Hp = 286, Speed = 15, BuildSpeed = 2, Weight = 6, Cons = {{1,1,100}}, Consume = 0.416, Pow = 1.4, TrainTime = 24,},
	[ARM_QI_3] = { ID = ARM_QI_3, Mode = 2, Lv = 3, Atk = 19, Def = 13, Imm = 0.2, Hp = 388, Speed = 15, BuildSpeed = 3, Weight = 6, Cons = {{1,1,150}}, Consume = 0.624, Pow = 1.9, TrainTime = 32,},
	[ARM_QI_4] = { ID = ARM_QI_4, Mode = 2, Lv = 4, Atk = 25, Def = 18, Imm = 0.2, Hp = 510, Speed = 15, BuildSpeed = 4, Weight = 7, Cons = {{1,1,165},{1,2,21},{1,3,24}}, Consume = 0.832, Pow = 2.5, TrainTime = 42,},
	[ARM_QI_5] = { ID = ARM_QI_5, Mode = 2, Lv = 5, Atk = 32, Def = 22, Imm = 0.2, Hp = 653, Speed = 15, BuildSpeed = 5, Weight = 7, Cons = {{1,1,222},{1,2,28},{1,3,30}}, Consume = 1.04, Pow = 3.2, TrainTime = 56,},
	[ARM_QI_6] = { ID = ARM_QI_6, Mode = 2, Lv = 6, Atk = 40, Def = 28, Imm = 0.2, Hp = 816, Speed = 15, BuildSpeed = 6, Weight = 7, Cons = {{1,1,203},{1,2,37},{1,3,72},{1,4,3}}, Consume = 1.248, Pow = 4, TrainTime = 72,},
	[ARM_QI_7] = { ID = ARM_QI_7, Mode = 2, Lv = 7, Atk = 49, Def = 34, Imm = 0.2, Hp = 1000, Speed = 15, BuildSpeed = 7, Weight = 8, Cons = {{1,1,244},{1,2,44},{1,3,90},{1,4,4}}, Consume = 1.456, Pow = 4.9, TrainTime = 90,},
	[ARM_QI_8] = { ID = ARM_QI_8, Mode = 2, Lv = 8, Atk = 59, Def = 41, Imm = 0.2, Hp = 1204, Speed = 15, BuildSpeed = 8, Weight = 8, Cons = {{1,1,313},{1,2,57},{1,3,108},{1,4,4}}, Consume = 1.664, Pow = 5.9, TrainTime = 110,},
	[ARM_QI_9] = { ID = ARM_QI_9, Mode = 2, Lv = 9, Atk = 70, Def = 49, Imm = 0.2, Hp = 1428, Speed = 15, BuildSpeed = 9, Weight = 9, Cons = {{1,1,366},{1,2,66},{1,3,132},{1,4,5}}, Consume = 1.872, Pow = 7, TrainTime = 132,},
	[ARM_QI_10] = { ID = ARM_QI_10, Mode = 2, Lv = 10, Atk = 82, Def = 57, Imm = 0.2, Hp = 1673, Speed = 15, BuildSpeed = 10, Weight = 9, Cons = {{1,1,426},{1,2,78},{1,3,156},{1,4,6}}, Consume = 2.08, Pow = 8.2, TrainTime = 156,},
	[ARM_GONG_1] = { ID = ARM_GONG_1, Mode = 3, Lv = 1, Atk = 10, Def = 7, Imm = 0.2, Hp = 204, Speed = 10, BuildSpeed = 1, Weight = 8, Cons = {{1,1,60}}, Consume = 0.208, Pow = 1, TrainTime = 20,},
	[ARM_GONG_2] = { ID = ARM_GONG_2, Mode = 3, Lv = 2, Atk = 14, Def = 10, Imm = 0.2, Hp = 286, Speed = 10, BuildSpeed = 2, Weight = 8, Cons = {{1,1,90},{1,2,10}}, Consume = 0.416, Pow = 1.4, TrainTime = 24,},
	[ARM_GONG_3] = { ID = ARM_GONG_3, Mode = 3, Lv = 3, Atk = 19, Def = 13, Imm = 0.2, Hp = 388, Speed = 10, BuildSpeed = 3, Weight = 8, Cons = {{1,1,135},{1,2,15}}, Consume = 0.624, Pow = 1.9, TrainTime = 32,},
	[ARM_GONG_4] = { ID = ARM_GONG_4, Mode = 3, Lv = 4, Atk = 25, Def = 18, Imm = 0.2, Hp = 510, Speed = 10, BuildSpeed = 4, Weight = 9, Cons = {{1,1,177},{1,2,21},{1,3,12}}, Consume = 0.832, Pow = 2.5, TrainTime = 42,},
	[ARM_GONG_5] = { ID = ARM_GONG_5, Mode = 3, Lv = 5, Atk = 32, Def = 22, Imm = 0.2, Hp = 653, Speed = 10, BuildSpeed = 5, Weight = 9, Cons = {{1,1,240},{1,2,28},{1,3,12}}, Consume = 1.04, Pow = 3.2, TrainTime = 56,},
	[ARM_GONG_6] = { ID = ARM_GONG_6, Mode = 3, Lv = 6, Atk = 40, Def = 28, Imm = 0.2, Hp = 816, Speed = 10, BuildSpeed = 6, Weight = 9, Cons = {{1,1,221},{1,2,37},{1,3,54},{1,4,3}}, Consume = 1.248, Pow = 4, TrainTime = 72,},
	[ARM_GONG_7] = { ID = ARM_GONG_7, Mode = 3, Lv = 7, Atk = 49, Def = 34, Imm = 0.2, Hp = 1000, Speed = 10, BuildSpeed = 7, Weight = 10, Cons = {{1,1,267},{1,2,45},{1,3,66},{1,4,4}}, Consume = 1.456, Pow = 4.9, TrainTime = 90,},
	[ARM_GONG_8] = { ID = ARM_GONG_8, Mode = 3, Lv = 8, Atk = 59, Def = 41, Imm = 0.2, Hp = 1204, Speed = 10, BuildSpeed = 8, Weight = 10, Cons = {{1,1,338},{1,2,56},{1,3,84},{1,4,4}}, Consume = 1.664, Pow = 5.9, TrainTime = 110,},
	[ARM_GONG_9] = { ID = ARM_GONG_9, Mode = 3, Lv = 9, Atk = 70, Def = 49, Imm = 0.2, Hp = 1428, Speed = 10, BuildSpeed = 9, Weight = 11, Cons = {{1,1,396},{1,2,66},{1,3,102},{1,4,5}}, Consume = 1.872, Pow = 7, TrainTime = 132,},
	[ARM_GONG_10] = { ID = ARM_GONG_10, Mode = 3, Lv = 10, Atk = 82, Def = 57, Imm = 0.2, Hp = 1673, Speed = 10, BuildSpeed = 10, Weight = 11, Cons = {{1,1,463},{1,2,77},{1,3,120},{1,4,6}}, Consume = 2.08, Pow = 8.2, TrainTime = 156,},
	[ARM_CHE_1] = { ID = ARM_CHE_1, Mode = 4, Lv = 1, Atk = 10, Def = 7, Imm = 0.2, Hp = 204, Speed = 7, BuildSpeed = 1, Weight = 22, Cons = {{1,1,36},{1,2,24}}, Consume = 0.208, Pow = 1, TrainTime = 20,},
	[ARM_CHE_2] = { ID = ARM_CHE_2, Mode = 4, Lv = 2, Atk = 14, Def = 10, Imm = 0.2, Hp = 286, Speed = 7, BuildSpeed = 2, Weight = 22, Cons = {{1,1,60},{1,2,40}}, Consume = 0.416, Pow = 1.4, TrainTime = 24,},
	[ARM_CHE_3] = { ID = ARM_CHE_3, Mode = 4, Lv = 3, Atk = 19, Def = 13, Imm = 0.2, Hp = 388, Speed = 7, BuildSpeed = 3, Weight = 22, Cons = {{1,1,90},{1,2,60}}, Consume = 0.624, Pow = 1.9, TrainTime = 32,},
	[ARM_CHE_4] = { ID = ARM_CHE_4, Mode = 4, Lv = 4, Atk = 25, Def = 18, Imm = 0.2, Hp = 510, Speed = 7, BuildSpeed = 4, Weight = 23, Cons = {{1,1,103},{1,2,83},{1,3,24}}, Consume = 0.832, Pow = 2.5, TrainTime = 42,},
	[ARM_CHE_5] = { ID = ARM_CHE_5, Mode = 4, Lv = 5, Atk = 32, Def = 22, Imm = 0.2, Hp = 653, Speed = 7, BuildSpeed = 5, Weight = 23, Cons = {{1,1,139},{1,2,111},{1,3,30}}, Consume = 1.04, Pow = 3.2, TrainTime = 56,},
	[ARM_CHE_6] = { ID = ARM_CHE_6, Mode = 4, Lv = 6, Atk = 40, Def = 28, Imm = 0.2, Hp = 816, Speed = 7, BuildSpeed = 6, Weight = 23, Cons = {{1,1,159},{1,2,141},{1,3,36},{1,4,2}}, Consume = 1.248, Pow = 4, TrainTime = 72,},
	[ARM_CHE_7] = { ID = ARM_CHE_7, Mode = 4, Lv = 7, Atk = 49, Def = 34, Imm = 0.2, Hp = 1000, Speed = 7, BuildSpeed = 7, Weight = 24, Cons = {{1,1,200},{1,2,178},{1,3,48},{1,4,2}}, Consume = 1.456, Pow = 4.9, TrainTime = 90,},
	[ARM_CHE_8] = { ID = ARM_CHE_8, Mode = 4, Lv = 8, Atk = 59, Def = 41, Imm = 0.2, Hp = 1204, Speed = 7, BuildSpeed = 8, Weight = 24, Cons = {{1,1,250},{1,2,222},{1,3,54},{1,4,2}}, Consume = 1.664, Pow = 5.9, TrainTime = 110,},
	[ARM_CHE_9] = { ID = ARM_CHE_9, Mode = 4, Lv = 9, Atk = 70, Def = 49, Imm = 0.2, Hp = 1428, Speed = 7, BuildSpeed = 9, Weight = 25, Cons = {{1,1,302},{1,2,268},{1,3,66},{1,4,2}}, Consume = 1.872, Pow = 7, TrainTime = 132,},
	[ARM_CHE_10] = { ID = ARM_CHE_10, Mode = 4, Lv = 10, Atk = 82, Def = 57, Imm = 0.2, Hp = 1673, Speed = 7, BuildSpeed = 10, Weight = 25, Cons = {{1,1,346},{1,2,308},{1,3,78},{1,4,3}}, Consume = 2.08, Pow = 8.2, TrainTime = 156,},
}
