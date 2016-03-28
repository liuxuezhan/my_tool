#include "isq_sender.h"
#include <boost/lexical_cast.hpp>
#include <sys/prctl.h>

CRemoteSender::CRemoteSender(const string& strAddr, const uint16_t usPort, uint32_t uiRemoteModuleID, uint32_t uiLocalModuleID,
                             PostMsgFunc func, const string& strBindIP)
        : m_socket(m_ios)
        , m_endpoint(boost::asio::ip::address::from_string(strAddr), usPort)
        , m_bActived(false)
        , m_bExit(false)
        , m_ProcSysFunc(func)
        , m_uiReadBytes(0)
        , m_uiRemoteModuleID(uiRemoteModuleID)
        , m_uiLocalModuleID(uiLocalModuleID)
        , m_timerHeart(m_ios)
        , m_timerConnection(m_ios)
        , m_ucHeartReqTimes(0)
{
    m_strRemoteIP = strAddr;
    m_usPort = usPort;

    if (strlen(strBindIP.c_str()) >= 7)
    {
        boost::asio::ip::tcp::endpoint tmpPoint(boost::asio::ip::address::from_string(strBindIP), 0);
        m_socket.open(boost::asio::ip::tcp::v4());
        m_socket.bind(tmpPoint);

        LOGGER_DEBUG(CLogController::getinstance(), "IP绑定 BindIP=" << strBindIP.c_str()
            << "ModID=" << GetModID(m_uiRemoteModuleID)
            << " InstID=" << GetInsID(m_uiRemoteModuleID)
            << " IP=" << m_strRemoteIP.c_str() << " Port=" << m_usPort);
    }

    m_bDeleteSelf = true;
    m_bLinkTransStatus = true;
    m_uiReadErrNums = 0;

    memset(m_szTid, 0, sizeof(m_szTid));
}

CRemoteSender::~CRemoteSender(void)
{
    // 取消心跳定时器
    CancelHeartTimer();

    // 取消连接定时器
    CancelConnectTimer();

    // 退出socket连接
    ExitSocket();

    LOGGER_DEBUG(CLogController::getinstance(), "Sender线程退出成功: RModID="
        << GetModID(m_uiRemoteModuleID) << " RInsID="
        << GetInsID(m_uiRemoteModuleID) << " IP="
        << m_strRemoteIP.c_str() << " Port="
        << m_usPort << " LModID="
        << GetModID(m_uiLocalModuleID) << " LInsID="
        << GetInsID(m_uiLocalModuleID) <<" TID=" << m_szTid);
}

void CRemoteSender::Startup(void)
{
    // 异步链接
    AsyncConnect();

    try
    {
        // 创建socket线程
        boost::thread sockThread(boost::bind(&boost::asio::io_service::run, &m_ios));
        m_socketThread.swap(sockThread);

        // 启动消息队列处理线程
        boost::thread threadProcMsg(boost::bind(&CRemoteSender::ProcessMsg, this));
        m_thread.swap(threadProcMsg);
    }
    catch(const boost::system::error_code& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Sender线程启动失败 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " IP="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << ". 原因: " << e.message());
    }
    catch(const boost::system::system_error& sysex)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Sender线程启动失败 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " IP="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << ". 原因: " << sysex.what());
    }
    catch(...)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Sender线程启动失败 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " IP="
            << m_strRemoteIP.c_str() << " Port=" << m_usPort);
    }
}

