#include "isq_receiver.h"
#include <boost/bind.hpp>
#include <boost/lexical_cast.hpp>

CRemoteReceiver::CRemoteReceiver(boost::asio::io_service& ios, CGServerMgr* pGServerMgr)
        : m_ios(ios)
        , m_socket(ios)
        , m_isRun(RUNING)
        , m_uiOffsetPos(0)
        , m_pGServerMgr(pGServerMgr)
        , m_bRet(true)
        , m_strRemoteIP("")
        , m_usPort(0)
        , m_uiUserID(0)
{
    m_pBuffer = (uint8_t*)LOG_MALLOC(MAX_BUFFER_SIZE+1);

    if (!m_pBuffer)
    {
        LOGGER_ERROR(CLogController::getinstance(), "malloc res fail");
        exit(1);
    }
}

CRemoteReceiver::~CRemoteReceiver(void)
{
    try
    {
        while(!m_MsgQueue.empty())
        {
            free(m_MsgQueue.front());
            m_MsgQueue.pop_front();
        }

        m_socket.close();
    }
    catch(const boost::system::system_error& ex)
    {
    }

    m_pGServerMgr->OffLine(m_uiUserID, (uint64_t)this);

    if (m_pBuffer)
    {
        free(m_pBuffer);
        m_pBuffer = NULL;
    }

    if (0==m_bProcExit)
    {
        LOGGER_DEBUG(CLogController::getinstance(),"远端到本地连接断开 UserID=" << m_uiUserID << " IP=" << m_strRemoteIP.c_str() << " port=" << m_usPort);
    }
}

// 启动异步消息接收
void CRemoteReceiver::Startup(void)
{
    //获取主机IP、端口
    GetSocketIPAndPort();

    LOGGER_DEBUG(CLogController::getinstance(), "远端到本地连接建立 IP=" << m_strRemoteIP.c_str() << " port=" << m_usPort);

    // 设置发送缓存大小
    SetSocketSendBuffSize(16 * 1024 * 1024);

    // 设置接收缓存大小
    SetSocketRecvBuffSize(4 * 1024 * 1024);

    // 设置Linger模式
    SetSocketLingerOption();

    if (false == (m_pGServerMgr->m_LinkHMap.insert(make_pair((uint64_t)this, this))).second)
    {
        LOGGER_ERROR(CLogController::getinstance(), "LinkHMap insert fail");

        m_isRun = EXITING;
        delete this;

        return;
    }

    boost::thread msgthread(boost::bind(&CRemoteReceiver::EnumMsg, this));
    m_thread.swap(msgthread);

    AsyncRead();
}

// 异步读取消息
void CRemoteReceiver::AsyncRead(void)
{
    uint32_t uiMaxBytes = MAX_BUFFER_SIZE - m_uiOffsetPos;
    uint8_t* pBuf = m_pBuffer + m_uiOffsetPos;

    m_socket.async_read_some(boost::asio::buffer(pBuf, uiMaxBytes)
        , boost::bind(&CRemoteReceiver::HandleAysncRead, this
        , boost::asio::placeholders::error
        , boost::asio::placeholders::bytes_transferred));
}

// 异步发送消息
int32_t CRemoteReceiver::AsyncWrite(NIMsg* pMsg)
{
    int  nRet = PROC_SUCCESS;

    if (!pMsg)
    {
        LOGGER_ERROR(CLogController::getinstance(), "AsyncWrite invalid parameter");
        return nRet;
    }

    char*     pBuf = (char*)pMsg;
    uint32_t  uiTotalLen = pMsg->Len;
    uint32_t  uiSendBytes = 0;

    while (uiSendBytes < uiTotalLen)
    {
        try
        {
            uint32_t uiBytes = (uint32_t)(m_socket.write_some(boost::asio::buffer(pBuf + uiSendBytes, uiTotalLen - uiSendBytes)));
            uiSendBytes += uiBytes;
        }
        catch(const boost::system::error_code& e)
        {
            LOGGER_ERROR(CLogController::getinstance(),"本地发送消息到远端错误 UserID="
                << m_uiUserID << " IP="
                << m_strRemoteIP.c_str() << " port="
                << m_usPort << ". 原因："<< e.message());
            nRet = PROC_FAILED;
            break;
        }
        catch(const boost::system::system_error& sysex)
        {
            LOGGER_ERROR(CLogController::getinstance(),"本地发送消息到远端错误 UserID="
                << m_uiUserID << " IP="
                << m_strRemoteIP.c_str() << " port="
                << m_usPort << ". 原因："<< sysex.what());
            nRet = PROC_FAILED;
            break;
        }
        catch(...)
        {
            LOGGER_ERROR(CLogController::getinstance(),"本地发送消息到远端错误 UserID="
                << m_uiUserID << " IP="
                << m_strRemoteIP.c_str() << " port="
                << m_usPort << ". 原因：未知");
            nRet = PROC_FAILED;
            break;
        }
    } // end while

    LOGGER_DEBUG(CLogController::getinstance(), "msg= "<< pMsg->Head.MsgID << " id=" << pMsg->Head.Sender );
    free(pMsg);
    pMsg=NULL;
    return nRet;
}

