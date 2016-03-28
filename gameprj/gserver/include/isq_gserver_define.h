// ----------------------------------------------------------------
// Description   : 模块相关数据结构定义
// ----------------------------------------------------------------
#ifndef   __AGENT_DEFINE_H__
#define   __AGENT_DEFINE_H__

#include "boost/thread.hpp"
#include "boost/function.hpp"
#include "boost/bind.hpp"
#include "boost/asio.hpp"

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/uio.h>
#include <sys/wait.h>
#include <sys/un.h>

#include <arpa/inet.h> //inet_addr()
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <iconv.h>

#include <typeinfo>
#include <dirent.h>
#include <stdarg.h>
#include <utility>
#include <assert.h>
#include <errno.h>
#include <stdint.h> //for uint32_t
#include <unistd.h>
#include <string>
#include <deque>
#include <algorithm>
#include <ext/hash_map>
#include <ext/hash_set>

using namespace  std;
using namespace boost::asio;
using boost::asio::ip::tcp;
#define   MAX_PATH   260


#include "msg.h"
#include "msg_def_1.h"


extern "C"
{
    #include <stdio.h>
    #include "lua.h"
    #include "lualib.h"
    #include "lauxlib.h"
}

const unsigned int     MAX_MSG_LEN       = 8 * 1024 * 1024;
const unsigned int     LOGIN_USER_LEN    = 51;
const unsigned int     DEBUG_BUF_LEN     = 101;

const unsigned int     MAX_MODULES       = 0xFF;        // 最大模块数
const unsigned int     MAX_INSTANCE      = 0xFF;        // 最大实例数
const unsigned int     MODULE_NAME_LEN   = 31;

typedef void* HANDLE;
extern int  m_bProcExit;
extern int  m_exitnum;

//定义消息入口分发函数
typedef  boost::function<int32_t(NIMsg*, int32_t)> PostMsgFunc;


// 计算模块id和实例id的组合值
#define MKModInstID(ModID,InstID) ((uint32_t)(((ModID)<<16)|((InstID)&0xFFFF)))

#define GetInsID(val) (val&0xFFFF)
#define GetModID(val) (val>>16)

// DB地址
struct HostIpPort
{
    char       Address[16];
    uint16_t   Port;
};

// DB帐号
struct DBInfo
{
    HostIpPort  DBHost;
    char        UserName[16];
    char        PassWord[16];
    char        DataBase[16];
};

// GServer配置
struct CfgInfo
{
    uint32_t    ListenPort;
    char        BindIP[16];
    uint16_t    ModuleID;             // 模块ID
    uint16_t    InstanceID;           // 实例ID
    char        Name[MODULE_NAME_LEN];// 模块名称
    uint16_t    SaveCycle;            // 日志保存周期（单位：年）
    uint8_t     LogLevel;             // 日志级别
};


// 消息处理返回结果，框架根据返回值决定是否释放消息缓冲区
enum PROC_STATUS
{
    PROC_SUCCESS    = 0,                                    //处理成功
    PROC_HOLD       = 1,                                    //用户保持了该消息，在用户使用完毕后由用户自行释放
    PROC_NO         = 2,                                    //没有处理消息
    PROC_FAILED     = 0xFFFFFFFF                            //处理失败
};

// 广播类型  1=后台广播  2=前台广播  3=全局广播  4=模块内实例广播
enum MSGTYPE
{
    SINGLE          = 0,
    BROADCAST       = 1,
    BROADCASTFRONT  = 2,
    BROADCASTALL    = 3,
    BROADCASTINST   = 4
};

enum MSGPRIORITY
{
    PRIORITY_NORMAL =   0,                      // 普通优先级
    PRIORITY_HIGH   =   1                       // 高优先级
};

enum ONLINE_STATUS
{
    OS_ONLINE                               = 1,          // 在线
    OS_OFFLINE                              = 0           // 离线
};

// 内部消息结构
class CMsg
{
public:
    uint32_t    Sender;                                     // 消息发送者
    uint32_t    Receiver;                                   // 0:定时器1：优先线程
    uint32_t    MsgID;                                      // 消息标识
    uint64_t    UserData;                                   // 用户数据,对于定时器消息，携带的时启动定时器时的用户数据
    uint64_t    UserData2;                                  // server对象
    uint32_t    PayloadLen;                                 // 负载内容的有效长度 (不包含头长度)
    uint32_t    Checksum;                                   // 消息校验字,在发送时由发送模块自动填入 值 = 消息标识 ^ 负载长度
};

// 来自终端的消息结构定义
class CEPMsg: public CMsg
{
public:
    char       Buf[0];           // 参数NIMsg
};




class CDequeMsg
{
public:
    CDequeMsg()
        : m_dqCntZero(0)
        , m_dqSize(0)
    {

    }

    ~CDequeMsg()
    {

    }

    inline void push_front(NIMsg* pT)
    {

        m_dqCntZero++;
        m_dqZero.push_front(pT);
        m_dqSize += (pT->Len);

    }

    inline void push_back(NIMsg* pT)
    {

        m_dqCntZero++;
        m_dqZero.push_back(pT);
        m_dqSize += ( pT->Len);

    }

    inline NIMsg* front()
    {
        NIMsg* pT = NULL;

        if(!m_dqZero.empty())
        {
            pT = m_dqZero.front();
            m_dqZero.pop_front();
            m_dqCntZero--;
            m_dqSize -= ( pT->Len);
        }
        else
        {
            m_dqSize = 0;                                   //Zero 队列长度清零
            m_dqCntZero = 0;                                //Zero 队列大小清零
        }
        return pT;
    }

    inline uint32_t size()
    {
        return m_dqCntZero;
    }

    inline uint64_t GetSize()
    {
        return m_dqSize;
    }

    uint32_t GetAllBuff(deque<NIMsg*>& ls, const uint32_t uiCnt = 500)
    {
        uint32_t uiNum = 0;

        while(++uiNum <= uiCnt)
        {
            if(!m_dqZero.empty())
            {
                ls.push_back(m_dqZero.front());
                m_dqSize -= ( m_dqZero.front()->Len);
                m_dqZero.pop_front();
                m_dqCntZero--;
            }
            else
            {
                m_dqCntZero = 0;                            //Zero 队列大小清零
            }
        }

        return (uint32_t)(ls.size());
    }

    uint64_t ClearDeque()
    {
        NIMsg* pT;
        uint64_t ulNums = 0;

        while (!m_dqZero.empty())
        {
            pT = m_dqZero.front();
            m_dqZero.pop_front();
            if (pT != NULL)
            {
                free(pT);
                pT=NULL;
            }
            ulNums++;
        }

        return ulNums;
    }

private:
    deque<NIMsg*>    m_dqZero;                               //Zero 队列
    uint32_t        m_dqCntZero;                            //Zero 队列大小
    int64_t         m_dqSize;                               //Zero 队列长度
};



#endif // __AGENT_DEFINE_H__
