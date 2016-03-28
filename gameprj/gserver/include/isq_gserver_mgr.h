/*----------------------------------------------------------------

 *  Description:  消息分派器
 ----------------------------------------------------------------*/
#ifndef   __GSERVER_MGR_DEFINE_H__
#define   __GSERVER_MGR_DEFINE_H__
#include "isq_gserver_define.h"
#include "isq_thread.h"
#include "isq_logger.h"
#include "isq_database.h"
#include "isq_receiver.h"
#include "isq_sender.h"
#include "isq_encrypt.h"
#include <boost/thread.hpp>
#include <boost/asio.hpp>
#include <string>
#include <deque>

class CRemoteReceiver;
class CGServerMgr;
class CDispatchMgr;
class CAynscWriter;



const unsigned int     MAX_MSG_THREAD       = 100;        // 最大消息处理子线程数

class CAynscWriter : public CThread
{
public:
    CAynscWriter(CQueue<CMsg>* p,CfgInfo *cfg,uint32_t n) :CThread(99)
    {
        m_id = n;
        m_l = NULL;
        m_Task = p;
        m_CfgInfo = cfg;
    };
    virtual ~CAynscWriter(void){  DBClose(m_l);};
public:
    int32_t OnMsg( CMsg* pMsg );
    lua_State* m_l;

private:
    CQueue<CMsg>* m_Task;
    uint32_t                  m_id;// 子线程ID
    CfgInfo *m_CfgInfo;

    bool OnStart(void)
    {
        //加载lua
        m_l =  luaL_newstate();
        //加载lua
        reload_lua(m_l, "lua/pid_main.lua");


        return true;
    }
    void Execute(void)  // 功能: 事务处理者线程接口
    {

        CMsg* e = NULL;

        while (CThread::IsRunning())
        {

            if (1==m_bProcExit) {
                break;
            }

            if (m_Task->Pop(&e))
            {
                Dispatch(e);
                continue;
            }

            ::sleep(1);
        }

    }

    //功能: 事务处理者分派出口
    void Dispatch(CMsg* pTask)
    {

        OnMsg((CMsg*)pTask);
        free(pTask);
        pTask=NULL;
    }

    void OnStop(void)
    {

    };

};

class CDispatchMgr
{
public:
    CDispatchMgr(CfgInfo *p,uint8_t ucNum ) : m_ucWriterNum(ucNum)
    {

        // 创建子线程
        for (uint32_t n = 0 ; n < m_ucWriterNum ; n ++)
        {
            m_pWrites[n] = new CAynscWriter(&m_AllTask,p,n);
            assert(m_pWrites);
        }

        OnStart();

    }
    virtual ~CDispatchMgr(void)
    {
        for (uint32_t n = 0 ; n < m_ucWriterNum ; n ++)
        {
            if (m_pWrites[n])
            {
                ((CAynscWriter*)m_pWrites[n])->Stop();
            }
            delete  m_pWrites[n];
        }
    };
public:
    CQueue<CMsg>    m_AllTask;// 所有任务队列
    CAynscWriter*   m_pWrites[MAX_MSG_THREAD];  // 子线程指针
    uint32_t        m_ucWriterNum;// 子线程数量

    bool Write(CMsg* e)
    {
        return m_AllTask.Push(e);
    }

    bool OnStart(void)
    {

        for (uint32_t n = 0 ; n < m_ucWriterNum ; n ++)
        {
            if (NULL != m_pWrites[n])
            {
                ((CAynscWriter*)m_pWrites[n])->Start();
            }
        }

        return true;
    }

};

typedef __gnu_cxx::hash_map<uint64_t, CRemoteReceiver*>       LinkHMap;
typedef LinkHMap::iterator                         LinkIter;

class CGServerMgr : public CThread
{
public:

    CGServerMgr(CfgInfo *p,uint32_t num): m_acceptor(m_ios),CThread(99)
    {
        m_MsgQueue.clear();
        m_uiLocalModuleID = 0;
        m_pReceiver = NULL;
        m_CfgInfo = p;
        m_l =  luaL_newstate();
        //加载lua
        reload_lua(m_l, "lua/pid_main.lua");

        m_uiLocalModuleID = MKModInstID(m_CfgInfo->ModuleID, m_CfgInfo->InstanceID);

        m_DispatchMgr = new CDispatchMgr(p,num);//多个读线程
        if (!Start()) //创建一个写线程
        {
            printf("GServerMgr start fail, main exit\n");
        }

    };

    virtual ~CGServerMgr(void);

public:
    lua_State* m_l;
    int32_t timer();
    CDispatchMgr* m_DispatchMgr;

   int32_t   DispatchMsg(CMsg* pMsg, int32_t iPriority = 0, uint8_t bBroadcast = SINGLE);
   // 安装系统退出信号
   void      InstallSysSignal(void);
   // 主框架消息处理入口分发
   int32_t   ProcSysMsg(CMsg* pMsg, int32_t iPriority);
   // 获取绑定端口的进程信息
   int       GetProcNoByPort(const uint32_t uiPort, uint32_t &uiProcNo);
   // 获取进程号获取进程名
   int       GetProcNameByProcNo(const uint32_t uiProcNo, char *pszProcName);
   void      OffLine(uint32_t uiUserID, uint64_t ullLink);
   NIMsg*  InitMsg( uint32_t Len );
   void      SendMsg(NIMsg*, uint64_t);

protected:
   bool      OnStart(void);//新建线程
   void      OnStop(void);
   void      Execute(void);//新建线程运行的函数

private:
    bool           LoadData(void);
    NIMsg* MSG1_CS_GET_PLAYER_ORDER_fun(int ,char* );
    NIMsg* MSG1_CS_GET_PLAYER_ORDER2_fun(int ,char* );
    NIMsg* MSG1_CS_GET_PLAYER_ORDER3_fun(int ,char* );
    NIMsg* MSG1_CS_GET_PLAYER_INFO_fun(int ,char* );
    NIMsg* MSG1_CS_GET_OTHER_PLAYER_fun(int ,char* );
    NIMsg* MSG1_CS_PLAYER_INFO_fun(int,char* );
    // 启动服务器
    bool     StartServer(uint16_t usPort);
   // 异步接受客户端连接
    void     AsyncAccept(void);
   // 异步接受客户端连接回调函数
    void     HandleAccept(const boost::system::error_code &e, CRemoteReceiver* pReceiver);
   // 任务ID归属用户绑定
   void     AttachClient(uint64_t ulUserID, CRemoteReceiver* pClient);

   // 用户注册处理
   NIMsg*     OnRegister(int,char*);
   // 用户登录处理
   NIMsg*     OnLogin(int* ,char* );

public:
   LinkHMap                    m_LinkHMap;          //一般链路队列
   CRemoteReceiver*            m_pReceiver;          // 接受链路(一次一个)

   // IO服务对象
   boost::asio::io_service     m_ios;
   tcp::acceptor               m_acceptor;
   boost::thread               m_hSockThread;
   uint32_t                    m_uiLocalModuleID;                   // 本地模块ID
   CfgInfo*                    m_CfgInfo;
private:
   deque<CMsg*>                m_MsgQueue;  //接受所有玩家的消息队列
};


#endif // __GSERVER_MGR_DEFINE_H__