// 异步读取消息回调函数
void CRemoteReceiver::HandleAysncRead(const boost::system::error_code &e, size_t bytes_transferred)
{
    if (e)
    {
        LOGGER_DEBUG(CLogController::getinstance(), "HandleAysncRead error [delete this]:"
            << e.message() << " Queue Size:"
            << m_MsgQueue.size() << " UserID="
            << m_uiUserID << " IP="
            << m_strRemoteIP.c_str() << " port=" << m_usPort);
        m_isRun = EXITING;
        delete this;
    }
    else
    {
        try
        {
            m_bRet = ProcessMsg(bytes_transferred); // 派发消息
        }
        catch(...)
        {
            m_bRet = false;
            LOGGER_ERROR(CLogController::getinstance(), "捕获到ProcessMsg异常, UserID="
                << m_uiUserID << " IP=" << m_strRemoteIP.c_str() << " port=" << m_usPort);
        }

        if (EXITING == m_isRun || EXITED == m_isRun)
        {
            // 链路出错退出
            LOGGER_ERROR(CLogController::getinstance(), "Link exit [delete this]:"
                << e.message() << " Queue Size:"
                << m_MsgQueue.size() << " UserID="
                << m_uiUserID << " IP="
                << m_strRemoteIP.c_str() << " port=" << m_usPort);
            delete this;
        }
        else if (1==m_bProcExit)
        {
            // 正常退出
            LOGGER_ERROR(CLogController::getinstance(), "System exit [delete this]:"
                << e.message() << " Queue Size:"
                << m_MsgQueue.size() << " UserID="
                << m_uiUserID << " IP="
                << m_strRemoteIP.c_str() << " port=" << m_usPort);
            m_isRun = EXITING;
            delete this;
        }
        else if (m_bRet)
        {
            // 再次读取消息
            AsyncRead();
        }
        else
        {
            LOGGER_ERROR(CLogController::getinstance(), "Process msg error [delete this]. Queue size:"
                << m_MsgQueue.size() << " UserID="
                << m_uiUserID << " IP="
                << m_strRemoteIP.c_str() << " port=" << m_usPort);
            m_isRun = EXITING;
            delete this;
        }
    }
}

