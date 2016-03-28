// 消息结构：NIMsg+消息体
#ifndef _MSG_
#define _MSG_

// 包头前相关旗标长度
const   unsigned  short   MSG_FLAG_VAL          = 9754;
// 注册用户名长度
const   unsigned int      USER_NAME_LEN         = 50+1;
// 注册密码长度
const   unsigned int      REG_PWD_LEN           = 10+1;
// 注册相关
const  short          ER_USER_ALREADY_REGISTER        = 1;                             // 此用户名已经注册过
const  short          ER_USER_TOO_MORE                = 2;                             // 系统注册用户过多
const  short          ER_REG_USER_ID_COLLIDE          = 3;                             // 注册用户ID碰撞异常
const  short          ER_REG_USER_NAME_COLLIDE        = 4;                             // 注册用户名碰撞异常
const  short          ER_UNKNOWN_ENTRY                = 5;                             // 未知入口
// 登录相关
const  short          ER_USER_NOT_EXIST               = 100;                           // 此用户不存在
const  short          ER_USER_LOGIN_COLLIDE           = 101;                           // 一个账号不允许同时在多个地方登录
const  short          ER_PWD_INVALID                  = 102;                           // 密码错误
// 通用错误
const  short          ER_DB_OPERATE_FAIL              = 500;                           // DB操作失败
const  short          ER_ALLOCATION_RES_FAIL          = 501;                      // 服务器资源分配失败
enum
{
    MAX_RECV_BUFFER = 1024 * 1024,//最大接收BUFFER大小
    MAX_SEND_BUFFER = 1024 ,//最大发送BUFFER大小
    SINGLE_MSG_MAX_LEN = 8 * 1024 * 1024,//单个消息最大长度
};

// 加密类型
 enum
 {
     RC4_E                       = 1                            // RC4加密算法
 };

// 消息来源旗标
enum MsgSourceFlag_E
{
   MSF_GSERVER                 = 0,                           // 来自游戏服务器
   MSF_SELF_IPHONE             = 1,                           // 自有入口(IPhone)
   MSF_SELF_ANDROID            = 2                            // 自有入口(Android)
};

// 游戏区域节点状态
enum AreaNodeStatus_E
{
    ANS_BUSY               = 0,                           // 繁忙
    ANS_RECOMMEND          = 1                            // 推荐
};

#pragma pack(1) //一字节对齐

// 手机 <-> GServer 消息头
struct MsgHead
{
 short                        Source;                       // 消息来源  Ref：MsgSourceFlag_E
 unsigned int                 Sender;                       // 发送者  手机端为：用户ID;  内部为:模块ID+实例ID;  0为特殊用途（用户注册，还没有分配ID）
 short                        Version;                      // 接口版本
 short                        MsgID;                        // 消息标识
 unsigned short               AreaID;               // 游戏区ID  玩家进入游戏区后 与服务器端的交互 均需要携带>此ID
 unsigned short               num;                        // 消息体的数量
};

// 新 手机 <-> GServer 接口定义
struct NIMsg
{
    int                 Len;                       // 包全长
    char                EncryptType;               // 加密类型
    short               Flag;                 // 加密码
    MsgHead             Head;   // Head
};

enum E_MSG_BASE
{
    MSG_HEART_REQUEST           = 1,            // 手机 ->  GServer    心跳消息
    MSG_MOD_LINK_BREAK          = 2,            // 模块链路断开
    MSG_CONNVERIFY_REQUEST      = 3,            // 连接验证消息
    MSG_CONNVERIFY_RESPONSE     = 4,           // 连接验证确认消息
    MSG_MOD_LINK_RECONN         = 5,            // 远端模块重连
    MSG_TIMER                   = 6,           //定时器消息
  };


// IP地址长度
 const   unsigned int      IP_LEN                = 15;
 // 游戏区名长度
const   unsigned int      AREA_NAME_LEN         = 50+1;
// 游戏区域节点信息
struct AreaNodeInfo
{
    unsigned short       AreaID;                      // 某游戏区ID
    char                 AreaName[AREA_NAME_LEN];     // 某游戏区名称
    unsigned char        Status;                      // 状态   Ref：AreaNodeStatus_E
    char                 Addr[IP_LEN];                // 游戏区域节点IP地址(外网IP)    后续版本 预留 待续
    unsigned short       Port;                        // 端口                         后续版本 预留 待续
    unsigned char        IsEnter;                     // 用户是否有进入过 此游戏区节点 0：没有；1：有
    unsigned char        IsLastArea;                  // 是否是最后所在区 0：不是；1：是
};
#pragma pack()
#endif // _MSG_
