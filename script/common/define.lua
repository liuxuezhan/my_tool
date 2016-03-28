--------------------------------------------------------------------------------

-- 数值变化原因
VALUE_CHANGE_REASON = {
    -- [0, 9] Don't use these value.
    DEFAULT = 0,
    DEBUG   = 1,

    -- [10, 19] Item
    USE_ITEM   = 10,
    FETCH_MAIL = 11,
    COMPOSE = 12,
    DECOMPOSE = 13,
    FORGE = 14,
    SPLIT = 15,
    

    -- [20, 29] Build
    BUILD_CONSTRUCT = 20,
    BUILD_UPGRADE   = 21,
    BUILD_ACC       = 22,
    LEARN_TECH      = 23,

    -- [30, 39] Hero
    HERO_CREATE       = 30,
    HERO_SATR_UP      = 31,
    HERO_LV_UP        = 32,
    RESET_SKILL       = 33,
    CONVERT_HERO_CARD = 34,
    DESTROY_HERO      = 35,
    CURE_HERO         = 36,
    CANCEL_CURE_HERO  = 37,
    RELIVE_HERO       = 38,

    -- [40, 49] Union
    UNION_CREATE = 40,
    UNION_DONATE = 41,
    UNION_RESTORE = 42,

    -- [50, 79] Play
    GATHER = 50,
    REAP   = 51,
    TRAIN  = 52,
    JUNGLE = 53,
}

resmng.CLASS_RES = 1			--物品类型1资源
resmng.CLASS_BUILD = 2			--物品类型2建筑
resmng.CLASS_ARM = 3			--物品类型3军队
resmng.CLASS_GENIUS = 4			--物品类型4天赋
resmng.CLASS_TECH = 5			--物品类型5科技
resmng.CLASS_ITEM = 6			--物品类型6道具
resmng.CLASS_COUNT = 7			--操作类型7达成次数
resmng.CLASS_UNION_TECH = 8     --物品类型8军团科技
resmng.CLASS_UNION_BUILDLV = 9  --物品类型9军团建筑等级

resmng.ITEM_CLASS_ACC = 3


resmng.MATERIAL_COMPOSE_COUNT = 3

ROI_MSG = {
    NTY_NO_RES  = 13, 
    TRIGGERS_ENTER = 21,
    TRIGGERS_LEAVE = 22,
    TRIGGERS_ARRIVE = 23,
    ADD_SCAN = 24,
    REM_SCAN = 25,
    ADD_ACTOR = 26,
    REM_ACTOR = 27,
    UPD_ACTOR = 28,
}

--resmng.CLASS_UNION_BUILD_
--
CLASS_UNIT = {
    UNION_BUILD = 10,
    PLAYER_CITY = 0,
    RESOURCE = 1,
    MONSTER = 2,
    NPC_CITY = 3,
}

-- Hx@2015-12-02 : mail
--


MailMode = {}
MailMode.Sys = 1
MailMode.AlncInvite = 2

MAIL_CLASS = {
    PLAYER = 1,  -- 玩家
    FIGHT = 2,  -- 战斗
    SYSTEM = 3,  -- 系统
    REPORT = 4,  -- 报告
}
MAIL_FIGHT_MODE = {
    SPY = 1,  -- 侦查
    BE_SPY = 2,  -- 被侦查

    ATTACK_SUCCESS = 3,  -- 进攻成功
    ATTACK_FAIL = 4,  -- 进攻失败
    DEFEND_SUCCESS = 5,  -- 防守成功
    DEFEND_FAIL = 6,  -- 防守失败

    MASS_SUCCESS = 7,  -- 集结成功
    MASS_FAIL = 8,  -- 集结失败
    DEFEND_MASS_SUCCESS = 9,  -- 防守集结成功
    DEFEND_MASS_FAIL = 10,  -- 防守集结失败
}
MAIL_REPORT_MODE = {
    GATHER = 1,  -- 采集
    JUNGLE = 2,  -- 打怪
}

