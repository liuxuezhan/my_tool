--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_task_detail = {

	[TASK_DAILY_1] = { ID = TASK_DAILY_1, TaskType = 1, PreTask = 0, PreCondition = {1,1}, Bonus = {"item",10006,10}, FinishCondition = {"attack_special_monster",2,3,0},},
	[TASK_TRUNK_1] = { ID = TASK_TRUNK_1, TaskType = 2, PreTask = 0, PreCondition = {1,1}, Bonus = {"item",10006,11}, FinishCondition = {"attack_special_monster",2,3,1},},
	[TASK_BRANCH_1] = { ID = TASK_BRANCH_1, TaskType = 3, PreTask = 0, PreCondition = {1,1}, Bonus = {"item",10006,12}, FinishCondition = {"attack_special_monster",2,3,2},},
	[TASK_UNION_1] = { ID = TASK_UNION_1, TaskType = 4, PreTask = 0, PreCondition = {1,1}, Bonus = {"item",10006,13}, FinishCondition = {"attack_special_monster",2,3,3},},
}
