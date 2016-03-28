#ifndef _MSG_DEF_1_
#define _MSG_DEF_1_
#include "msg.h"

#pragma pack(1) //一字节对齐

const   short  INTERFACE_VERSION     = 100; //版本号

//消息ID： 发送和接受暂时用一个ID
enum E_MSG_1
{
    CS_PLAYER_REG             = 50,         // cs_reg ->  sc_reg    用户注册
    CS_PLAYER_LOGIN           = 51,         // 手机 ->  GServer    用户登陆

    MSG1_CS_PLAYER_INFO = 100,            //保存玩家数据      cs_player_info          --->  ret
    MSG1_CS_GET_OTHER_PLAYER = 101,      //获取其他玩家数据    cs_get_player_info  * n   --->     other_player_info*n
    MSG1_CS_GET_PLAYER_ORDER = 102,      //获取周排行        cs_get_player_order     ---->     sc_get_player_order
    MSG1_CS_GET_PLAYER_INFO = 103,      //获取自己数据       NULL     --->     cs_player_info
    MSG1_CS_GET_PLAYER_ORDER2 = 104,      //获取月排行         cs_get_player_order     ---->     sc_get_player_order
    MSG1_CS_GET_PLAYER_ORDER3 = 105,      //获取总排行         cs_get_player_order     ---->     sc_get_player_order

};

// 用户注册请求
struct cs_reg
{
    char       name[USER_NAME_LEN];
    int        seed;                //随机数
    char       pwd[REG_PWD_LEN];
    char       nation;              //国籍
    char       id[USER_NAME_LEN]; //平台唯一id

};
// 用户注册响应
struct sc_reg
{
    unsigned int   id;     // 用户id
};

// 用户发起登录
struct cs_login
{
    char        name[USER_NAME_LEN];
    int         seed;               //随机数
    char        pwd[REG_PWD_LEN];
};
// 用户登录响应
struct sc_login
{
    unsigned int         id;                      // 服务器返回的用户ID 之后与所有与服务器端交互时携带
    unsigned short      AreaNum;                  // 各游戏区数量
};


struct msg_task     //任务：AID_TASK(4)
{
    unsigned short uId_1;               //id1
    unsigned short uId_2;               //id2
    unsigned short uId_3;               //id3
};

struct msg_role //角色信息：AID_ROLE(4)
{
    unsigned short id;          //id
    unsigned short lv;          //等级
    unsigned short str;         //力量值
    unsigned short dex;         //敏捷值
    unsigned short spec;        //特殊值
    msg_task task;              //完成的任务
};

struct msg_pet  //宠物信息：AID_PET(2)
{
    unsigned short id;          //宠物id
    unsigned short lv;          //等级

};

struct msg_skill  //技能信息
{
    unsigned short id;
    unsigned short lv;//等级
};

struct msg_suc  //成就：AID_SUCCESS(1)
{
    unsigned short id;
    unsigned short value;
};

struct cs_player_info
{
    unsigned int distance;
    #if 0
    unsigned short money;
    unsigned short diamond;
    unsigned short chaper;
    unsigned short role_num;    //msg_role角色数量
    unsigned short pet_num;     //msg_pet宠物数量
    unsigned short equip_num;   //msg_equip装备数量
    unsigned short item_num;    //msg_item物品数量
    unsigned short skill_num;   //msg_skill技能数量
    unsigned short suc_num;     //msg_suc成就数量
    #endif
};

struct msg_equip
{
    unsigned short id;          //id
    unsigned short type;        //类型
    unsigned short lv;          //等级
    unsigned char use;                  //1:装备 0：未装备
};

struct msg_item
{
    unsigned short id;           //id
    unsigned short num;         //数量
};


struct cs_get_player_info
{
    char name[USER_NAME_LEN];
    char nation;
    unsigned int id;
};

struct other_player_info
{
    cs_get_player_info player;
    unsigned int   distance;
 };


struct sc_get_player_info
{
    unsigned int   distance;
};

struct cs_get_player_order
{
    unsigned short   num;
};

struct sc_get_player_order
{
    cs_get_player_info player;
    unsigned int   distance;
};
#pragma pack()
#endif