-- Zhao@2015年12月3日 ：Language
language_def = {
	[40] = {text = "中文(简体)",icon = "icon_language_cn"},
	[41] = {text = "繁體中文",icon = "icon_language_cn"},
	[10] = {text = "English",icon = "icon_language_en"},
	[22] = {text = "日 本 語",icon = "icon_language_jpn"},
	[15] = {text = "Deutsch",icon = "icon_language_de"},		-- 德语
	[14] = {text = "Français",icon = "icon_language_fra"},			-- 法语
	[36] = {text = "ภาษาไทย",icon = "icon_language_th"}			-- 泰语
}

-- Hx@2015-12-04 : union state in player eye
UNION_STATE = {
    NONE = 0,
    APPLYING = 1,
    IN_UNION = 2,
    ENEMY = 3,
}

-- Hx@2015-12-08 :
UNION_MASS_STATE = {
    CREATE = 0,
    UPDATE = 1,
    DESTORY = 2,
    FINISH = 3,
}

TroopAction = {
    Gather = 1,     --采集
    Seige = 2,      --打架
    Mass = 3,       --发起集结
    Mass_node = 4,  --参与集结
    Spy = 5,        --侦查
    Res_go = 6,     --运送资源
    Res_back = 7,   --取回资源
    Aid = 8,        --支援
    Station = 9,    --驻守帐篷
    Defend = 10,     --驻守城防临时部队
    Hold = 11,     --驻守其他建筑
    Build = 12,     --修建建筑
    PRISON_BACK_HOME = 13, -- 俘虏回家
    Buy = 14,   --买特产 
    Sell = 15,  -- 上架特产
    UnSell = 16,  -- 下架特产
}


TroopState = {
    Go = 1,     --出发
    Wait = 2,   --等待触发下一个事件
    Back = 3,   --回来
    Arrive = 4, --等待(无下一个状态)
    Gather = 5, --采集(无下一个状态)
    Fight = 6,  --战斗中
    Build = 7,  --建造中
}

BigMapState = {
    normal = 1,
    war = 2,
}

EidType = {
    Player = 0,
    Res = 1,
    Troop = 2,
    Monster = 3,
    UnionBuild = 4,
    NpcCity = 5,
}

--聊天频道枚举
ChatChanelEnum = {
    World = 0,        --世界
    Union = 1,        --军团
    Culture = 2,      --文明
}

TECH_DONATE_TYPE = {
    PRIMARY = 1,    --初级
    MEDIUM = 2,     --中级
    SENIOR = 3,     --高级
}

DONATE_RANKING_TYPE = {
    DAY = 1,
    WEEK = 2,
    UNION = 3,
    ALL = 4,
}

TechValidCond = {0,10,20,30,40}


--------------------------------------------------------------------------------
-- Build begin.
-- TODO: 把这里的 CLASS MODE NUM 改成配置

BUILD_CLASS = {
    FUNCTION = 0,     -- 功能建筑
    RESOURCE = 1,     -- 资源田(农田、伐木场、铁矿厂、能源石)
    ARMY     = 2,     -- 造兵建筑
    UNION    = 10,    -- 军团建筑
}

BUILD_FUNCTION_MODE = {
    CASTLE          = 0,     -- 城堡
    ALTAR           = 1,     -- 祭坛
    WALLS           = 2,     -- 城墙
    DAILYQUEST      = 3,     -- 行宫
    STOREHOUSE      = 4,     -- 仓库
    MARKET          = 5,     -- 市场
    BLACKMARKET     = 6,     -- 黑市
    RESOURCESMARKET = 7,     -- 物资市场
    PRISON          = 8,     -- 监狱
    FORGE           = 9,     -- 铁匠铺
    ACADEMY         = 10,    -- 研究院
    HALLOFHERO      = 11,    -- 英雄大厅
    EMBASSY         = 12,    -- 大使馆
    HALLOFWAR       = 13,    -- 战争大厅
    WATCHTOWER      = 14,    -- 瞭望塔
    TUTTER_LEFT     = 15,    -- 箭塔
    HELP            = 16,    -- 公告牌
    DRILLGROUNDS    = 17,    -- 校场
    MILITARYTENT    = 18,    -- 训练营
    HOSPITAL        = 19,    -- 医疗所
    TUTTER_RIGHT    = 20,    -- 箭塔
}