// 处理并派发消息
bool CRemoteReceiver::ProcessMsg(size_t bytes_transferred)
{
    uint32_t        uiOffset  = 0;
    uint32_t        uiEndPos  = (uint32_t)(m_uiOffsetPos + bytes_transferred);

    // 循环拆分消息，直到消息长度不足，拆分到最后时如果还有剩余数据, 将其移动到缓冲区头部
    while (EXITING != m_isRun && EXITED != m_isRun)
    {
        uint8_t*    pBuffer = m_pBuffer + uiOffset;     // 当前正在处理的消息开始位置
        uint32_t    uiLeftSize = uiEndPos - uiOffset;   // 剩余尚未处理的缓冲区字节数

        NIMsg*       pMsg = (NIMsg*)pBuffer;
        uint32_t    uiActMsgLen =   pMsg->Len;

        // 校检
        if ((uiLeftSize >= sizeof(NIMsg)) && (uiActMsgLen > MAX_BUFFER_SIZE))
        {
            LOGGER_DEBUG(CLogController::getinstance(), " 接收消息长度="
                << uiActMsgLen << " 超过最大长度="
                << MAX_BUFFER_SIZE << " UserID="
                << m_uiUserID << " IP="
                << m_strRemoteIP.c_str() << " port=" << m_usPort);

            m_uiOffsetPos = 0;
            return false;
        }
        else if (uiLeftSize < sizeof(NIMsg) || uiLeftSize < uiActMsgLen)
        {
            LOGGER_DEBUG(CLogController::getinstance(), "uiLeftSize="<<uiLeftSize<<" len="<<uiActMsgLen);
            LOGGER_DEBUG(CLogController::getinstance(), "剩余的长度小于消息的实际长度; 判断时，第一个条件和第二个条件并不冲突，因为此时可能消息头部并未收全");
            if (uiLeftSize && uiOffset)
            {
                memmove(m_pBuffer, pBuffer, uiLeftSize);
            }
            m_uiOffsetPos = uiLeftSize;
            break;
        }

        if (  MSG_FLAG_VAL != pMsg->Flag  )
        {
            LOGGER_DEBUG(CLogController::getinstance(), "接收到非法消息 消息长度="
                << uiActMsgLen << " UserID="
                << m_uiUserID << "MsgFlag="
                << pMsg->Flag << "Sender="
                << pMsg->Head.Sender << " IP="
                << m_strRemoteIP.c_str() << " port=" << m_usPort);

            return false;
        }

        if (  INTERFACE_VERSION != pMsg->Head.Version  )
        {
            LOGGER_DEBUG(CLogController::getinstance(), "版本错误 消息="
                << pMsg->Head.Version << " UserID="
                << m_uiUserID << " MsgFlag="
                << pMsg->Flag << " Sender="
                << pMsg->Head.Sender << " IP="
                << m_strRemoteIP.c_str() << " port=" << m_usPort);

            return false;
        }

        switch (pMsg->Head.MsgID)
        {
        case MSG_HEART_REQUEST:
            HandleHeartResponse(pMsg);
            break;

        default:
            {
                uint32_t  uiTotalLen = (uint32_t)(sizeof(CEPMsg) + uiActMsgLen + 1);
                CEPMsg*   pPtr = (CEPMsg*)LOG_MALLOC(uiTotalLen);

                if (!pPtr)
                {
                    LOGGER_ERROR(CLogController::getinstance(), "ProcessMsg malloc res fail");
                    return false;
                }

                memset(pPtr, 0, uiTotalLen);

                memcpy(pPtr->Buf, pBuffer, uiActMsgLen);

                pPtr->Sender = pMsg->Head.Sender;
                pPtr->MsgID = pMsg->Head.MsgID;
                pPtr->UserData = (uint64_t)this;
                pPtr->PayloadLen = (uint32_t)(uiTotalLen-sizeof(CMsg));
                pPtr->Checksum = pPtr->PayloadLen^pPtr->MsgID; // 保留

                if (PROC_FAILED == (uint32_t)(m_pGServerMgr->DispatchMsg(pPtr)))
                {
                    free(pPtr);
                    pPtr=NULL;
                    return false;
                }
            }
            break;
        } // end switch

        uiOffset += uiActMsgLen;
    } // end while

    return true;
}

void CRemoteReceiver::HandleHeartResponse(const boost::system::error_code& e, size_t bytes_transferred, NIMsg* pMsg)
{
    if (bytes_transferred)
    {
        ;
    }

    if (e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Can't send heart response msg. UserID="
            << m_uiUserID << " IP="
            << m_strRemoteIP.c_str() << " port="
            << m_usPort << ". Reason : " << e.message());
        m_isRun = EXITING;
    }

    free((void*)pMsg);
    pMsg=NULL;
}

void CRemoteReceiver::HandleHeartResponse(NIMsg* pMsg)
{
    if (pMsg)
    {
        ;
    }

    uint32_t uiTotalLen = sizeof(NIMsg);
    NIMsg*    pResponse = (NIMsg*)LOG_MALLOC(uiTotalLen);

    if (!pResponse)
    {
        LOGGER_ERROR(CLogController::getinstance(), "HandleHeartResponse malloc res fail");
        return;
    }

    LOGGER_DEBUG(CLogController::getinstance(), "HeartResponse: "
        << m_uiUserID << " IP="
        << m_strRemoteIP.c_str() << " port="
        << m_usPort << " QueSize=" << m_MsgQueue.size());

    pResponse->Flag = MSG_FLAG_VAL;
    pResponse->EncryptType = RC4_E;
    pResponse->Len = sizeof(NIMsg);
    pResponse->Head.Source = MSF_GSERVER;
    pResponse->Head.Version = INTERFACE_VERSION;
    pResponse->Head.MsgID = MSG_HEART_REQUEST;

    boost::asio::async_write(m_socket,
        boost::asio::buffer(pResponse, uiTotalLen),
        boost::bind(&CRemoteReceiver::HandleHeartResponse,
        this, placeholders::error,
        placeholders::bytes_transferred, pResponse));
}

string CRemoteReceiver::GetRemoteIP(void)
{
    return m_strRemoteIP ;
}

uint32_t CRemoteReceiver::GetRemotePort(void)
{
    return m_usPort ;
}

int32_t CRemoteReceiver::EnumMsg(void)
{
    LOGGER_DEBUG(CLogController::getinstance(), "创建玩家IP["<< m_strRemoteIP<<"]发送消息线程");

    NIMsg* pMsg = NULL;

    while (RUNING == m_isRun && 0==m_bProcExit)
    {
        pMsg = NULL;

        if (!m_MsgQueue.empty())
        {
            pMsg = m_MsgQueue.front();
            m_MsgQueue.pop_front();
        }

        if (pMsg)
        {
            // 发送
            AsyncWrite(pMsg);

        }
        else
        {
            usleep(1000);
        }

    } // while

/*  m_MutexSend.lock();
    while(!m_MsgQueue.empty())
    {
        free(m_MsgQueue.front());
        m_MsgQueue.pop_front();
    }
    m_MutexSend.unlock();*/

    m_isRun = EXITED;

    //delete this;   // add

    return PROC_SUCCESS;
}

