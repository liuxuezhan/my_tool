// ------------------------------
#include "isq_gserver_mgr.h"

CGServerMgr::~CGServerMgr(void)
{
    delete m_DispatchMgr;
    Stop();

    try
    {
        m_hSockThread.interrupt();
    }
    catch(const boost::system::error_code& e)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Exit thread失败. 原因: " << e.message());
    }
    catch(const boost::system::system_error& sysex)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Exit thread失败. 原因: " << sysex.what());
    }
    catch(...)
    {
        LOGGER_ERROR(CLogController::getinstance(), "Exit thread失败");
    }

    LinkIter it;
    while( (it = m_LinkHMap.begin()) != m_LinkHMap.end() )
    {
        CRemoteReceiver* tp = it->second;
        delete tp;
        m_LinkHMap.erase(it);
    }

    m_ios.stop();
    m_acceptor.close();
    if (m_pReceiver)
    {
        delete m_pReceiver;
        m_pReceiver = NULL;
    }
    DBClose(m_l);
}

// 模块启动
bool CGServerMgr::OnStart( void )
{
    printf("OnStart enter\n");

    // 检查日志文件目录./log是否存在 不存在创建
    struct stat entryInfo;
    if (stat("./log", &entryInfo) < 0)
    {
        mkdir("./log", 0755);
    }

    string     szRunPath;
    char       szPath[MAX_PATH] = {0};



    // 启动消息接收服务器
    if (!StartServer((uint16_t)m_CfgInfo->ListenPort))
    {
        // 根据端口获取进程号
        uint32_t    uiProcNo = 0;
        if (!GetProcNoByPort(m_CfgInfo->ListenPort, uiProcNo))
        {
            LOGGER_ERROR(CLogController::getinstance(), "启动消息接收服务器失败");
            return false;
        }

        // 根据进程号获取进程名
        char szProcName[256] = {0};
        if (!GetProcNameByProcNo(uiProcNo, szProcName))
        {
            LOGGER_ERROR(CLogController::getinstance(), "启动消息接收服务器失败!端口[" << m_CfgInfo->ListenPort << "]被进程[pid=" << uiProcNo << "]绑定");
            return false;
        }

        LOGGER_ERROR(CLogController::getinstance(), "启动消息接收服务器失败!端口[" << m_CfgInfo->ListenPort << "]被进程[" << szProcName << "][pid=" << uiProcNo << "]绑定");
        return false;
    }

    LOGGER_DEBUG(CLogController::getinstance(), "启动消息接收服务器成功");

    // socket启动
    boost::thread SockThread(boost::bind(&boost::asio::io_service::run, &m_ios));
    SockThread.detach();
    m_hSockThread.swap(SockThread);

   for (int i=0;i<m_DispatchMgr->m_ucWriterNum;i++)
   {
       LOGGER_INFO(CLogController::getinstance(), "线程池ID[" << m_DispatchMgr->m_pWrites[i]->m_pid << "] ");
   }
    return true;
}

// 未用，发送消息失败后的处理
int32_t CGServerMgr::ProcSysMsg(CMsg* pMsg, int32_t iPriority)
{
    assert(pMsg);

    if (1 == iPriority)
    {
        // 消息转发
        if (PROC_FAILED == (uint32_t)DispatchMsg(pMsg, iPriority))
        {
            return PROC_FAILED;
        }
        return PROC_HOLD;
    }

    if (1==m_bProcExit)
    {
        return PROC_FAILED;
    }

    int32_t iRet = PROC_NO;

    // Sender 相关 预留
    switch(pMsg->MsgID)
    {
    case MSG_MOD_LINK_BREAK:                            // 模块链路断开

    case MSG_MOD_LINK_RECONN:                           // 模块链路重连
        // 待续
        break;
    default:
        break;
    }

    return iRet;
}

// 收到消息
int32_t CGServerMgr::DispatchMsg( CMsg* pMsg, int32_t iPriority, uint8_t bBroadcast )
{
    if (iPriority) { ;}

    if (1==m_bProcExit)
    {
        // 防止退出程序时报错
        free((void*)pMsg);
        pMsg = NULL;
        return PROC_SUCCESS;
    }

    switch(bBroadcast)
    {
    case BROADCAST:                                     // 后台广播
        break;
    case BROADCASTFRONT :                               // 前台广播
        break;
    case BROADCASTALL :                                 // 全局广播
        break;
    case BROADCASTINST :                                // 模块实例广播
        break;
        #if 0//cpu空闲时开线程
    case MSG1_CS_PLAYER_INFO :
        {
            //写入优先链路写数据库
            pMsg->Receiver = 1;//子线程ID
            pMsg->UserData2 = (uint64_t)this;

            bool bRet = m_DispatchMgr->Write(pMsg);
            if (!bRet)
            {
                LOGGER_ERROR(CLogController::getinstance(), "Dispatch the message processing bottlenecks, optimize server");
                return PROC_FAILED;
            }

            return PROC_SUCCESS;

        }
        break;
        #endif
    default :
    {
        // 写入主线程队列
        m_MsgQueue.push_back(pMsg);
        return PROC_SUCCESS;
    }

    break;
    }// end switch

    return PROC_SUCCESS;
}

