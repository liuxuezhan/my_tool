module("Protocol")

Server = {
    firstPacket = "int uid, string name, string pasw",
    login = "int pid",
    onBreak = "",
    create_character = "pack info",
    change_name = "string name",

    getTime = "",
    reCalcFood = "",

    debugInput = "string str",

    onQryCross = "int toPid, int sn, int smap, int spid, string cmd, pack arg",
    onAckCross = "int smap, int sn, int code, pack arg",

    hello = "int pid1, int pid2, string text",
    say = "string say, int nouse",
    say1 = "string say, int nouse",

    use_item = "int id, int num",
    material_compose = "int id",
    material_decompose = "int id",

    equip_forge = "int propid",
    equip_split = "int sn",
    equip_on = "int sn",
    equip_off = "int sn",

    --  聊天
    chat = "int chanelid, string word, int chatid",      --chanelId: enum in common/define/ChatChanelEnum;   word:the word you say;     chatid:聊天流水号，服务器会在onError方法中返回
    chat_with_audio = "int chanelid, byte[] stream",      --TODO
    get_user_simple_info = "int pid",     --获取用户简单信息

    get_user_info = "int pid, string what", --查看别的玩家的信息

    testPack = "int i, pack p, string s",
    qryInfo = "int pid",
    loadData = "string what",
    qryAround = "",

	--troop
    get_eye_info = "int eid",--获取地图单位详细信息
    get_room_troop = "int rid,int pid", --获取战争的行军队列数据
    get_eid_troop = "int eid,int pid", --获取建筑的行军队列数据
	troop_go = "int action, pack dp, pack info",--发出行军队列
	--dp 包含 eid or x , y
	--info 包含 res , arms，heros
	troopx_back = "int idx",    --正常召回部队
    troopx_stdtime = "int did", --行军标准时间
    seige = "int dpid, pack troop, pack heros",
    spy = "int did",
    gather = "int dpid, pack troop, pack heros",
	union_mass_create = "int deid, int tm, pack troop, pack heros",   --创建集结
    union_mass_join = "int mid, pack arms, pack heros",               --参与集结
    union_mass_deny = "int mid, int pid",
    union_aid_go = "int pid, pack arms, pack heros",--援助
    union_aid_count = "int pid",
    union_aid_recall = "int pid",


    reap = "int idx",
    train = "int idx, int armid, int num",
    draft = "int idx",

    migrate = "int x, int y",

    --------------------------------------------------------------------------------
    -- build begin
    construct = "int x, int y, int build_propid",
    upgrade = "int idx",
    acc_build = "int build_idx, int acc_type",
    item_acc_build = "int build_idx, int item_idx, int num",
    one_key_upgrade_build = "int build_idx",
    learn_tech = "int build_idx, int tech_id",
    -- build end.
    --------------------------------------------------------------------------------

    --geniusDo = "int id",
    do_genius = "int id",

    -- mail
    --mail_load = "int class, int id, int is_new",
    mail_load = "int idx",
    mail_read_by_sn = "pack sns",
    mail_drop_by_sn = "pack sns",
    mail_fetch_by_sn ="pack sns",
    mail_lock_by_sn = "pack sns",
    mail_unlock_by_sn= "pack sns",

    --mail_unread_count = "",
    -- mail_read = "pack sns",
    -- mail_drop = "pack sns",
    --mail_read_by_class = "int class",
    --mail_drop_by_class = "int class",
    --mail_fetch_by_class = "int class",
    -- mail_send = "int class, int to, string title, string content",
    mail_send_player = "int to_player_id, string title, string content",
    test_mail_all = "int class, string title, string content, pack its",

    -- roi
    addEye = "",
    remEye = "",
    movEye = "int x, int y",

    -- allience
    -- tech = {info={{idx,id,exp,tmOver},{...}},mark={idx,idx}}
    -- donate = {tmOver,flag}
    union_load = "string what",      ---"info","member","apply","mass","aid","tech","donate","fight","build"
    union_create = "string name, string alias, int language, int mars", --创建军团
    union_rm_member = "int pid",        --踢人
    union_add_member = "int pid",       --同意申请
    union_quit = "",                    --主动退出联盟
    union_destory = "",
    union_list = "",
    union_apply = "int uid",
    union_reject = "int pid",            --拒绝申请
    union_invite = "int pid",
    union_set_note_in = "string what",  --设置军团对内公告
    union_accept_invite = "int unionId",

    union_tech_info = "int idx",            --科技详细信息
    union_donate = "int idx, int type",     --科技捐献
    union_tech_upgrade = "int idx",         --科技升级
    union_tech_mark = "pack info",          --设置新的优先标记
    union_log = "int idx, int mode",        --获取联盟日志
    union_donate_rank = "int what",         --捐献排名
    union_member_rank = "int pid, int r",   --设置rank
    union_build_setup = "int idx,int propid, int x, int y",--放置军团建筑
    union_build_upgrade = "int idx",   --军队建筑升级
    union_build_remove = "int idx",     --拆除军团建筑
    union_build_donate = "int class",       --建筑捐献
    --改联盟基本信息 name,alias,language,rank_alias,mars
    --{tag=value, ...}
    union_set_info = "pack info",

    get_room = "int rid", --获取战斗双方数据


    -- just for test
    addArm = "",
    addItem = "int id, int num",
    addRes = "",

    runCommand = "string command",

    -- debug func beign.
    clear_item = "",
    -- debug func end.

    gm_user = "string cmd",
    gm_platform = "string cmd",

    testFight = "int an1, int an2, int an3 int an4, int ah1, int ah2, int ah3, int ah4, int dn1, int dn2, int dn3, int dn4, int dh1, int dh2, int dh3, int dh4",

    query_fight_info = "int eid",

    --------------------------------------------------------------------------------
    -- Hero Begin.    YC@2015-12-30
    get_hero_list_info = "int pid",
    get_hero_detail_info = "string hero_id",

    call_hero_by_piece = "int hero_propid",
    hero_star_up = "int hero_idx",
    hero_lv_up = "int hero_idx, int item_idx, int num",

    use_hero_skill_item = "int hero_idx, int skill_idx, int item_idx, int num",

    -- 派遣
    dispatch_hero = "int build_idx, int hero_idx",

    -- 分解英雄
    destroy_hero = "int hero_idx",

    -- 治疗英雄
    cure_hero = "int hero_idx, int delta_hp",
    cancel_cure_hero = "int hero_idx",

    -- 获取被俘英雄信息
    get_prisoners_info = "",

    -- 释放英雄
    release_prisoner = "string hero_id",

    -- 处死英雄
    kill_hero = "string hero_id, int buff_idx",

    -- 复活英雄
    relive_hero = "int hero_idx",

    -- 指定守城英雄
    set_def_hero = "pack def_heros",
    -- Hero End.
    --------------------------------------------------------------------------------
    get_resm_conf = "",--获取当前物资市场配置
    buy_res = "int id",--购买资源

    ----------------------------------------------------------------------------
    --task
    daily_task_list = "",    --获取日常任务列表
    life_task_list = "",     --获取主线支线任务列表
    union_task_list = "",    --获取任务列表
    finish_task = "int task_id",     --完成任务获得奖励
    accept_task = "pack task_id_array",     --接任务
}