int32_t CRemoteReceiver::PushMsg(NIMsg* pMsg, int32_t iPriority)
{
    if (RUNING != m_isRun || 1==m_bProcExit )
    {
        free(pMsg);
        pMsg=NULL;
        return PROC_FAILED;
    }


    if(iPriority)
    {
        m_MsgQueue.push_front(pMsg);
    }
    else
    {
        m_MsgQueue.push_back(pMsg);
    }


    return PROC_SUCCESS;
}

bool CRemoteReceiver::GetSocketIPAndPort(void)
{
    try
    {
        m_strRemoteIP = m_socket.remote_endpoint().address().to_string();
        m_usPort      = m_socket.remote_endpoint().port();
    }
    catch(const boost::system::error_code& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "获取链路信息异常 IP="
            << m_strRemoteIP.c_str() << " port="
            << m_usPort << ". 原因: " << e.message());

        return false;
    }
    catch(const boost::system::system_error& sysex)
    {
        LOGGER_ERROR(CLogController::getinstance(), "获取链路信息异常 IP="
            << m_strRemoteIP.c_str() << " port="
            << m_usPort << ". 原因: " << sysex.what());

        return false;
    }
    catch(...)
    {
        LOGGER_ERROR(CLogController::getinstance(), "获取链路信息异常 IP="
            << m_strRemoteIP.c_str() << " port=" << m_usPort);

        return false;
    }

    return true;
}

bool CRemoteReceiver::SetSocketSendBuffSize(uint32_t uiSize)
{
    try
    {
        boost::asio::socket_base::send_buffer_size sendoption(uiSize);
        m_socket.set_option(sendoption);
    }
    catch(const boost::system::error_code& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "设置socket send buffer size异常 IP="
            << m_strRemoteIP.c_str() << " port="
            << m_usPort << ". 原因: " << e.message());

        return false;
    }
    catch(const boost::system::system_error& sysex)
    {
        LOGGER_ERROR(CLogController::getinstance(), "设置socket send buffer size异常 IP="
            << m_strRemoteIP.c_str() << " port="
            << m_usPort << ". 原因: " << sysex.what());

        return false;
    }
    catch(...)
    {
        LOGGER_ERROR(CLogController::getinstance(), "设置socket send buffer size异常 IP="
            << m_strRemoteIP.c_str() << " port=" << m_usPort);

        return false;
    }

    return true;
}

bool CRemoteReceiver::SetSocketRecvBuffSize(uint32_t uiSize)
{
    try
    {
        boost::asio::socket_base::receive_buffer_size receiveoption(uiSize);
        m_socket.set_option(receiveoption);
    }
    catch(const boost::system::error_code& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "设置socket recv buffer size异常 IP="
            << m_strRemoteIP.c_str() << " port="
            << m_usPort << ". 原因: " << e.message());

        return false;
    }
    catch(const boost::system::system_error& sysex)
    {
        LOGGER_ERROR(CLogController::getinstance(), "设置socket recv buffer size异常 IP="
            << m_strRemoteIP.c_str() << " port="
            << m_usPort << ". 原因: " << sysex.what());

        return false;
    }
    catch(...)
    {
        LOGGER_ERROR(CLogController::getinstance(), "设置socket recv buffer size异常 IP="
            << m_strRemoteIP.c_str() << " port=" << m_usPort);

        return false;
    }

    return true;
}

bool CRemoteReceiver::SetSocketLingerOption(void)
{
    try
    {
        boost::asio::socket_base::linger lingeroption(true, 0);
        m_socket.set_option(lingeroption);
    }
    catch(const boost::system::error_code& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "设置socket linger option异常 IP="
            << m_strRemoteIP.c_str() << " port="
            << m_usPort << ". 原因: " << e.message());

        return false;
    }
    catch(const boost::system::system_error& sysex)
    {
        LOGGER_ERROR(CLogController::getinstance(), "设置socket linger option异常 IP="
            << m_strRemoteIP.c_str() << " port="
            << m_usPort << ". 原因: " << sysex.what());

        return false;
    }
    catch(...)
    {
        LOGGER_ERROR(CLogController::getinstance(), "设置socket linger option异常 IP="
            << m_strRemoteIP.c_str() << " port=" << m_usPort);

        return false;
    }

    return true;
}