// 启动消息服务器
bool CGServerMgr::StartServer( uint16_t usPort )
{
    boost::system::error_code ec;

    // 打开socket
    tcp::endpoint* pendpoint = NULL;

    if (strlen(m_CfgInfo->BindIP) >= 7)
    {
        pendpoint = new tcp::endpoint(boost::asio::ip::address::from_string(m_CfgInfo->BindIP), usPort);
    }
    else
    {
        pendpoint = new tcp::endpoint(tcp::v4(), usPort);
    }

    m_acceptor.open(pendpoint->protocol());

    boost::asio::socket_base::reuse_address option(true);
    m_acceptor.set_option(option);

    // 绑定端口
    m_acceptor.bind(*pendpoint, ec);
    if (ec)
    {
        LOGGER_ERROR(CLogController::getinstance(), "创建Socket服务器失败:"  << *pendpoint << "端口["<<usPort << "]被占用.原因(bind):" << ec.message());
        delete pendpoint;
        return false;
    }

    // 侦听
    m_acceptor.listen(boost::asio::socket_base::max_connections, ec);
    if (ec)
    {
        LOGGER_ERROR(CLogController::getinstance(), "创建Socket服务器失败:"  << *pendpoint << " 原因(listen):" << ec.message());
        delete pendpoint;
        return false;
    }

    // 启动异步接受客户端连接
    AsyncAccept();
    delete pendpoint;
    return true;
}

// 异步接受客户端连接
void CGServerMgr::AsyncAccept( void )
{
    if (1==m_bProcExit)
    {
        return; // 不在接受链路连接
    }

    CRemoteReceiver* pReceiver = new CRemoteReceiver(m_ios, this); //一个客户端建立一个对象
    if (pReceiver)
    {
        m_pReceiver = pReceiver;
        m_acceptor.async_accept(pReceiver->socket(), boost::bind(&CGServerMgr::HandleAccept, this, boost::asio::placeholders::error, pReceiver));
    }
}

// 异步接受客户端连接回调函数
void CGServerMgr::HandleAccept(const boost::system::error_code &e, CRemoteReceiver* pReceiver)
{
    if (e)
    {
        if (0==m_bProcExit)
        {
            LOGGER_ERROR(CLogController::getinstance(), "创建客户端连接失败,原因:"   << e.message());
        }

        delete pReceiver;
    }
    else
    {
        pReceiver->Startup();
    }

    AsyncAccept();
}

void CGServerMgr::OnStop( void )
{

}