BUILD_RESOURCE_MODE = {
    FARM        = 1,  -- 农田
    LOGGINGCAMP = 2,  -- 伐木场
    MINE        = 3,  -- 铁矿厂
    QUARRY      = 4,  -- 能源石
}

BUILD_ARMY_MODE = {
    BARRACKS = 1,  -- 兵营
    STABLES  = 2,  -- 马厩
    RANGE    = 3,  -- 靶场
    FACTORY  = 4,  -- 工坊
}

--BUILD_UNION_MODE
resmng.CLASS_UNION_BUILD_CASTLE = 1         --奇迹
resmng.CLASS_UNION_BUILD_MINI_CASTLE = 2    --小奇迹
resmng.CLASS_UNION_BUILD_MARKET = 3        --市场
resmng.CLASS_UNION_BUILD_RESTORE = 4        --仓库
resmng.CLASS_UNION_BUILD_TUTTER1 = 5         --箭塔1
resmng.CLASS_UNION_BUILD_TUTTER2 = 6         --箭塔2
resmng.CLASS_UNION_BUILD_FARM = 7           --农田
resmng.CLASS_UNION_BUILD_LOGGINGCAMP = 8    --木厂
resmng.CLASS_UNION_BUILD_MINE = 9           --铁矿厂
resmng.CLASS_UNION_BUILD_QUARRY = 10         --能源石

-- 建筑数量上限
BUILD_MAX_NUM = {
    [BUILD_CLASS.FUNCTION] = {
        [BUILD_FUNCTION_MODE.CASTLE]          = 1,  -- 城堡
        [BUILD_FUNCTION_MODE.ALTAR]           = 1,  -- 祭坛
        [BUILD_FUNCTION_MODE.WALLS]           = 1,  -- 城墙
        [BUILD_FUNCTION_MODE.DAILYQUEST]      = 1,  -- 行宫
        [BUILD_FUNCTION_MODE.STOREHOUSE]      = 1,  -- 仓库
        [BUILD_FUNCTION_MODE.MARKET]          = 1,  -- 市场
        [BUILD_FUNCTION_MODE.BLACKMARKET]     = 1,  -- 黑市
        [BUILD_FUNCTION_MODE.RESOURCESMARKET] = 1,  -- 物资市场
        [BUILD_FUNCTION_MODE.PRISON]          = 1,  -- 监狱
        [BUILD_FUNCTION_MODE.FORGE]           = 1,  -- 铁匠铺
        [BUILD_FUNCTION_MODE.ACADEMY]         = 1,  -- 研究院
        [BUILD_FUNCTION_MODE.HALLOFHERO]      = 1,  -- 英雄大厅
        [BUILD_FUNCTION_MODE.EMBASSY]         = 1,  -- 大使馆
        [BUILD_FUNCTION_MODE.HALLOFWAR]       = 1,  -- 战争大厅
        [BUILD_FUNCTION_MODE.WATCHTOWER]      = 1,  -- 瞭望塔
        [BUILD_FUNCTION_MODE.TUTTER_LEFT]     = 1,  -- 箭塔
        [BUILD_FUNCTION_MODE.TUTTER_RIGHT]    = 1,  -- 箭塔
        [BUILD_FUNCTION_MODE.HELP]            = 1,  -- 公告牌
        [BUILD_FUNCTION_MODE.DRILLGROUNDS]    = 1,  -- 校场
        [BUILD_FUNCTION_MODE.MILITARYTENT]    = 8,  -- 训练营
        [BUILD_FUNCTION_MODE.HOSPITAL]        = 8,  -- 医疗所
    },
    [BUILD_CLASS.RESOURCE] = {
        [BUILD_RESOURCE_MODE.FARM]        = 8,  -- 农田
        [BUILD_RESOURCE_MODE.LOGGINGCAMP] = 8,  -- 伐木场
        [BUILD_RESOURCE_MODE.MINE]        = 8,  -- 铁矿厂
        [BUILD_RESOURCE_MODE.QUARRY]      = 8,  -- 能源石
    },
    [BUILD_CLASS.ARMY] = {
        [BUILD_ARMY_MODE.BARRACKS] = 1,  -- 兵营
        [BUILD_ARMY_MODE.STABLES]  = 1,  -- 马厩
        [BUILD_ARMY_MODE.RANGE]    = 1,  -- 靶场
        [BUILD_ARMY_MODE.FACTORY]  = 1,  -- 工坊
    },
}