// 循环发送消息队列中的消息，如果网络错误则丢弃
void CRemoteSender::ProcessMsg(void)
{
    NIMsg*       pMsgTemp = NULL;
    NIMsg*       pMsg = NULL;
    uint32_t    uiSendFlag = 0;  // 发送标志
    uint32_t    uiCurPkgLen = 0; // 当前包长度
    uint32_t    uiToBuffLen = 0; // 发送缓冲区长度

    const uint32_t uiHeadLen = sizeof(NIMsg);
    MsgDq       dMsg;

    snprintf(m_szTid, sizeof(m_szTid), "0x%x", (uint32_t)pthread_self());

    LOGGER_DEBUG(CLogController::getinstance(), "消息发送线程 Enter RModID="
        << GetModID(m_uiRemoteModuleID) << " RInsID="
        << GetInsID(m_uiRemoteModuleID) << " IP="
        << m_strRemoteIP.c_str() << " Port="
        << m_usPort << " LModID="
        << GetModID(m_uiLocalModuleID) << " LInsID="
        << GetInsID(m_uiLocalModuleID) << " tid=" << m_szTid);

    char szProcName[128] = {0};
    snprintf(szProcName, sizeof(szProcName), "PrcSnd_%u_%u", GetModID(m_uiRemoteModuleID), GetInsID(m_uiRemoteModuleID));
    prctl(PR_SET_NAME, (unsigned long)szProcName);

    while (!m_bExit)
    {
        boost::this_thread::interruption_point();

        // 解决消息断网时丢失
        if (!m_bActived)
        {
            usleep(10000);                                  // 降CPU
            continue;
        }

        // 取出消息队列中的元素并逐个异步发送 每次获取500个
        if (NULL != pMsgTemp)                               // 如果有上次处理没有发送的数据包
        {
            // 先添加未发送数据
            uiSendFlag = 0;
            uiToBuffLen = 0;
            uiCurPkgLen = (uint32_t)(pMsgTemp->Len );

            if (uiCurPkgLen >= MAX_SEND_BUFFER)             // 单包数据发送超过最大组包长度
            {
                if (!Write((char*)pMsgTemp, uiCurPkgLen))
                {
                    ExitSocket();
                    free(pMsgTemp);
                    pMsgTemp = NULL;
                    continue;
                }
            }
            else    //如果为正常长度包数据  组包发送
            {
                memcpy(m_szBuffer + uiToBuffLen, (void*)pMsgTemp, uiCurPkgLen);
                uiToBuffLen += uiCurPkgLen;
            }

            free(pMsgTemp);
            pMsgTemp = NULL;
        }

        // 如果高优先级队列有消息,则发送高优先级消息队列
        if (m_msgHighQueue.size() && (pMsg = m_msgHighQueue.front()))
        {
            // 如果消息为空不处理
            if(NULL == pMsg)
            {
                continue;
            }

            uiCurPkgLen = (uint32_t)(pMsg->Len );

            // 发送缓冲区已满, socket处于连接状态
            if((uiToBuffLen + uiCurPkgLen) > MAX_SEND_BUFFER) // 如果 当前包长度+待发长度 大于 发送总长 则保留当前包
            {
                uiSendFlag = 1;
                pMsgTemp = pMsg;
            }
            else                                               // 如果 当前包长度+待发长度 小于等于 发送总长 发送当前包数据
            {
                memcpy(m_szBuffer + uiToBuffLen, (void*)pMsg, uiCurPkgLen);
                uiToBuffLen += uiCurPkgLen;
                free(pMsg);
                pMsg=NULL;
            }
        }
        else if(dMsg.size())                              // 如果普通消息缓存队列不为空,发送普通消息缓存队列
        {
            pMsg = dMsg.front();
            dMsg.pop_front();

            // 如果消息为空不处理
            if(NULL == pMsg)
            {
                continue;
            }

            uiCurPkgLen = (uint32_t)( pMsg->Len );

            // 发送缓冲区已满, socket处于连接状态
            if((uiToBuffLen + uiCurPkgLen) > MAX_SEND_BUFFER) // 如果 当前包长度+待发长度 大于 发送总长 则保留当前包
            {
                uiSendFlag = 1;
                pMsgTemp = pMsg;
            }
            else                                               // 如果 当前包长度+待发长度 小于等于 发送总长 发送当前包数据
            {
                memcpy(m_szBuffer + uiToBuffLen, (void*)pMsg, uiCurPkgLen);
                uiToBuffLen += uiCurPkgLen;
                free(pMsg);
                pMsg=NULL;
            }
        }
        else if(!m_msgQueue.GetAllBuff(dMsg, 1000))
        {
            // 获取发送数据 如果队列为空则发送缓冲区数据
            uiSendFlag = 0;

            if (uiToBuffLen)
            {
                // 如果缓冲区有数据 发送数据
                uiSendFlag = 1;
            }
            else
            {
                usleep(10000);           // 降所有CPU
            }
        }

        // 发送消息
        if (uiSendFlag && m_bActived)
        {
            // 如果网络连接正常则发送(异步发送 AsyncWrite(pMsg))
            if (!Write(m_szBuffer, uiToBuffLen))
            {
                ExitSocket();
            }

            uiSendFlag = 0;
            uiToBuffLen = 0;
        }
    } // while

    uint32_t uiQueSize = (uint32_t)(dMsg.size() + m_msgQueue.size());
    uint32_t uiHighQueSize = m_msgHighQueue.size();

    LOGGER_DEBUG(CLogController::getinstance(), "消息发送线程 End ModID="
        << GetModID(m_uiRemoteModuleID) << " InsID ="
        << GetInsID(m_uiRemoteModuleID) << " IP="
        << m_strRemoteIP.c_str() << " Port="
        << m_usPort << " Que="
        << uiQueSize << " HighQue="
        << uiHighQueSize << " TID=" << m_szTid);

    //释放内存
    FreeMemory();
    while(dMsg.size())
    {
        free(dMsg.front());
        dMsg.pop_front();
    }

    if (NULL != pMsgTemp)
    {
        free(pMsgTemp);
        pMsgTemp = NULL;
    }

    // 结束线程
    ExitIOThread();

    delete this;
}