NIMsg* CGServerMgr::OnLogin( int *pid,char* pPkt )
{
    pPkt += sizeof(NIMsg);
    cs_login* pInfo = (cs_login*)pPkt;

    /*
    CEncrypt rc(RC4_KEY);
    rc.rc4_crypt((unsigned char*)&pInfo,sizeof(cs_login));
*/

    /*调用lua函数处理消息并返回*/
      LOG_LUA_GET(m_l, "msg_to_lua");

      lua_pushnumber(m_l, 0);
      lua_pushstring(m_l, __func__);
      lua_newtable(m_l);
      {
          lua_pushnumber(m_l, 1);
          lua_pushstring(m_l, pInfo->name);
          lua_settable(m_l, -3);

          lua_pushnumber(m_l, 2);
          lua_pushstring(m_l, pInfo->pwd);
          lua_settable(m_l, -3);
      }

      if (lua_pcall(m_l, 3, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
          LOGGER_ERROR(CLogController::getinstance(), lua_tostring(m_l,-1));
          lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
           return NULL;
      }
     *pid = lua_tonumber(m_l, -1);
     lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

    NIMsg* pRegResp = InitMsg( sizeof(sc_login));
    if (!pRegResp) { return NULL; }
    char*   pPtr = (char*)pRegResp;
    pPtr += sizeof(NIMsg);

    ((sc_login*)pPtr)->id = *pid;

    return pRegResp;
}

NIMsg* CGServerMgr::OnRegister( int id,char* pPkt )
{
    pPkt += sizeof(NIMsg);
    cs_reg* pInfo = (cs_reg*)pPkt;

    /*
   CEncrypt rc(RC4_KEY);
   rc.rc4_crypt((unsigned char*)&pInfo,sizeof(cs_reg));
*/
    /*调用lua函数处理消息并返回*/
      LOG_LUA_GET(m_l, "msg_to_lua");
      lua_pushnumber(m_l, id);
      lua_pushstring(m_l, __func__);
      lua_newtable(m_l);
      {
          lua_pushnumber(m_l, 1);
          lua_pushstring(m_l, pInfo->name);
          lua_settable(m_l, -3);

           lua_pushnumber(m_l, 2);
          lua_pushstring(m_l, pInfo->pwd);
          lua_settable(m_l, -3);

          lua_pushnumber(m_l, 3);
          lua_pushnumber(m_l, pInfo->nation);
          lua_settable(m_l, -3);

          lua_pushnumber(m_l, 4);
          lua_pushstring(m_l, pInfo->id);
          lua_settable(m_l, -3);
      }

      if (lua_pcall(m_l, 3, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
          LOGGER_ERROR(CLogController::getinstance(), lua_tostring(m_l,-1));
          lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

          return NULL;
      }

    NIMsg* pRegResp = InitMsg( sizeof(sc_reg));
    if (!pRegResp) { return NULL; }
    char*   pPtr = (char*)pRegResp;
    pPtr += sizeof(NIMsg);

    ((sc_reg*)pPtr)->id = lua_tonumber(m_l, -1);

    lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
    return pRegResp;
}

void lua_role_push( lua_State* m_l, char* pi)
{
    msg_role* pt = (msg_role*)pi;
    lua_pushstring(m_l, "id" );
    lua_pushnumber(m_l, pt->id );
    lua_settable(m_l, -3);

    lua_pushstring(m_l, "lv" );
    lua_pushnumber(m_l, pt->lv );
    lua_settable(m_l, -3);

    lua_pushstring(m_l, "str" );
    lua_pushnumber(m_l, pt->str );
    lua_settable(m_l, -3);

    lua_pushstring(m_l, "dex" );
    lua_pushnumber(m_l, pt->dex );
    lua_settable(m_l, -3);

    lua_pushstring(m_l, "spec" );
    lua_pushnumber(m_l, pt->spec );
    lua_settable(m_l, -3);

    lua_pushstring(m_l, "task1" );
    lua_pushnumber(m_l, pt->task.uId_1 );
    lua_settable(m_l, -3);

    lua_pushstring(m_l, "task2" );
    lua_pushnumber(m_l, pt->task.uId_2 );
    lua_settable(m_l, -3);

    lua_pushstring(m_l, "task3" );
    lua_pushnumber(m_l, pt->task.uId_3 );
    lua_settable(m_l, -3);
}

NIMsg* CGServerMgr::MSG1_CS_PLAYER_INFO_fun(int id,char* pPkt)//保存玩家数据
{
      pPkt += sizeof(NIMsg);
      cs_player_info* pInfo = (cs_player_info*)pPkt;

      /*调用lua函数处理消息并返回*/
      LOG_LUA_GET(m_l, "msg_to_lua");
      lua_pushnumber(m_l, id);
      lua_pushstring(m_l, __func__);

      lua_newtable(m_l);

      lua_pushstring(m_l, "distance");
      lua_pushnumber(m_l, pInfo->distance);
      lua_settable(m_l, -3);

      #if 0
      lua_pushstring(m_l, "money");
      lua_pushnumber(m_l, pInfo->money);
      lua_settable(m_l, -3);

      lua_pushstring(m_l, "diamond");
      lua_pushnumber(m_l, pInfo->diamond);
      lua_settable(m_l, -3);

      lua_pushstring(m_l, "chaper");
      lua_pushnumber(m_l, pInfo->chaper);
      lua_settable(m_l, -3);

      char *pi= pPkt + sizeof(cs_player_info);

      if (pInfo->role_num!=0)
      {
          lua_pushstring(m_l, "role");
          lua_newtable(m_l);

          for (int i=0;i<pInfo->role_num ;i++)
          {
              lua_role_push(m_l,pi);
              pi= pi + sizeof(msg_role);
          }
          lua_settable(m_l, -3);
      }

      if (pInfo->pet_num!=0)
      {
          lua_pushstring(m_l, "pet");
          lua_newtable(m_l);

          for (int i=0;i<pInfo->pet_num ;i++)
          {
            msg_pet* pt = (msg_pet*)pi;
            lua_pushstring(m_l, "id" );
            lua_pushnumber(m_l, pt->id );
            lua_settable(m_l, -3);

            lua_pushstring(m_l, "lv" );
            lua_pushnumber(m_l, pt->lv );
            lua_settable(m_l, -3);

            pi= pi + sizeof(msg_pet);
          }
          lua_settable(m_l, -3);
      }

      if (pInfo->equip_num!=0)
      {
          lua_pushstring(m_l, "equip");
          lua_newtable(m_l);

          for (int i=0;i<pInfo->equip_num ;i++)
          {
            msg_equip* pt = (msg_equip*)pi;
            lua_pushstring(m_l, "id" );
            lua_pushnumber(m_l, pt->id );
            lua_settable(m_l, -3);

            lua_pushstring(m_l, "lv" );
            lua_pushnumber(m_l, pt->lv );
            lua_settable(m_l, -3);

            lua_pushstring(m_l, "use" );
            lua_pushnumber(m_l, pt->use );
            lua_settable(m_l, -3);

            pi= pi + sizeof(msg_equip);
          }
          lua_settable(m_l, -3);
      }

      if (pInfo->item_num!=0)
      {
          lua_pushstring(m_l, "item");
          lua_newtable(m_l);

          for (int i=0;i<pInfo->item_num ;i++)
          {
            msg_item* pt = (msg_item*)pi;
            lua_pushstring(m_l, "id" );
            lua_pushnumber(m_l, pt->id );
            lua_settable(m_l, -3);

            lua_pushstring(m_l, "num" );
            lua_pushnumber(m_l, pt->num );
            lua_settable(m_l, -3);

            pi= pi + sizeof(msg_item);
          }
          lua_settable(m_l, -3);
      }

      if (pInfo->skill_num!=0)
      {
          lua_pushstring(m_l, "skill");
          lua_newtable(m_l);

          for (int i=0;i<pInfo->skill_num ;i++)
          {
            msg_skill* pt = (msg_skill*)pi;
            lua_pushstring(m_l, "id" );
            lua_pushnumber(m_l, pt->id );
            lua_settable(m_l, -3);

            lua_pushstring(m_l, "lv" );
            lua_pushnumber(m_l, pt->lv );
            lua_settable(m_l, -3);

            pi= pi + sizeof(msg_skill);
          }
          lua_settable(m_l, -3);
      }

      if (pInfo->suc_num!=0)
      {
          lua_pushstring(m_l, "suc");
          lua_newtable(m_l);

          for (int i=0;i<pInfo->suc_num ;i++)
          {
            msg_suc* pt = (msg_suc*)pi;
            lua_pushstring(m_l, "id" );
            lua_pushnumber(m_l, pt->id );
            lua_settable(m_l, -3);

            lua_pushstring(m_l, "value" );
            lua_pushnumber(m_l, pt->value );
            lua_settable(m_l, -3);

            pi= pi + sizeof(msg_suc);
          }
          lua_settable(m_l, -3);
      }
#endif
      if (lua_pcall(m_l, 3, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
          LOGGER_ERROR(CLogController::getinstance(), lua_tostring(m_l,-1));
      }

    NIMsg* pRegResp = InitMsg( sizeof(char));
    if (!pRegResp) { return NULL ; }
    char*   pPtr = (char*)pRegResp;
    pPtr += sizeof(NIMsg);
    *pPtr=1;

    lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
    return pRegResp;
}

NIMsg* CGServerMgr::MSG1_CS_GET_OTHER_PLAYER_fun(int id,char* pPkt )//获取其他玩家数据
{
    int  num = ((NIMsg*)(pPkt))->Head.num;

    pPkt += sizeof(NIMsg);

      /*调用lua函数处理消息并返回*/
      LOG_LUA_GET(m_l, "msg_to_lua");
      lua_pushnumber(m_l, id);
      lua_pushstring(m_l, __func__);
      lua_newtable(m_l);

      for (int i=1;i<num+1;i++)
      {
          cs_get_player_info* pInfo = (cs_get_player_info*)pPkt;
          lua_pushnumber(m_l, i);
          lua_pushstring(m_l, pInfo->name);
          lua_settable(m_l, -3);
          pPkt += sizeof(cs_get_player_info);
      }

      if (lua_pcall(m_l, 3, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
           LOGGER_ERROR(CLogController::getinstance(), lua_tostring(m_l,-1));
           lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

            return NULL;
      }

    NIMsg* pRegResp = InitMsg( sizeof(sc_get_player_info)*num);
    if (!pRegResp) { return NULL; }
    char*   pPtr = (char*)pRegResp;
    pPtr += sizeof(NIMsg);

    int idx = lua_gettop(m_l);
    lua_pushnil(m_l);
    while (lua_next(m_l, idx) != 0)
    {
        if (lua_type(m_l, -1) == LUA_TSTRING)
        {
             lua_tostring(m_l, -1);
        }
        else if (lua_type(m_l, -1) == LUA_TNUMBER)
        {
            ((sc_get_player_info*)pPtr)->distance = lua_tonumber(m_l, -1);
            pPtr += sizeof(sc_get_player_info);
        }
        else if (lua_type(m_l, -1) == LUA_TTABLE)
        {

        }
        else
        {
        }
        //移除 'value' ；保留 'key' 做下一次迭代
        lua_pop(m_l, 1);
    }

    lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

    return pRegResp;
}

void lua_role_to1( lua_State* m_l, char* pi)
{
    int idx = lua_gettop(m_l);
    lua_pushnil(m_l);
    while (lua_next(m_l, idx) != 0)
    {
        if (lua_type(m_l, -2) == LUA_TSTRING)
        {
            if (strcmp( lua_tostring(m_l, -2),"lv")==0)
            {
                ((msg_role*)pi)->lv = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"str")==0)
            {
                ((msg_role*)pi)->str = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"dex")==0)
            {
                ((msg_role*)pi)->dex = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"spec")==0)
            {
                ((msg_role*)pi)->spec = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"task1")==0)
            {
                ((msg_role*)pi)->task.uId_1 = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"task2")==0)
            {
                ((msg_role*)pi)->task.uId_2 = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"task3")==0)
            {
                ((msg_role*)pi)->task.uId_3 = lua_tonumber(m_l, -1);
            }
        }
        lua_pop(m_l, 1);
    }
}
void lua_role_to( lua_State* m_l, char* pi)
{
    int idx = lua_gettop(m_l);
    lua_pushnil(m_l);
    while (lua_next(m_l, idx) != 0)
    {
       ((msg_role*)pi)->id = lua_tonumber(m_l, -2);
       lua_role_to1(m_l,pi);
       lua_pop(m_l, 1);
       pi += sizeof(msg_role);
    }
}