-- 建筑状态
BUILD_STATE = {
    DESTROY = 0,   -- 被拆除
    CREATE  = 1,   -- 修建
    WAIT    = 2,   -- 待机状态
    WORK    = 3,   -- 生效中/训练中/治疗中/科技研究/锻造
    UPGRADE = 4,   -- 升级中
}

-- Build end.
--------------------------------------------------------------------------------


-- Hx@2016-01-04 : 数据操作类型
OPERATOR = {
    ADD = 1,        --增
    UPDATE = 2,     --改
    DELETE = 3,     --删
}

-- 加速方式
ACC_TYPE = {
    FREE = 1,
    GOLD = 2,
    ITEM = 3,
}

-- 道具class种类
ITEM_CLASS = {
    RES   = 1,  -- 资源
    BOX   = 2,  -- 箱子
    SPEED = 3,  -- 加速道具
    HERO  = 4,  -- 英雄道具
    SKILL = 5,  -- 技能道具
    MATERIAL = 6, -- 资源
}

-- 加速MODE分类
ITEM_SPEED_MODE = {
    COMMON = 0,    -- 通用加速
    LV_UP  = 1,    -- 升级加速
    TRAIN  = 2,    -- 造兵加速
    CURE   = 3,    -- 治疗加速
}

-- 英雄道具
ITEM_HERO_MODE = {
    HERO_CARD           = 1,  -- 英雄卡
    PIECE               = 2,  -- 英雄碎片
    EXP_BOOK            = 3,  -- 英雄经验书
    RESET_NAME          = 4,  -- 改名卡
    RESET_PERSONALITY   = 5,  -- 重置个性
}

-- 技能道具
ITEM_SKILL_MODE = {
    SPECIAL_BOOK = 1,  -- 特定技能书
    COMMON_BOOK  = 2,  -- 通用技能书
    RESET_BOOK   = 3,  -- 重置技能书
}

-- Hx@2015-12-28 : 事件类型
EVENT_TYPE = {
    UNION_CREATE = 1,
    UNION_DESTORY = 2,
    UNION_JOIN = 3,
    UNION_QUIT = 4,
    UNION_KICK = 5,
    SET_NOTE_IN = 6,
    FIGHT = 10,
}

-- Hx@2016-01-08 : effect类型，配置表使用,此枚举用于检查唯一性
-- 1.数值类使用此定义
-- 2.因子类使用 xxRate
EFFECT_TYPE = {
    MaxSoldier = true,
    TrainCount = true,
    TrainSpeed = true,
    FoodUse = true,
    FoodSpeed = true,
    FoodCount = true,
    WoodSpeed = true,
    GatherSpeed = true,
    TroopExtra = true,

    FoodSpeedR   = true,
    WoodSpeedR   = true,
    IronSpeedR   = true,
    EnergySpeedR = true,
    TrainSpeedR  = true,
    CureSpeedR   = true,
    LearnSpeedR  = true,

     Atk_R = true,
    Atk1_R = true,
    Atk2_R = true,
    Atk3_R = true,
    Atk4_R = true,

    AAtk1_R = true,
    AAtk2_R = true,
    AAtk3_R = true,
    AAtk4_R = true,

     Def_R = true,
    Def1_R = true,
    Def2_R = true,
    Def3_R = true,
    Def4_R = true,

    Imm = true,
    Imm1 = true,
    Imm2 = true,
    Imm3 = true,
    Imm4 = true,

     Imm_R = true,
    Imm1_R = true,
    Imm2_R = true,
    Imm3_R = true,
    Imm4_R = true,

    DImm1_R = true,
    DImm2_R = true,
    DImm3_R = true,
    DImm4_R = true,
}