// 将消息投递到消息队列并立即返回 链路断开时,队列总长不超过200M(209715200)
int32_t CRemoteSender::PushMsg(NIMsg* pMsg, int32_t iPriority)
{
    if (m_bExit)
    {
        return -1;
    }

    uint32_t  uiTotalLen = (uint32_t)(pMsg->Len );

    // 消息超出8M大小限制
    if ( pMsg && (uiTotalLen > SINGLE_MSG_MAX_LEN) )
    {
        LOGGER_ERROR(CLogController::getinstance(), "发送消息超过最大消息长度="
            << uiTotalLen << " MsgID="
            << pMsg->Head.MsgID << " IP="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort);

        return -1;
    }

    uint32_t  uiQueSize = 0;                                //对列大小
    if (0 == iPriority)
    {
        // 解决链路占用内存过多
        uiQueSize = m_msgQueue.size();
        if (uiQueSize >= SEND_QUEQUE_MAX_SIZE
            || (!m_bActived && (uiQueSize >= SEND_QUEQUE_WAIT_MAX_SIZE
                || m_msgQueue.GetSize() > SEND_QUEQUE_WAIT_MAX_LEN)))
        {
            return -1;
        }

        m_msgQueue.push_back(pMsg);
    }
    else
    {
        // 解决链路占用内存过多
        uiQueSize = m_msgHighQueue.size();
        if (uiQueSize >= SEND_QUEQUE_MAX_SIZE
            || (!m_bActived && (uiQueSize >= SEND_QUEQUE_WAIT_MAX_SIZE
                || m_msgHighQueue.GetSize() > SEND_QUEQUE_WAIT_MAX_LEN)))
        {
            return -1;
        }

        m_msgHighQueue.push_back(pMsg);
    }

    return 0;
}

void CRemoteSender::NotifyBreakMsg(void)
{
    NIMsg* pMsg = (NIMsg*)LOG_MALLOC(sizeof(NIMsg));

    if (pMsg == NULL)
    {
        LOGGER_DEBUG(CLogController::getinstance(), "获取内存错误: ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port=" << m_usPort);

        return;
    }

    pMsg->Flag = MSG_FLAG_VAL;
    pMsg->EncryptType = 0;
    pMsg->Len = sizeof(NIMsg);
    pMsg->Head.Source = MSF_GSERVER;
    pMsg->Head.Version = 0;
    pMsg->Head.MsgID = MSG_MOD_LINK_BREAK;

    m_ProcSysFunc (pMsg, PRIORITY_NORMAL);
}