void lua_pet_to1( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
        if (lua_type(L, -2) == LUA_TSTRING)
        {
            if (strcmp( lua_tostring(L, -2),"lv")==0)
            {
                ((msg_pet*)pi)->lv = lua_tonumber(L, -1);
            }
        }
        lua_pop(L, 1);
    }
}

void lua_pet_to( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
       ((msg_pet*)pi)->id = lua_tonumber(L, -2);
       lua_pet_to1(L,pi);
       lua_pop(L, 1);
       pi += sizeof(msg_pet);
    }
}

void lua_item_to1( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
        if (lua_type(L, -2) == LUA_TSTRING)
        {
            if (strcmp( lua_tostring(L, -2),"num")==0)
            {
                ((msg_item*)pi)->num = lua_tonumber(L, -1);
            }
        }
        lua_pop(L, 1);
    }
}

void lua_item_to( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
       ((msg_item*)pi)->id = lua_tonumber(L, -2);
       lua_item_to1(L,pi);
       lua_pop(L, 1);
       pi += sizeof(msg_item);
    }
}

void lua_equip_to1( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
        if (lua_type(L, -2) == LUA_TSTRING)
        {
            if (strcmp( lua_tostring(L, -2),"lv")==0)
            {
                ((msg_equip*)pi)->lv = lua_tonumber(L, -1);
            }
            else if (strcmp( lua_tostring(L, -2),"type")==0)
            {
                ((msg_equip*)pi)->type = lua_tonumber(L, -1);
            }
            else if (strcmp( lua_tostring(L, -2),"use")==0)
            {
                ((msg_equip*)pi)->use = lua_tonumber(L, -1);
            }
        }
        lua_pop(L, 1);
    }
}

void lua_equip_to( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
       ((msg_equip*)pi)->id = lua_tonumber(L, -2);
       lua_equip_to1(L,pi);
       lua_pop(L, 1);
       pi += sizeof(msg_equip);
    }
}