-- -----------------------------------------------------------------------------
-- Hx@2016-01-26 : 行军速度倍率
-- -----------------------------------------------------------------------------
TROOP_STDSPEED = 10


-- Hx@2015-12-03 : ErrorCode
E_OK = 0
E_FAIL = 1

-- judge
E_DISALLOWED = 2
E_TIMEOUT = 3
E_ALREADY_IN_UNION = 101

-- lack of something
E_NO_TROOP = 1001
E_NO_MASS = 1002
E_NO_PLAYER = 1003
E_NO_UNION = 1004
E_NO_ENEMY = 1005
E_NO_CONF = 1006
E_NO_RMB = 1007
E_NOT_ENOUGH_SOLDIER = 1008
E_NO_HERO = 1009
E_NO_SOLDIER = 1010
E_HERO_BUSY = 1011
E_NO_REPORT = 1012
E_NO_ROOM = 1013
E_TROOP_BUSY = 1014
E_DUP_NAME = 1015


-- overflow
E_MAX_LV = 2001
E_TOO_MUCH_SOLDIER = 2002

--------------------------------------------------------------------------------
-- Hero Begin.   YC@2015-12-30
-- 属性
HERO_ATTR_TYPE = {
    ATTACK  = 1,    -- 攻击
    DEFENSE = 2,    -- 防御
    TANK    = 3,    -- 生命
    ALL     = 4,    -- 全能
}

-- 天性
HERO_NATURE_TYPE = {
    STRICT   = 1,    -- 严谨
    FEARLESS = 2,    -- 无谓
    CALM     = 3,    -- 冷静
    BOLD     = 4,    -- 豪放
}

-- 文明
HERO_CULTURE_TYPE = {
    CHINA  = 1,    -- 华夏
    EUROPE = 2,    -- 欧洲
    ARAB   = 3,    -- 阿拉伯
    SLAVIC = 4,    -- 斯拉夫
}

-- 状态
HERO_STATUS_TYPE = {
    FREE             = 1,    -- 待机
    MOVING           = 2,    -- 行军中
    DEFENDING        = 3,    -- 驻守中
    BUILDING         = 4,    -- 城建中
    GATHER           = 5,    -- 采集中
    BEING_CURED      = 6,    -- 治疗中
    BEING_CAPTURED   = 7,    -- 被俘虏
    BEING_IMPRISONED = 8,    -- 被监禁
    BEING_EXECUTED   = 9,    -- 处决中
    DEAD             = 10,   -- 死亡
}

-- 品质
HERO_QUALITY_TYPE = {
    ORDINARY  = 1,    -- 普通
    GOOD      = 2,    -- 优秀
    EXCELLENT = 3,    -- 精良
    EPIC      = 4,    -- 史诗
    LEGENDARY = 5,    -- 传说
    GODLIKE   = 6,    -- 神级
}

-- 英雄卡折算成碎片时的比例
HERO_CARD_2_PIECE_RATIO = 0.8

-- 重置技能时经验返回比例
RESET_SKILL_RETURN_RATIO = 0.8

-- 分解英雄时的经验值返回比例
DESTROY_HERO_RETURN_RATIO = 0.8

-- 取消治疗时的资源返还比例
CANCEL_CURE_RETURN_RATIO = 0.5

-- 英雄俘虏玩法开启所需的主城等级
CAPTURE_LV_LIMIT = 10

-- 英雄被处死后的复活时限(单位天)
RELIVE_HERO_DAYS_LIMIT = 7