void CRemoteSender::NotifyReconnectedMsg()
{
    NIMsg* pMsg = (NIMsg*)LOG_MALLOC(sizeof(NIMsg));

    if (pMsg == NULL)
    {
        LOGGER_DEBUG(CLogController::getinstance(), "获取内存错误: ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port=" << m_usPort);

        return;
    }

    pMsg->Flag = MSG_FLAG_VAL;
    pMsg->EncryptType = 0;
    pMsg->Len = sizeof(NIMsg);
    pMsg->Head.Source = MSF_GSERVER;
    pMsg->Head.Version = 0;
    pMsg->Head.MsgID = MSG_MOD_LINK_RECONN;

    m_ProcSysFunc (pMsg, PRIORITY_NORMAL);
}

void CRemoteSender::ReAsyncConnect(void)
{
    if (m_bExit)
    {
        return;                                             //退出
    }

    //通知上层模块链路断连
    NotifyBreakMsg();

    //取消心跳定时器
    CancelHeartTimer();

    //关闭socket连接
    ExitSocket();

    //心跳次数清零
    m_ucHeartReqTimes = 0;

    //链路重连
    ::sleep(3);

    AsyncConnect();
}

// 异步连接
void CRemoteSender::AsyncConnect(void)
{
    try
    {
        m_uiReadBytes = 0;
        m_socket.async_connect(m_endpoint, boost::bind(&CRemoteSender::HandleConnect,
            this, boost::asio::placeholders::error));
    }
    catch(const boost::system::error_code& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "连接远端模块异常 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << ". 原因: " << e.message());
    }
    catch(const boost::system::system_error& sysex)
    {
        LOGGER_ERROR(CLogController::getinstance(), "连接远端模块异常 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << ". 原因: " << sysex.what());
    }
    catch(...)
    {
        LOGGER_ERROR(CLogController::getinstance(), "连接远端模块异常 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " IP="
            << m_strRemoteIP.c_str() << " Port=" << m_usPort);
    }
}

// 异步连接回调通知
void CRemoteSender::HandleConnect(const boost::system::error_code &e)
{
    if (e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "本地连接到远端失败, ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << " 原因:" << e.message());

        ::sleep(3);
        AsyncConnect();
    }
    else
    {
        //设置缓冲区
        LOGGER_DEBUG(CLogController::getinstance(), "本地连接到远端成功, ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port=" << m_usPort << " ");
        try
        {
            boost::asio::socket_base::send_buffer_size sendoption(16 * 1024 * 1024);
            m_socket.set_option(sendoption);

            boost::asio::socket_base::receive_buffer_size receiveoption(4 * 1024 * 1024);
            m_socket.set_option(receiveoption);

            boost::asio::socket_base::linger lingeroption(true, 0);
            m_socket.set_option(lingeroption);
        }
        catch(const boost::system::error_code& e)
        {
            LOGGER_ERROR(CLogController::getinstance(), "Sender链路设置异常 ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port="
                << m_usPort << ". 原因: " << e.message());
        }
        catch(const boost::system::system_error& sysex)
        {
            LOGGER_ERROR(CLogController::getinstance(), "Sender链路设置异常 ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port="
                << m_usPort << ". 原因: " << sysex.what());
        }
        catch(...)
        {
            LOGGER_ERROR(CLogController::getinstance(), "Sender链路设置异常 ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port=" << m_usPort);
        }

        //成功连接，启动消息读取
        AsyncRead();

        ::sleep(3);

        VerifyConnection();
    }
}

void CRemoteSender::AsyncRead(void)
{
    m_socket.async_read_some(boost::asio::buffer(m_szReadBuffer + m_uiReadBytes, MAX_RECV_BUFFER - m_uiReadBytes)
        , boost::bind(&CRemoteSender::HandleAysncRead, this
        , boost::asio::placeholders::error
        , boost::asio::placeholders::bytes_transferred));
}

// 异步消息读取回调通知
void CRemoteSender::HandleAysncRead(const boost::system::error_code& e, size_t bytes_transferred)
{
    if (e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "本地读取远端消息错误 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << " 原因:" << e.message());

        // 重连
        ReAsyncConnect();

        if (++m_uiReadErrNums > 30)
        {
            LOGGER_ERROR(CLogController::getinstance(), "读取失败,重新构建连接 ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port="
                << m_usPort << " ReadErrNums=" << m_uiReadErrNums);
            m_bLinkTransStatus = false;
        }

        return;
    }

    m_uiReadBytes += (uint32_t)bytes_transferred;
    uint32_t offset = 0;

    while(1)
    {
        if ((m_uiReadBytes - offset) >= sizeof(NIMsg))
        {
            NIMsg* pMsg = (NIMsg*)(m_szReadBuffer + offset);

            if (MSG_FLAG_VAL != pMsg->Flag)
            {
                LOGGER_ERROR(CLogController::getinstance()," 收到远端消息校验错误 ModID="
                    << GetModID(m_uiRemoteModuleID) << " InsID="
                    << GetInsID(m_uiRemoteModuleID) << " Ip="
                    << m_strRemoteIP.c_str() << " Port=" << m_usPort);

                // 重连
                ReAsyncConnect();

                return;
            }

            if (pMsg->Len  > MAX_RECV_BUFFER)
            {
                LOGGER_ERROR(CLogController::getinstance()," 收到远端消息长度错误 ModID="
                    << GetModID(m_uiRemoteModuleID) << " InsID="
                    << GetInsID(m_uiRemoteModuleID) << " Ip="
                    << m_strRemoteIP.c_str() << " Port=" << m_usPort);

                // 重连
                ReAsyncConnect();

                return;
            }

            if ( pMsg->Len > (m_uiReadBytes - offset) )
            {
                break;
            }

            if (pMsg->Head.MsgID == MSG_HEART_REQUEST)
            {
                m_ucHeartReqTimes = 0;
                m_bLinkTransStatus = true;

                LOGGER_DEBUG(CLogController::getinstance()," 收到远端心跳 ModID="
                    << GetModID(m_uiRemoteModuleID) << " InsID="
                    << GetInsID(m_uiRemoteModuleID) << " Ip="
                    << m_strRemoteIP.c_str() << " Port="
                    << m_usPort << " ");

            }
            else if (pMsg->Head.MsgID == MSG_CONNVERIFY_RESPONSE)
            {
                LOGGER_DEBUG(CLogController::getinstance()," 本地连接到远端成功,连接次数: ModID="
                    << GetModID(m_uiRemoteModuleID) << " InsID="
                    << GetInsID(m_uiRemoteModuleID) << " Ip="
                    << m_strRemoteIP.c_str() << " Port="
                    << m_usPort << " ");

                // 连接OK
                OnConnected();

                // 通知上层业务模块
                NotifyReconnectedMsg();
            }
            else
            {
                LOGGER_ERROR(CLogController::getinstance()," 本地读取远端数据错误 ModID="
                    << GetModID(m_uiRemoteModuleID) << " InsID="
                    << GetInsID(m_uiRemoteModuleID) << " Ip="
                    << m_strRemoteIP.c_str() << " Port="
                    << m_usPort << " Msgid=" << pMsg->Head.MsgID);

                // 重连
                ReAsyncConnect();

                return;
            }
            offset += (uint32_t)(pMsg->Len );
        }
        else // if ((m_uiReadBytes
        {
            break;
        } // if ((m_uiReadBytes
    } // while(1 ...

    if (offset > 0)
    {
        m_uiReadBytes -= offset;
        memmove(m_szReadBuffer, m_szReadBuffer + offset, m_uiReadBytes);
    }

    AsyncRead();
}

void CRemoteSender::AsyncWrite(NIMsg* pMsg)
{
    if (NULL != pMsg)
    {
        m_socket.async_send(boost::asio::buffer(pMsg, pMsg->Len),
            boost::bind(&CRemoteSender::HandleAsyncWrite, this, boost::asio::placeholders::error,
            boost::asio::placeholders::bytes_transferred, pMsg, 0));
    }
}

void CRemoteSender::HandleAsyncWrite(const boost::system::error_code& e, size_t bytes_transferred, NIMsg* pMsg, size_t sendedBytes)
{
    // 此处释放消息存储空间
    if(e)
    {
        if (pMsg == NULL)
        {
            LOGGER_ERROR(CLogController::getinstance(), "远程业务模块连接认证请求消息发送失败, ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port="
                << m_usPort << " 原因: pMsg==NULL");
        }
        else if (pMsg->Head.MsgID == MSG_CONNVERIFY_REQUEST)
        {
            LOGGER_ERROR(CLogController::getinstance(), "远程业务模块连接认证请求消息发送失败, ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port="
                << m_usPort << " 原因:" << e.message());
        }
        else if (pMsg->Head.MsgID == MSG_HEART_REQUEST)
        {
            LOGGER_ERROR(CLogController::getinstance(), "远程业务模块心跳包消息发送失败, ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port="
                << m_usPort << " 原因:" << e.message());
        }
        else
        {
            LOGGER_ERROR(CLogController::getinstance(), "远程业务模块消息发送失败, ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port="
                << m_usPort << " Msgid="
                << pMsg->Head.MsgID << " 原因:" << e.message());
        }

        free((void*)pMsg);
        pMsg=NULL;

    }
    else
    {
        sendedBytes += bytes_transferred;

        if (pMsg != NULL)
        {
            if (sendedBytes >= (pMsg->Len ))
            {
                // 消息发送完毕
                free((void*)pMsg);
                pMsg=NULL;
            }
            else
            {
                m_socket.async_send(
                    boost::asio::buffer((char*)pMsg + sendedBytes,
                    pMsg->Len - sendedBytes),
                    boost::bind(&CRemoteSender::HandleAsyncWrite, this,
                    boost::asio::placeholders::error,
                    boost::asio::placeholders::bytes_transferred,
                    pMsg, sendedBytes));
            }
        }
        else
        {
            LOGGER_ERROR(CLogController::getinstance(), "远程业务模块消息被异常修改, ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port="
                << m_usPort << ", Close the socket.");
        }
    }
}

bool CRemoteSender::Write(char* pBuf, const uint32_t uiTolLen)
{
    bool   bResult = true;

    if (uiTolLen != 0)
    {
        uint32_t sendBytes = 0;
        uint32_t totalBytes = uiTolLen;

        while (sendBytes < totalBytes && !m_bExit)
        {
            try
            {
                uint32_t nBytes = (uint32_t)(m_socket.write_some(boost::asio::buffer(((char*)pBuf) + sendBytes, totalBytes - sendBytes)));
                sendBytes += nBytes;
            }
            catch(const boost::system::error_code& e)
            {
                LOGGER_ERROR(CLogController::getinstance(), "本地发送消息到远端错误 ModID="
                    << GetModID(m_uiRemoteModuleID) << " InsID="
                    << GetInsID(m_uiRemoteModuleID) << " Ip="
                    << m_strRemoteIP.c_str() << " Port="
                    << m_usPort << ". 原因: " << e.message());
                bResult = false;
                break;
            }
            catch(const boost::system::system_error& sysex)
            {
                LOGGER_ERROR(CLogController::getinstance(), "本地发送消息到远端错误 ModID="
                    << GetModID(m_uiRemoteModuleID) << " InsID="
                    << GetInsID(m_uiRemoteModuleID) << " Ip="
                    << m_strRemoteIP.c_str() << " Port="
                    << m_usPort << ". 原因: " << sysex.what());
                bResult = false;
                break;
            }
            catch(...)
            {
                LOGGER_ERROR(CLogController::getinstance(), "本地发送消息到远端错误 ModID="
                    << GetModID(m_uiRemoteModuleID) << " InsID="
                    << GetInsID(m_uiRemoteModuleID) << " Ip="
                    << m_strRemoteIP.c_str() << " m_usPort=" << m_usPort);
                bResult = false;
                break;
            }
        }
    }

    return bResult;
}

void CRemoteSender::ProcessTimerMsg(const boost::system::error_code& e)
{
    // Handle the timer exception.
    if (e)
    {
        return;
    }

    // 如果系统处于空闲状态 发送心跳消息
    if (m_bActived && !m_bExit)
    {

        m_ucHeartReqTimes++;
        if (m_ucHeartReqTimes > 6)
        {
            // 超时分为2种情况:1、链路僵死 2、传输瓶颈导致应答消息丢失
            LOGGER_ERROR(CLogController::getinstance(), "Recv Heart Respond Timer Out. 请检查是否存在传输或资源瓶颈 ModID="
                << GetModID(m_uiRemoteModuleID) << " InsID="
                << GetInsID(m_uiRemoteModuleID) << " Ip="
                << m_strRemoteIP.c_str() << " Port="
                << m_usPort << " tid=" << m_szTid);

            m_bLinkTransStatus = false;         //僵死

            ExitSocket();                       //关闭连接
        }
        else
        {
            NIMsg* pMsg = (NIMsg*)LOG_MALLOC(sizeof(NIMsg));

            if (pMsg == NULL)
            {
                m_ucHeartReqTimes--;
                LOGGER_ERROR(CLogController::getinstance(), "获取内存错误: ModID="
                    << GetModID(m_uiRemoteModuleID) << " InsID="
                    << GetInsID(m_uiRemoteModuleID) << " Ip="
                    << m_strRemoteIP.c_str() << " Port=" << m_usPort);
            }
            else
            {
                pMsg->Flag = MSG_FLAG_VAL;
                pMsg->EncryptType = 0;
                pMsg->Len = sizeof(NIMsg);
                pMsg->Head.Source = MSF_GSERVER;
                pMsg->Head.Version = 0;
                pMsg->Head.MsgID = MSG_HEART_REQUEST;

                if (PushMsg(pMsg, 1) == -1)
                {
                    free((void*)pMsg);
                    pMsg=NULL;

                }
            }

            m_timerHeart.expires_from_now(boost::posix_time::seconds(5));
            m_timerHeart.async_wait(boost::bind(&CRemoteSender::ProcessTimerMsg,
                this, boost::asio::placeholders::error));
        }
    }
}

bool CRemoteSender::VerifyConnection(void)
{
    NIMsg* pMsg = (NIMsg*)LOG_MALLOC(sizeof(NIMsg));

    if (pMsg == NULL)
    {
        LOGGER_DEBUG(CLogController::getinstance(), "获取内存错误: ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port=" << m_usPort);

        return false;
    }

    pMsg->Flag = MSG_FLAG_VAL;
    pMsg->EncryptType = 0;
    pMsg->Len = sizeof(NIMsg);
    pMsg->Head.Source = MSF_GSERVER;
    pMsg->Head.Version = 0;
    pMsg->Head.MsgID = MSG_CONNVERIFY_REQUEST;

    AsyncWrite(pMsg);

    m_timerConnection.expires_from_now(boost::posix_time::seconds(30));
    m_timerConnection.async_wait(boost::bind(&CRemoteSender::HandleConnectionTimer,
        this, boost::asio::placeholders::error));

    return true;
}

void CRemoteSender::HandleConnectionTimer(const boost::system::error_code& e)
{
    if (e)
    {
        return;
    }

    LOGGER_ERROR(CLogController::getinstance(), "Recv Verify Respond Timer Out. ModID="
        << GetModID(m_uiRemoteModuleID) << " InsID="
        << GetInsID(m_uiRemoteModuleID) << " Ip="
        << m_strRemoteIP.c_str() << " Port=" << m_usPort);

    m_bLinkTransStatus = false;
}

void CRemoteSender::OnConnected(void)
{
    //取消连接定时器
    CancelConnectTimer();

    RefreshLinkStatus(true);

    //启动心跳定时器
    m_timerHeart.expires_from_now(boost::posix_time::seconds(5));
    m_timerHeart.async_wait(boost::bind(&CRemoteSender::ProcessTimerMsg,
        this, boost::asio::placeholders::error));
}

void CRemoteSender::RefreshLinkStatus(bool bActive)
{
    m_bActived = bActive;
}

void CRemoteSender::KillThread(bool bDeleteSelf)
{
    if (m_bActived)
    {
        NotifyBreakMsg();                                   //通知上层模块链路断连
    }

    ExitSocket();

    m_bExit = true;
    m_bDeleteSelf = bDeleteSelf;

    //false:链路阻塞
    if (!m_bDeleteSelf)
    {
        FreeMemory();                                       //释放内存
        StopSocketIO();                                     //期望链路僵死可以激活,结果需验证
    }

    LOGGER_DEBUG(CLogController::getinstance(), "结束Sender对象: RModID="
        << GetModID(m_uiRemoteModuleID) << " RInsID="
        << GetInsID(m_uiRemoteModuleID) << " Ip="
        << m_strRemoteIP.c_str() << " Port="
        << m_usPort << " LModID="
        << GetModID(m_uiLocalModuleID) << " LInsID="
        << GetInsID(m_uiLocalModuleID) << " tid=" << m_szTid);
}

uint32_t CRemoteSender::GetLocalModuleID(void)
{
    return m_uiLocalModuleID;
}

void CRemoteSender::SetExitFlag(void)
{
    RefreshLinkStatus(false);
    m_bExit = true;

    LOGGER_DEBUG(CLogController::getinstance(), "退出Sender对象: ModID="
        << GetModID(m_uiRemoteModuleID) << " InsID="
        << GetInsID(m_uiRemoteModuleID) << " Ip="
        << m_strRemoteIP.c_str() << " Port=" << m_usPort);
}

void CRemoteSender::CloseSocket(void)
{
    try
    {
        LOGGER_DEBUG(CLogController::getinstance(), "Close socket. ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort);

        //关闭socket
        m_socket.close();
    }
    catch(const boost::system::system_error& e)
    {
        /*LOGGER_ERROR(CLogController::getinstance(), "Cancel socket asynchronous error. ModID="
            << GetModID(m_uiRemoteModuleID) << " InstID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << " Reason:" << e.what());*/
    }
    catch(...)
    {

    }
}

void CRemoteSender::ExitSocket(void)
{
    RefreshLinkStatus(false);                               //更新链路状态
    CloseSocket();
}

void CRemoteSender::CancelHeartTimer(void)
{
    try
    {
        // 取消心跳定时器
        m_timerHeart.cancel();
    }
    catch(const boost::system::system_error& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Cancel HeartBeat timer error. ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << " Reason:" << e.what());
    }
    catch(...)
    {
    }
}

void CRemoteSender::CancelConnectTimer(void)
{
    try
    {
        //取消连接定时器
        m_timerConnection.cancel();
    }
    catch(const boost::system::system_error& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Cancel Connection timer error. ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << " Reason:" << e.what());
    }
    catch(...)
    {
    }
}