void lua_skill_to1( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
        if (lua_type(L, -2) == LUA_TSTRING)
        {
            if (strcmp( lua_tostring(L, -2),"lv")==0)
            {
                ((msg_skill*)pi)->lv = lua_tonumber(L, -1);
            }
        }
        lua_pop(L, 1);
    }
}

void lua_skill_to( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
       ((msg_skill*)pi)->id = lua_tonumber(L, -2);
       lua_skill_to1(L,pi);
       lua_pop(L, 1);
       pi += sizeof(msg_skill);
    }
}

void lua_suc_to1( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
        if (lua_type(L, -2) == LUA_TSTRING)
        {
            if (strcmp( lua_tostring(L, -2),"value")==0)
            {
                ((msg_suc*)pi)->value = lua_tonumber(L, -1);
            }
        }
        lua_pop(L, 1);
    }
}

void lua_suc_to( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
       ((msg_suc*)pi)->id = lua_tonumber(L, -2);
       lua_suc_to1(L,pi);
       lua_pop(L, 1);
       pi += sizeof(msg_suc);
    }
}

void lua_order_to( lua_State* L, char* pi)
{
    int idx = lua_gettop(L);
    lua_pushnil(L);
    while (lua_next(L, idx) != 0)
    {
        if (strcmp( lua_tostring(L, -2),"name")==0)
        {
            memcpy(((sc_get_player_order*)pi)->player.name, lua_tostring(L, -1),USER_NAME_LEN);
        }
        else if(strcmp( lua_tostring(L, -2),"distance")==0)
        {
            ((sc_get_player_order*)pi)->distance = lua_tonumber(L, -1);
        }
        else if(strcmp( lua_tostring(L, -2),"nation")==0)
        {
            ((sc_get_player_order*)pi)->player.nation = lua_tonumber(L, -1);
        }
        else if(strcmp( lua_tostring(L, -2),"id")==0)
        {
            ((sc_get_player_order*)pi)->player.id = lua_tonumber(L, -1);
        }
        lua_pop(L, 1);
    }
}

NIMsg* CGServerMgr::MSG1_CS_GET_PLAYER_INFO_fun(int id,char* pPkt )//获取自己数据
{
    pPkt += sizeof(NIMsg);

    /*调用lua函数处理消息并返回*/
    LOG_LUA_GET(m_l, "msg_to_lua");
    lua_pushnumber(m_l, id);
    lua_pushstring(m_l, __func__);
    lua_newtable(m_l);

    if (lua_pcall(m_l, 3, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
    {
       LOGGER_ERROR(CLogController::getinstance(), lua_tostring(m_l,-1));
       lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

        return NULL;
    }

    cs_player_info pp;
    memset(&pp,0,sizeof(pp));

    #if 0

    //获取数量
    int idx = lua_gettop(m_l);
    lua_pushnil(m_l);
    while (lua_next(m_l, idx) != 0)
    {
        if (lua_type(m_l, -2) == LUA_TSTRING)
        {
            if (memcmp( lua_tostring(m_l, -2),"distance",strlen("distance"))==0)
            {
                pp.distance = lua_tonumber(m_l, -1);
            }
            else if (memcmp( lua_tostring(m_l, -2),"money",strlen("money"))==0)
            {
                pp.money = lua_tonumber(m_l, -1);
            }
            else if (memcmp( lua_tostring(m_l, -2),"diamond",strlen("diamond"))==0)
            {
                pp.diamond = lua_tonumber(m_l, -1);
            }
            else if (memcmp( lua_tostring(m_l, -2),"chaper",strlen("chaper"))==0)
            {
                pp.chaper = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"role_num")==0)
            {
                pp.role_num = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"pet_num")==0)
            {
                pp.pet_num = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"equip_num")==0)
            {
                pp.equip_num = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"item_num")==0)
            {
                pp.item_num = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"skill_num")==0)
            {
                pp.skill_num = lua_tonumber(m_l, -1);
            }
            else if (strcmp( lua_tostring(m_l, -2),"suc_num")==0)
            {
                pp.suc_num = lua_tonumber(m_l, -1);
            }
        }
        //移除 'value' ；保留 'key' 做下一次迭代
        lua_pop(m_l, 1);
    }

    //分配空间加载数据
    int len=sizeof(cs_player_info) +sizeof(msg_role)*pp.role_num\
                                    +sizeof(msg_pet)*pp.pet_num\
                                    +sizeof(msg_item)*pp.item_num\
                                    +sizeof(msg_skill)*pp.skill_num\
                                    +sizeof(msg_suc)*pp.suc_num;
#endif
//分配空间加载数据
    int len=sizeof(cs_player_info);

    NIMsg* pRegResp = InitMsg( len);
    if (!pRegResp) { return NULL; }
    char*   pPtr = (char*)pRegResp;
    pPtr += sizeof(NIMsg);

    memcpy(pPtr,&pp,sizeof(pp));
    pPtr += sizeof(pp);

    int idx = lua_gettop(m_l);
    lua_pushnil(m_l);
    while (lua_next(m_l, idx) != 0)
    {
        if (lua_type(m_l, -2) == LUA_TSTRING)
        {

            if (strcmp( lua_tostring(m_l, -2),"role")==0)
            {
                lua_role_to( m_l, pPtr);
            }
            else if (strcmp( lua_tostring(m_l, -2),"pet")==0)
            {
                lua_pet_to( m_l, pPtr);
            }
            else if (strcmp( lua_tostring(m_l, -2),"equip")==0)
            {
                lua_equip_to( m_l, pPtr);
            }
            else if (strcmp( lua_tostring(m_l, -2),"item")==0)
            {
                lua_item_to( m_l, pPtr);
            }
            else if (strcmp( lua_tostring(m_l, -2),"skill")==0)
            {
                lua_skill_to( m_l, pPtr);
            }
            else if (strcmp( lua_tostring(m_l, -2),"suc")==0)
            {
                lua_suc_to( m_l, pPtr);
            }
        }
        //移除 'value' ；保留 'key' 做下一次迭代
        lua_pop(m_l, 1);
    }

    lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
    return pRegResp;
}

