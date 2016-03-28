#ifndef __ISQ_SENDER_H__
#define __ISQ_SENDER_H__

#include "isq_gserver_mgr.h"

typedef deque<NIMsg*>  MsgDq;

class  CGServerMgr;
class  CLogController;

class CRemoteSender
{
    enum{RECONNECT_WAITSEC = 10};

    enum SENDSTATUS
    {
        SEND_BUSY = 0,
        SEND_IDLE = 1,
    };
public:
    CRemoteSender(const string& strAddr, const uint16_t usPort, uint32_t uiRemoteModuleID, uint32_t uiLocalModuleID,
        PostMsgFunc func, const string& strBindIP);
    ~CRemoteSender(void);

public:
    // 启动发送者
    void     Startup(void);

    // 投递消息到队列
    int32_t  PushMsg(NIMsg* pMsg, int32_t iPriority);

private:
    // 发送消息
    void     ProcessMsg(void);

    // 重连接服务器
    void     ReAsyncConnect(void);

    // 连接服务器
    void     AsyncConnect(void);

    // 连接回调通知
    void     HandleConnect(const boost::system::error_code& e);

    // 接收消息
    void     AsyncRead(void);

    // 接收消息回调
    void     HandleAysncRead(const boost::system::error_code& e, size_t bytes_transferred);

    // 发送消息
    void     AsyncWrite(NIMsg* pMsg);

    // 发送消息回调
    void     HandleAsyncWrite(const boost::system::error_code& e, size_t bytes_transferred, NIMsg* pMsg, size_t sendedBytes);

    // 同步发送消息
    bool     Write(char* pBuf, const uint32_t uiTolLen);

    // 定时发送心跳消息
    void     ProcessTimerMsg(const boost::system::error_code& e);

    // 验证网络连接
    bool     VerifyConnection(void);

    // 验证网络连超时回调
    void     HandleConnectionTimer(const boost::system::error_code& e);

    // 网络连接成功
    void     OnConnected(void);

    // 关闭socket链路
    void     CloseSocket(void);

    // 退出socket连接
    void     ExitSocket(void);

    // 更新链路状态
    void     RefreshLinkStatus(bool bActive);

    // 取消心跳定时器
    void     CancelHeartTimer(void);

    // 取消连接定时器
    void     CancelConnectTimer(void);

    // 退出IO线程
    void     ExitIOThread(void);

    // 停止socket IO
    void     StopSocketIO(void);

    // 释放内存
    void     FreeMemory(void);

public:

    // 关闭线程  bDeleteSelf 是否sender自身析构
    void     KillThread(bool bDeleteSelf);

    // 发送连接断开消息给Mgr
    void     NotifyBreakMsg(void);

    // 发送重连消息给Mgr
    void     NotifyReconnectedMsg(void);

    // 获取链路传输状态
    bool     GetLinkTransStatus(void);

    // 获取链路状态变更时刻
    uint32_t GetLinkStatusTime(void);

    // 获取本地模块ID
    uint32_t GetLocalModuleID(void);

    // 设置程序退出标志
    void     SetExitFlag(void);

private:

    boost::asio::io_service      m_ios;                 // 核心IO读取对象
    tcp::socket                  m_socket;              // 客户端socket
    tcp::endpoint                m_endpoint;
    boost::thread                m_thread;              // 消息队列处理线程对象
    boost::thread                m_socketThread;        // socket处理线程对象

    CDequeMsg                    m_msgQueue;             // 普通消息队列//MsgDq m_msgQueue;
    CDequeMsg                    m_msgHighQueue;         // 高优先级消息队列

    bool                         m_bActived;             // socket活动指示
    bool                         m_bExit;                // Sender退出标志
    PostMsgFunc                  m_ProcSysFunc;          // CGServerMgr消息处理入口

    enum
    {
        // 20万 断开时最大对列数
        SEND_QUEQUE_WAIT_MAX_SIZE = 200000,
        // 200万 正常最大对列数
        SEND_QUEQUE_MAX_SIZE = 2000000,
        //200M 断开时最大队列总长度
        SEND_QUEQUE_WAIT_MAX_LEN = 209715200
    };

    char                         m_szBuffer[MAX_SEND_BUFFER+1];     // 发送缓冲区
    uint8_t                      m_szReadBuffer[MAX_RECV_BUFFER+1]; // 接收缓冲区
    uint32_t                     m_uiReadBytes;//读取字节数

    // 日志对象
    uint32_t                     m_uiRemoteModuleID; //远端模块实例ID
    uint32_t                     m_uiLocalModuleID;

    bool                         m_bDeleteSelf;                                 //是否析构由ProcessMsg调用delete this析构自身
    bool                         m_bLinkTransStatus;                            //链路僵死true:正常 false:僵死

    uint32_t                     m_uiReadErrNums;                           //读取消息连续错误次数

    // 心跳/连接定时器对象
    boost::asio::deadline_timer  m_timerHeart;
    boost::asio::deadline_timer  m_timerConnection;

    // 心跳请求次数
    uint8_t                      m_ucHeartReqTimes;

    // 远端IP/Port
    string                       m_strRemoteIP;
    uint16_t                     m_usPort;

    char                         m_szTid[64];                                   //线程号
};

#endif // __ISQ_SENDER_H__