void CRemoteSender::ExitIOThread(void)
{
    //停止IO
    if (m_bDeleteSelf)
    {
        StopSocketIO();
    }

    try
    {
        m_socketThread.interrupt();
        m_socketThread.join();
    }
    catch(const boost::system::error_code& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Exit thread失败 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << ". 原因: " << e.message());
    }
    catch(const boost::system::system_error& sysex)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Exit thread失败 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << ". 原因: " << sysex.what());
    }
    catch(...)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Exit thread失败 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port=" << m_usPort);
    }
}

void CRemoteSender::StopSocketIO(void)
{
    try
    {
        m_ios.stop();
    }
    catch(const boost::system::error_code& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "asio stop失败 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << ". 原因: " << e.message());
    }
    catch(const boost::system::system_error& sysex)
    {
        LOGGER_ERROR(CLogController::getinstance(), "asio stop失败 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << ". 原因: " << sysex.what());
    }
    catch(...)
    {
        LOGGER_ERROR(CLogController::getinstance(), "asio stop失败 ModID="
            << GetModID(m_uiRemoteModuleID) << " InsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port=" << m_usPort);
    }
}

void CRemoteSender::FreeMemory(void)
{
    uint64_t ulQueSize = m_msgQueue.ClearDeque();
    uint64_t ulHighQueSize = m_msgHighQueue.ClearDeque();

    LOGGER_DEBUG(CLogController::getinstance(), "内存释放: RModID="
            << GetModID(m_uiRemoteModuleID) << " RInsID="
            << GetInsID(m_uiRemoteModuleID) << " Ip="
            << m_strRemoteIP.c_str() << " Port="
            << m_usPort << " LModID="
            << GetModID(m_uiLocalModuleID) << " LInsID="
            << GetInsID(m_uiLocalModuleID) << " QueSize="
            << ulQueSize << " HighQueSize="
            << ulHighQueSize << " tid=" << m_szTid);
}
