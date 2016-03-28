--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_genius = {

	[GENIUS_1001001] = { ID = GENIUS_1001001, Class = 1, Mode = 1, Lv = 1, Cond = nil, Effect = nil, Name = "天赋名1", Desc = "天赋描述1",},
	[GENIUS_1001002] = { ID = GENIUS_1001002, Class = 1, Mode = 1, Lv = 2, Cond = nil, Effect = nil, Name = "天赋名2", Desc = "天赋描述2",},
	[GENIUS_1002001] = { ID = GENIUS_1002001, Class = 1, Mode = 2, Lv = 1, Cond = nil, Effect = nil, Name = "天赋名3", Desc = "天赋描述3",},
	[GENIUS_1002002] = { ID = GENIUS_1002002, Class = 1, Mode = 2, Lv = 2, Cond = nil, Effect = nil, Name = "天赋名4", Desc = "天赋描述4",},
	[GENIUS_1003001] = { ID = GENIUS_1003001, Class = 1, Mode = 3, Lv = 1, Cond = {{4,1001001},{4,1002001}}, Effect = nil, Name = "天赋名5", Desc = "天赋描述5",},
	[GENIUS_1003002] = { ID = GENIUS_1003002, Class = 1, Mode = 3, Lv = 2, Cond = nil, Effect = nil, Name = "天赋名6", Desc = "天赋描述6",},
	[GENIUS_2001001] = { ID = GENIUS_2001001, Class = 2, Mode = 1, Lv = 1, Cond = nil, Effect = nil, Name = "天赋名7", Desc = "天赋描述7",},
	[GENIUS_2001002] = { ID = GENIUS_2001002, Class = 2, Mode = 1, Lv = 2, Cond = nil, Effect = nil, Name = "天赋名8", Desc = "天赋描述8",},
}