NIMsg* CGServerMgr::MSG1_CS_GET_PLAYER_ORDER_fun(int id,char* pPkt )
{
    pPkt += sizeof(NIMsg);
    cs_get_player_order* pInfo = (cs_get_player_order*)pPkt;
    int  num = pInfo->num;
    int idx=0;

    LOGGER_DEBUG(CLogController::getinstance(),num );
    NIMsg* pRegResp = InitMsg( sizeof(unsigned short) + sizeof(unsigned int)+sizeof(sc_get_player_order)*num);
    if (!pRegResp) { return NULL; }
    char*   pPtr = (char*)pRegResp;
    pPtr += sizeof(NIMsg);

    lua_State* tmp_lua = m_l;
    // 取玩家数据
      LOG_LUA_GET(tmp_lua, "msg_to_lua");
      lua_pushnumber(tmp_lua, id);
      lua_pushstring(tmp_lua, "get_player_num1");

      if (lua_pcall(tmp_lua, 2, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
           LOGGER_ERROR(CLogController::getinstance(), lua_tostring(tmp_lua,-1));
           lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
           free(pRegResp);
            return NULL;
      }

      idx = lua_gettop(tmp_lua);
      lua_pushnil(tmp_lua);

      lua_next(tmp_lua, idx);   //击败玩家数
      *((unsigned short*)pPtr) = lua_tonumber(tmp_lua, -1);
      lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

      lua_next(tmp_lua, idx);  //自己的排行数据
      pPtr += sizeof(unsigned short);
      *((unsigned int*)pPtr) = lua_tonumber(tmp_lua, -1);
      lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */


     lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */


      /*调用lua函数处理消息并返回*/
      LOG_LUA_GET(tmp_lua, "msg_to_lua");
      lua_pushnumber(tmp_lua, id);
      lua_pushstring(tmp_lua, __func__);
      lua_newtable(tmp_lua);

      lua_pushnumber(tmp_lua, 1);
      lua_pushnumber(tmp_lua, pInfo->num);
      lua_settable(tmp_lua, -3);

      if (lua_pcall(tmp_lua, 3, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
           LOGGER_ERROR(CLogController::getinstance(), lua_tostring(tmp_lua,-1));
           lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
           free(pRegResp);
            return NULL;
      }

    pPtr += sizeof(unsigned int);

    idx = lua_gettop(tmp_lua);
    lua_pushnil(tmp_lua);
    while (lua_next(tmp_lua, idx) != 0)
    {
        lua_order_to( tmp_lua, pPtr);

        lua_pop(tmp_lua, 1);
        pPtr += sizeof(sc_get_player_order);
    }

    lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

    return pRegResp;
}

NIMsg* CGServerMgr::MSG1_CS_GET_PLAYER_ORDER3_fun(int id,char* pPkt )
{
    pPkt += sizeof(NIMsg);
    cs_get_player_order* pInfo = (cs_get_player_order*)pPkt;
    int  num = pInfo->num;
    int idx=0;

    LOGGER_DEBUG(CLogController::getinstance(),num );
    NIMsg* pRegResp = InitMsg( sizeof(unsigned short) + sizeof(unsigned int)+ sizeof(sc_get_player_order)*num);
    if (!pRegResp) { return NULL; }
    char*   pPtr = (char*)pRegResp;
    pPtr += sizeof(NIMsg);

    lua_State* tmp_lua = m_l;
    // 取玩家数据
      LOG_LUA_GET(tmp_lua, "msg_to_lua");
      lua_pushnumber(tmp_lua, id);
      lua_pushstring(tmp_lua, "get_player_num3");

      if (lua_pcall(tmp_lua, 2, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
           LOGGER_ERROR(CLogController::getinstance(), lua_tostring(tmp_lua,-1));
           lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
           free(pRegResp);
            return NULL;
      }

      idx = lua_gettop(tmp_lua);
      lua_pushnil(tmp_lua);

      lua_next(tmp_lua, idx);    //击败玩家数
      *((unsigned short*)pPtr) = lua_tonumber(tmp_lua, -1);
      lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

      lua_next(tmp_lua, idx);   //自己的排行数据
      pPtr += sizeof(unsigned short);
      *((unsigned int*)pPtr) = lua_tonumber(tmp_lua, -1);
      lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */


     lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */


      /*调用lua函数处理消息并返回*/
      LOG_LUA_GET(tmp_lua, "msg_to_lua");
      lua_pushnumber(tmp_lua, id);
      lua_pushstring(tmp_lua, __func__);
      lua_newtable(tmp_lua);

      lua_pushnumber(tmp_lua, 1);
      lua_pushnumber(tmp_lua, pInfo->num);
      lua_settable(tmp_lua, -3);

      if (lua_pcall(tmp_lua, 3, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
           LOGGER_ERROR(CLogController::getinstance(), lua_tostring(tmp_lua,-1));
           lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
           free(pRegResp);
            return NULL;
      }

    pPtr += sizeof(unsigned int);

    idx = lua_gettop(tmp_lua);
    lua_pushnil(tmp_lua);
    while (lua_next(tmp_lua, idx) != 0)
    {
        lua_order_to( tmp_lua, pPtr);

        lua_pop(tmp_lua, 1);
        pPtr += sizeof(sc_get_player_order);
    }

    lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

    return pRegResp;
}
NIMsg* CGServerMgr::MSG1_CS_GET_PLAYER_ORDER2_fun(int id,char* pPkt )
{
    pPkt += sizeof(NIMsg);
    cs_get_player_order* pInfo = (cs_get_player_order*)pPkt;
    int  num = pInfo->num;
    int idx=0;


    LOGGER_DEBUG(CLogController::getinstance(),num );
    NIMsg* pRegResp = InitMsg( sizeof(unsigned short) +sizeof(unsigned int)+ sizeof(sc_get_player_order)*num);
    if (!pRegResp) { return NULL; }
    char*   pPtr = (char*)pRegResp;
    pPtr += sizeof(NIMsg);

    lua_State* tmp_lua = m_l;
    // 取玩家数据
      LOG_LUA_GET(tmp_lua, "msg_to_lua");
      lua_pushnumber(tmp_lua, id);
      lua_pushstring(tmp_lua, "get_player_num2");

      if (lua_pcall(tmp_lua, 2, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
           LOGGER_ERROR(CLogController::getinstance(), lua_tostring(tmp_lua,-1));
           lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
           free(pRegResp);
            return NULL;
      }

      idx = lua_gettop(tmp_lua);
      lua_pushnil(tmp_lua);

      lua_next(tmp_lua, idx);   //击败玩家数
      *((unsigned short*)pPtr) = lua_tonumber(tmp_lua, -1);
      lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

      lua_next(tmp_lua, idx);   //自己的排行数据
      pPtr += sizeof(unsigned short);
      *((unsigned int*)pPtr) = lua_tonumber(tmp_lua, -1);
      lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */


     lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */


      /*调用lua函数处理消息并返回*/
      LOG_LUA_GET(tmp_lua, "msg_to_lua");
      lua_pushnumber(tmp_lua, id);
      lua_pushstring(tmp_lua, __func__);
      lua_newtable(tmp_lua);

      lua_pushnumber(tmp_lua, 1);
      lua_pushnumber(tmp_lua, pInfo->num);
      lua_settable(tmp_lua, -3);

      if (lua_pcall(tmp_lua, 3, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
           LOGGER_ERROR(CLogController::getinstance(), lua_tostring(tmp_lua,-1));
           lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
           free(pRegResp);
            return NULL;
      }

    pPtr += sizeof(unsigned int);

    idx = lua_gettop(tmp_lua);
    lua_pushnil(tmp_lua);
    while (lua_next(tmp_lua, idx) != 0)
    {
        lua_order_to( tmp_lua, pPtr);

        lua_pop(tmp_lua, 1);
        pPtr += sizeof(sc_get_player_order);
    }

    lua_pop(tmp_lua, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

    return pRegResp;
}

void CGServerMgr::Execute( void )//新开线程运行的函数
{
    int8_t    ucNum = 0;
    char      szTime[32] = {0};
    CMsg*     pMsg = NULL;

    if (false == LoadData()) { assert(0); return; }
    LOGGER_DEBUG(CLogController::getinstance(), "LoadData OK");



    LOGGER_DEBUG(CLogController::getinstance(), "msg = "<<m_MsgQueue.empty());
    m_MsgQueue.clear();
    LOGGER_DEBUG(CLogController::getinstance(), "msg = "<<m_MsgQueue.empty());

    while (0==m_bProcExit)
    {
        pMsg = NULL;

        // 消息队列处理

        if (!m_MsgQueue.empty())
        {
            pMsg = m_MsgQueue.front();
            m_MsgQueue.pop_front();
        }

        if (pMsg)
        {

            #if 1
            CRemoteReceiver*  pLink = (CRemoteReceiver*)(pMsg->UserData);
            if (pLink) {
                pLink->m_uiUserID = pMsg->Sender;
            }
            #endif

            LOGGER_DEBUG(CLogController::getinstance(), "Begin Call Msg [" <<pMsg->Sender<<"."<<pMsg->MsgID << "] ++++++++++++ ")
            NIMsg* ret=NULL;
            char*   pPkt  = (char*)(((CEPMsg*)(pMsg))->Buf);

            switch (pMsg->MsgID)
            {
                case CS_PLAYER_LOGIN:
                {
                    ret = OnLogin((int *)&pMsg->Sender,pPkt);

                }
                break;

                case CS_PLAYER_REG:
                {
                    ret =OnRegister(pMsg->Sender,pPkt);
                }
                break;

                case MSG1_CS_PLAYER_INFO: //保存玩家数据
                {
                     ret =MSG1_CS_PLAYER_INFO_fun(pMsg->Sender, pPkt);
                }
                break;

                case MSG1_CS_GET_PLAYER_INFO:
                {
                     ret =MSG1_CS_GET_PLAYER_INFO_fun(pMsg->Sender, pPkt);
                }
                break;

                case MSG1_CS_GET_OTHER_PLAYER:
                {
                     ret =MSG1_CS_GET_OTHER_PLAYER_fun(pMsg->Sender, pPkt);
                }
                break;

                case MSG1_CS_GET_PLAYER_ORDER: //获取周排行
                {
                     ret =MSG1_CS_GET_PLAYER_ORDER_fun(pMsg->Sender, pPkt);
                }
                break;

                case MSG1_CS_GET_PLAYER_ORDER2: //获取月排行
                {
                     ret =MSG1_CS_GET_PLAYER_ORDER2_fun(pMsg->Sender, pPkt);
                }
                break;

                case MSG1_CS_GET_PLAYER_ORDER3: //获取总排行
                {
                     ret =MSG1_CS_GET_PLAYER_ORDER3_fun(pMsg->Sender, pPkt);
                }
                break;

            default:
                break;
            }


            if (ret != NULL)
            {
                ret->Head.Sender = pMsg->Sender;
                ret->Head.MsgID = pMsg->MsgID;
                SendMsg(ret, pMsg->UserData);
                LOGGER_DEBUG(CLogController::getinstance(), "End Call Msg OK [" <<pMsg->Sender<<"."<<pMsg->MsgID <<"] ++++++++++++ ")
            }
            else
            {
                LOGGER_DEBUG(CLogController::getinstance(), "End Call Msg err[" <<pMsg->Sender<<"."<<pMsg->MsgID <<"] ++++++++++++ ")
            }

            free(pMsg);
            pMsg = NULL;

        }
        else
        {
            // 如果没有消息处理 等待
            usleep(100);
        }


    }
}

int CGServerMgr::GetProcNoByPort( const uint32_t uiPort, uint32_t &uiProcNo )
{
    FILE *hFile;
    char szBuff[256] = {0};

    sprintf(szBuff, "ProcNo=`netstat -nap|grep %u|grep LISTEN|grep tcp|awk '{print $7}'`;ProcNo=$(echo ${ProcNo%/*});echo $ProcNo", uiPort);

    hFile = popen(szBuff, "r");
    if (hFile == NULL){ return 0;}

    if (fgets(szBuff, sizeof(szBuff), hFile) == NULL)
    {
        pclose(hFile);
        return 0;
    }

    //取进程号
    uiProcNo = (uint16_t)strtoul(szBuff, NULL, 10);

    pclose(hFile);
    return 1;
}

int CGServerMgr::GetProcNameByProcNo( const uint32_t uiProcNo, char *pszProcName )
{
    if (pszProcName == NULL) { return 0;}

    FILE *hFile;
    char szBuff[256] = {0};

    sprintf(szBuff, "ProcNm=`ps -ef|grep %u|grep -v grep|awk '{print $8}'`;ProcNm=$(echo ${ProcNm##*/});echo $ProcNm", uiProcNo);

    hFile = popen(szBuff, "r");
    if (hFile == NULL) { return 0; }

    if (fgets(szBuff, sizeof(szBuff), hFile) == NULL)
    {
        pclose(hFile);
        return 0;
    }

    //取进程名
    szBuff[strlen(szBuff)-1] = 0x0;
    memset(pszProcName, 0, strlen(pszProcName));
    strcpy(pszProcName, szBuff);

    pclose(hFile);
    return 1;
}

NIMsg* CGServerMgr::InitMsg( uint32_t Len )
{
    NIMsg* pMsg = (NIMsg*)LOG_MALLOC( sizeof(NIMsg) + Len + 1);
     if (!pMsg)
     {
        LOGGER_ERROR(CLogController::getinstance(), "malloc res fail");
        return NULL;
     }

    memset(pMsg, 0, sizeof(NIMsg)+Len+1 );
    pMsg->Flag              = MSG_FLAG_VAL;
    pMsg->EncryptType       = RC4_E;
    pMsg->Len               = sizeof(NIMsg) + Len + 1;
    pMsg->Head.Source       = MSF_GSERVER;
    pMsg->Head.Version      = INTERFACE_VERSION;
    return pMsg;
}

void CGServerMgr::SendMsg( NIMsg* pRespMsg, uint64_t link )
{
    #if 0
    if ( pRespMsg->Len>MAX_SEND_BUFFER )
    {
    }
    #endif

    LinkIter  Iter = m_LinkHMap.find(link);
    if (Iter != m_LinkHMap.end())
    {
        CRemoteReceiver* pLink = (CRemoteReceiver* )link;
        assert(pLink);
        pLink->PushMsg(pRespMsg, 0);

    }
    else
    {
        LOGGER_DEBUG(CLogController::getinstance(), "已断开连接 放弃消息 [" <<pRespMsg->Len<<"."<<pRespMsg->Flag<<"] ++++++++++++ ")
        free(pRespMsg);
        pRespMsg = NULL;
    }

}

void CGServerMgr::OffLine( uint32_t uiUserID, uint64_t ullLink )
{
    m_LinkHMap.erase(ullLink);

    #if 0
    /*调用lua函数处理消息并返回*/
      LOG_LUA_GET(m_l, "msg_to_lua");

      lua_pushnumber(m_l, uiUserID);
      lua_pushstring(m_l, "OffLine");

      if (lua_pcall(m_l, 2, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
      {
          LOGGER_ERROR(CLogController::getinstance(), lua_tostring(m_l,-1));
          lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
           return;
      }

     int ret = lua_tonumber(m_l, -1);
     lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

     #endif
}


bool CGServerMgr::LoadData( void )
{

    /*调用lua函数处理消息并返回*/
    LOG_LUA_GET(m_l, "load_mysql");

    if (lua_pcall(m_l, 0, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
    {
        LOGGER_ERROR(CLogController::getinstance(), lua_tostring(m_l,-1));
        lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
        return false;
    }

    int ret = lua_tonumber(m_l, -1);
    if (0!=ret) {
        LOGGER_ERROR(CLogController::getinstance(), ret);
    }
    lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

    return true;
}

int32_t CAynscWriter::OnMsg( CMsg* pMsg )
{
    LOGGER_DEBUG(CLogController::getinstance(), "-----------------");
    return PROC_SUCCESS;
}
