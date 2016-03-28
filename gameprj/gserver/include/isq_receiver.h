#ifndef __ISQ_RECEIVER_H__
#define __ISQ_RECEIVER_H__

#include "isq_gserver_mgr.h"

// -------------------------------------------------------------------


class  CGServerMgr;
class  CLogController;

class CRemoteReceiver
{
public:
    CRemoteReceiver(boost::asio::io_service& ios, CGServerMgr* pFMsg);
    ~CRemoteReceiver(void);
    uint32_t  m_uiUserID;

public:

    tcp::socket& socket(void)
    {
        return m_socket;
    }

    // 启动异步消息接收
    void        Startup(void);
    int32_t     AsyncWrite(NIMsg* pMsg);

    int32_t     PushMsg(NIMsg* pMsg, int32_t iPriority);
    int32_t     EnumMsg(void);

    string      GetRemoteIP(void);
    uint32_t    GetRemotePort(void);


private:
    void        AsyncRead(void);
    void        HandleAysncRead(const boost::system::error_code &e, size_t bytes_transferred);

    void        HandleHeartResponse(const boost::system::error_code& e, size_t bytes_transferred, NIMsg* pMsg);
    void        HandleHeartResponse(NIMsg* pMsg);

    // 处理并派发消息
    bool        ProcessMsg(size_t bytes_transferred);

    // 获取socket链路IP&PORT
    bool        GetSocketIPAndPort(void);

    // 设置socket send buffer size
    bool        SetSocketSendBuffSize(uint32_t uiSize);
    // 设置socket recv buffer size
    bool        SetSocketRecvBuffSize(uint32_t uiSize);
    // 设置socket linger option
    bool        SetSocketLingerOption(void);

    bool        OnRecvObject(NIMsg* pMsg);

private:

    // 网络传输相关对象
    boost::asio::io_service&  m_ios;
    tcp::socket     m_socket;
    // 消息队列处理线程对象
    boost::thread   m_thread;
    deque<NIMsg*>    m_MsgQueue; //发送到一个玩家的队列

    enum RUNSTATUS {STOPING=0,RUNING=1,EXITING=2,EXITED=3};
    // 线程是否运行
    RUNSTATUS       m_isRun;

    // 接收消息的缓冲区，最大消息长度为8M
    enum{MAX_BUFFER_SIZE= 8 * 1024 * 1024};

    // 接收缓冲区
    uint8_t*                    m_pBuffer;
    uint32_t                    m_uiOffsetPos;

    // 日志/GServer对象指针
    CGServerMgr*                m_pGServerMgr;
    bool                        m_bRet;

    // 远端IP/PORT/用户ID
    string                      m_strRemoteIP;
    uint16_t                    m_usPort;
};

#endif // __ISQ_RECEIVER_H__
