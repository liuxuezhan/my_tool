--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_resource = {

	[DEF_RES_FOOD] = { ID = DEF_RES_FOOD, CodeKey = "food", Name = ITEM_RES_NAME_1, Mul = 1, Open = 1, Desc = ITEM_RES_DESC_1,},
	[DEF_RES_WOOD] = { ID = DEF_RES_WOOD, CodeKey = "wood", Name = ITEM_RES_NAME_2, Mul = 1, Open = 1, Desc = ITEM_RES_DESC_2,},
	[DEF_RES_IRON] = { ID = DEF_RES_IRON, CodeKey = "iron", Name = ITEM_RES_NAME_3, Mul = 5, Open = 10, Desc = ITEM_RES_DESC_3,},
	[DEF_RES_ENERGY] = { ID = DEF_RES_ENERGY, CodeKey = "energy", Name = ITEM_RES_NAME_4, Mul = 20, Open = 15, Desc = ITEM_RES_DESC_4,},
	[DEF_RES_STEEL] = { ID = DEF_RES_STEEL, CodeKey = "steel", Name = ITEM_RES_NAME_5, Mul = nil, Open = nil, Desc = ITEM_RES_DESC_5,},
	[DEF_RES_GOLD] = { ID = DEF_RES_GOLD, CodeKey = "gold", Name = ITEM_RES_NAME_6, Mul = nil, Open = nil, Desc = ITEM_RES_DESC_6,},
	[DEF_RES_RMB] = { ID = DEF_RES_RMB, CodeKey = "rmb", Name = ITEM_RES_NAME_7, Mul = nil, Open = nil, Desc = ITEM_RES_DESC_7,},
}