Client = {
    getTime = "int gTime",

    ply_list = "string proc, string account, pack pids, pack characters",


    onQryCross = "int toPid, int sn, int smap, int spid, string cmd, pack arg",
    onAckCross = "int smap, int sn, int code, pack arg",

    hello = "int pid1, int pid2, string text",
    onLogin = "int pid, string name",
    say = "string say, int nouse",
    say1 = "string say, int nouse",

    -- 聊天
    chat = "int chanelID, int pid, int photo, string name, string word",    --chanelId: enum in common/define/ChatChanelEnum;   pid==-1 means system;   word:the word somebody say
    --chatWithAudio         --TODO
    --获取用户简单信息回应，这次通讯主要是用来获取玩家的聊天基本信息，获取详细信息可以采用另外的接口,remoteAvatarId为空时代表没有自定义头像
    on_get_user_simple_info = "int pid, int vipLevel, string userName, int defaultAvatarId, string remoteAvatarId",

    get_user_info = "pack info",

    testPack = "int i, pack p, string s",

    qryInfo = "pack info",
    loadData = "pack info",
    qryAround = "int x, int y, pack objs",

    tips = "string s",

    add_troop = "pack troop",

    equip_add = "int propid",
    equip_rem = "int sn",

    -- mail
    -- mail_new = "pack mail",
    --mail_unread = "pack mail_class",  -- {[class_id]=unread_count,....}
    --mail_unread_inc = "int class, int inc",

    mail_load = "pack mails",
    mail_sys_new = "int sysMail",

    -- roi
    addEty = "pack obj",
    addEtys = "pack objs",
    remEty = "int eid",

    -- state change
    stateBuild = "pack build",
    statePro = "pack pro",
    stateEf = "pack ef",
    state_ef_hero= "pack ef_hero",
    stateTroop = "pack troop",
    -- 单个英雄发生变化的字段
    stateHero = "pack hero",
    -- {idx（唯一ID）,_id（配置表ID）,num（当前数量）}
    stateItem = "pack items",

    addTips = "string str, pack tab",

    fightInfo = "pack info",
    battle = "int eid, int aid, int did, int pid, int uid",

    gmCmd = "string process, string ack",

    onError = "int cmdHash, int code, int reason",

    union_load = "pack info",
    union_on_create = "pack info",
    --unionRmMemberNotice = "int unionId",
    union_on_rm_member = "int pid",            --broadcast
    union_add_member = "pack info",           --broadcast

    union_destory = "",                      --- 军团解散
    union_list = "pack info",                ---读取军团列表

    union_reject = "int pid",                --广播申请拒绝消息
    union_reply = "int unionId,int state",   --- 发送加入军团申请成功
    union_invite = "int unionId",            ---主动邀请玩家加入军团
    union_mass_on_create = "int mid",   --回复集结创建成功
    union_state_mass = "pack info",     --集结变化(新的集结，完成集结) --broadcast
    --union_state_member = "pack info",   --军团成员变化(战争状态，在线状态，军团属性) --broadcast
    --集结详细(根据敌我方区别显示)
    --atk={id,
    --  A={{pid,name,lv,photo,troop={state,tmStart,tmOver,arms={...}}},{...}}
    --  D={{pid,name,lv,photo},{...}} || D={{propid},{...}}
    --  Dcnt={total}
    --}
    --def={id,
    --  A={{pid,name,lv,photo},{...}}
    --  Acnt={total}
    --  D={{pid,name,lv,photo,troop={state,tmStart,tmOver,arms={...}}},{...}}
    --}
    --union_mass_enemy_info = "pack info",    --敌方集结信息
    union_state_aid = "pack info",
    union_tech_update = "pack info",    --广播科技变化{idx,.id,xx,.tmOver}
    union_tech_mark = "pack info",      --广播新的标记
    union_tech_info = "pack info",      --科技详细信息{idx,id,exp,tmOver,donate={2,0,0}}
    union_donate_info = "pack info",    --更新捐献状态
    union_log = "pack info",            --获取联盟日志
    union_donate_rank = "pack info",  --捐献排名
    union_member_mark = "int pid, string mark", --联盟标记
    union_build_donate = "pack info",       --更新建筑捐献
    --援助目标统计
    --{max,cur,mine,}
    union_aid_count = "pack info",

    --联盟数据广播
    --fight:正在发生的战斗
    --ADD={id,A={{pid,name,lv,photo},{...}},
    --  Ds={total}
    --  Au={uid,alias,flag},
    --  D={{pid,name,lv,photo},{...}},||D={{propid},{...}}
    --  Ds={total}
    --  Du={uid,alias,flag},
    --  Dc={cival,},
    --  T={action,state,tmStart,tmOver,eid,did,sx,sy,dx,dy},
    --}
    --UPDATE={id,A={..},As={...},D={..},Ds={...},T={...}}
    --DELETE={id,}
    --
    --member:联盟成员变化(ADD和DELETE暂时还用union_add_member&union_on_rm_member)
    --ADD={pid,name,lv,rank,photo,mark}
    --UPDATE={pid,name,lv,rank,photo,mark}
    --DELETE={pid}
    --
    --buildlv:建筑变化(exp变化不推)
    --UPDATE={class,id,stage,exp}
    --
    --info:基本信息变化
    --UPDATE={name,alias,language,mars,rank_alias}
    union_broadcast = "string what, int mode, pack info",

    get_room = "int rid,pack info", --获取战斗双方数据
    get_room_troop = "int rid,int pid,pack info", --获取战争的行军队列数据
    get_eid_troop = "int eid,int pid,pack info", --获取建筑的行军队列数据
    get_eye_info = "int eid, pack info",--获取地图单位详细信息
    --troop
    troopx_stdtime = "int did, int tm", --行军标准时间

    --test
    runCommand = "pack info",

    --------------------------------------------------------------------------------
    -- Hero Begin.    YC@2015-12-30
    -- _id name star lv currHP maxHP status fightPower _type personality（随机天性） basicSkill talentSkill atk def exp culture nature（固定天性） quality
    on_get_hero_list_info = "pack heroListInfo",
    -- _id name star lv currHP maxHP status fightPower _type personality（随机天性） basicSkill talentSkill atk def exp culture nature（固定天性） quality
    on_get_hero_detail_info = "pack heroDetailInfo",
    -- hero_idx, skill_idx, skill_id, exp
    on_basic_skill_changed = "int hero_idx, int skill_idx, int skill_id, int exp",
    on_destroy_hero = "int hero_idx",
    -- {{idx, propid,star, fight_power, prison_start_tm, kill_start_tm, kill_over_tm, player_name, player_id, union_name}, ...}
    on_get_prisoners_info = "pack prisoners_info",
    -- 英雄逃脱，被释放、处斩之后告知前端
    on_get_out_of_prison = "string hero_id",
    -- Hero End.
    --------------------------------------------------------------------------------
    get_resm_conf = "int rmb, pack info",--物资市场配置

    -- 建筑完成工作
    on_build_work_completed = "int build_idx",

    ------------------------------------------------------
    --task
    daily_task_list_resp = "pack info",
    life_task_list_resp = "pack info",
    union_task_list_resp = "pack info",
    finish_task_resp = "int result",
    accept_task_resp = "int result",

}