-- 技能 CLASS
SKILL_CLASS = {
    ATTACK  = 1,  --  攻击类技能
    BUILD   = 2,  --  城建类技能
    DEFENSE = 3,  --  防御类技能
    TACTICS = 4,  --  战法类技能
    SPECIAL = 5,  --  特殊类技能
    CONTROL = 6,  --  统御类技能
    TALENT  = 7,  --  特技
}

SKILL_TYPE = {
    FIGHT     = 0,  -- 战斗技能
    NOT_FIGHT = 1,  -- 非战斗技能
}
-- Hero End.
-------------------------------------------------------------------------------------

--任务定义
TASK_TYPE = {
    TASK_TYPE_INVALID       = 0,
    TASK_TYPE_DAILY         = 1,    --日常任务
    TASK_TYPE_TRUNK         = 2,    --主线任务
    TASK_TYPE_BRANCH        = 3,    --支线任务
    TASK_TYPE_UNION         = 4,    --军团任务
}

TASK_STATUS = {
    TASK_STATUS_INVALID             = 0,
    TASK_STATUS_LOCK                = 1,    --未解锁
    TASK_STATUS_CAN_ACCEPT          = 2,    --可以接收
    TASK_STATUS_ACCEPTED            = 3,    --已接收
    TASK_STATUS_CAN_FINISH          = 4,    --可以完成
    TASK_STATUS_FINISHED            = 5,    --已完成
}

TASK_MANAGER_TYPE = {
    INVALID                         = 0,
    ATTACK_SPECIAL_MONSTER          = 1,
}

g_task_func_relation = {}
g_task_func_relation["attack_special_monster"] = TASK_MANAGER_TYPE.ATTACK_SPECIAL_MONSTER

-------------------------------------------------------------
--奖励
BONUS_TYPE = {
    BONUS_TYPE_ITEM         = 1,
    BONUS_TYPE_RES          = 2,
    BONUS_TYPE_EXP          = 3,
    BONUS_TYPE_SOLIDER      = 4,
    BONUS_TYPE_ACTIVE       = 5,
}

-----------------------------------------------------------------
--触发器

RANGE_EVENT_ID = {
    ENTER_RANGE        = 1,    --进入作用范围
    LEAVE_RANGE        = 2,    --离开作用范围
    ARRIVED_TARGET     = 3,    --到达目标
}

TRIGGERS_EVENT_ID = {
    TRIGGERS_BEGIN             = 0,  --起始值
    TRIGGERS_ACK               = 1,  --被攻击
    TRIGGERS_SLOW              = 3, --被减速

    ---------------------------------------------------------
    TRIGGERS_END               = 3,  --终止值（增加一个类型需要递增）
}

--------------------------------------------------------------------------------
-- 日志中是否显示调试信息（文件名、函数名、行号）
SHOW_DEBUG_INFO = false



-- Certify Code
CertifyCode = {
    OK = 0,
    PASS_ERROR = 1,
    BLOCK = 2,
    DUPLICATE = 3,
}

function is_ply(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.Player end
        else
            return (math.floor(ety / 0x010000)) == EidType.Player
        end
    end
end

function is_res(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.Res end
        else
            return (math.floor(ety / 0x010000)) == EidType.Res
        end
    end
end

function is_troop(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.Troop end
        else
            return (math.floor(ety / 0x010000)) == EidType.Troop
        end
    end
end

function is_monster(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.Monster end
        else
            return (math.floor(ety / 0x010000)) == EidType.Monster
        end
    end
end

function is_union_building(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.UnionBuild end
        else
            return (math.floor(ety / 0x010000)) == EidType.UnionBuild
        end
    end
end

function is_npc_city(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.NpcCity end
        else
            return (math.floor(ety / 0x010000)) == EidType.NpcCity
        end
    end
end


function can_attack(ety)
    if is_ply(ety) then return true end
    if is_monster(ety) then return true end
    if is_res(ety) and ety.on then return true end
end


