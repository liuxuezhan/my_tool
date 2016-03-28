#include <iostream>
#include <stdint.h>
#include "isq_gserver_mgr.h"

#define ISQ_SYSTEM_VERSION  "lxz_server-debug-2015.8.25"

CGServerMgr* pMgr=NULL;
CfgInfo m_CfgInfo;
int  m_bProcExit = 0;
int  m_exitnum = 0;
void CatchSysSignal(int iSignal);
void sig_reload_lua_1()
{
    LOGGER_DEBUG(CLogController::getinstance(), "reload lua  begin------------>");
    reload_lua( CLogController::getinstance()->m_l, "lua/pid_log.lua");
    reload_lua(pMgr->m_l,"lua/pid_main.lua");

    for (uint32_t n = 0 ; n < pMgr->m_DispatchMgr->m_ucWriterNum ; n ++)
    {
        reload_lua(pMgr->m_DispatchMgr->m_pWrites[n]->m_l,"lua/pid_1.lua");

    }
    LOGGER_DEBUG(CLogController::getinstance(), "------------->reload lua  end");

}

void sig_reload_lua_2()
{

}

void server_quit()
{
    m_bProcExit = 1;
    while (m_exitnum>0) {
        LOGGER_DEBUG(CLogController::getinstance(), "正在执行退出流程["<< m_exitnum <<"]");
        ::sleep(1);
    }

    delete pMgr;
    CLogController::getinstance()->Stop();
}

void CatchSysSignal(int iSignal)
{

    LOGGER_DEBUG(CLogController::getinstance(), "捕获信号: ["<< iSignal << "]");

    switch(iSignal)
    {
    case SIGUSR1:
        {
            sig_reload_lua_1();
            break;
        }
    case SIGUSR2:
        {
            sig_reload_lua_2();
            break;
        }
    case SIGINT:
    case SIGTERM:
    case SIGSYS:
    case SIGTRAP:
        {//正常退出
            server_quit();
            exit(0);
        }
    case SIGILL:
    case SIGQUIT:
    case SIGBUS:
    case SIGSEGV:
    case SIGFPE:
    case SIGXCPU:
    case SIGXFSZ:
        {//非法退出
        //    server_quit();
            abort();
        }
    default:
        break;
    }
}

void InstallSysSignal(void)
{
    struct sigaction sigact;
    struct sigaction old;

    sigact.sa_handler = CatchSysSignal;
    sigfillset(&sigact.sa_mask);//执行时屏蔽所有信号
    sigact.sa_flags = 0;

    if (sigaction(SIGINT, &sigact, &old) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGINT");
    }
    if (sigaction(SIGTERM, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGTERM");
    }
    if (sigaction(SIGQUIT, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGQUIT");
    }

    if (sigaction(SIGHUP, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGHUP");
    }
    if (sigaction(SIGUSR1, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGUSR1");
    }
    if (sigaction(SIGUSR2, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGUSR2");
    }
    if (sigaction(SIGALRM, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGALRM");
    }
    if (sigaction(SIGSYS, &sigact, NULL) < 0)
    {       LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGSYS");
    }

    if (sigaction(SIGBUS, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGBUS");
    }
    if (sigaction(SIGILL, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGILL");
    }

    if (sigaction(SIGFPE, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGFPE");
    }

    if (sigaction(SIGSEGV, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGSEGV");
    }

    if (sigaction(SIGTRAP, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGTRAP");
    }

    if (sigaction(SIGXCPU, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGXCPU");
    }

    if (sigaction(SIGXFSZ, &sigact, NULL) < 0)
    {
        LOGGER_ERROR(CLogController::getinstance(), "安装信号失败: SIGXFSZ");
    }

}

int LoadCfgInfo( CfgInfo* m_CfgInfo )
{
    memset(m_CfgInfo, 0, sizeof(CfgInfo));

    lua_State* p_l =  luaL_newstate();
    reload_lua(p_l,"lua/conf.lua");

    LOG_LUA_GET(p_l, "port");
    m_CfgInfo->ListenPort = lua_tonumber(p_l,-1);
    lua_pop(p_l, 1);

    LOG_LUA_GET(p_l, "address");
    snprintf(m_CfgInfo->BindIP,  sizeof(m_CfgInfo->BindIP), "%s", lua_tostring(p_l,-1));
    lua_pop(p_l, 1);

    LOG_LUA_GET(p_l, "save_cycle");
    m_CfgInfo->SaveCycle = lua_tonumber(p_l,-1);
    lua_pop(p_l, 1);

    LOG_LUA_GET(p_l, "log_level");
    m_CfgInfo->LogLevel = lua_tonumber(p_l,-1);
    lua_pop(p_l, 1);

    LOG_LUA_GET(p_l, "moduleid");
    m_CfgInfo->ModuleID = lua_tonumber(p_l,-1);
    lua_pop(p_l, 1);

    LOG_LUA_GET(p_l, "instanceid");
    m_CfgInfo->InstanceID = lua_tonumber(p_l,-1);
    lua_pop(p_l, 1);

    LOG_LUA_GET(p_l, "name");
    snprintf(m_CfgInfo->Name,  sizeof(m_CfgInfo->Name), "%s", lua_tostring(p_l,-1));
    lua_pop(p_l, 1);

    lua_close(p_l);

    CLogController::getinstance()->SetParameter(m_CfgInfo->SaveCycle,m_CfgInfo->LogLevel);
}

void ShowSysVersion( void )
{
    char szVer[64] = {0};

    sprintf(szVer, "版本: %s 编译时间: %s %s", ISQ_SYSTEM_VERSION, __DATE__, __TIME__);
    printf("%s\n",szVer);
    LOGGER_DEBUG(CLogController::getinstance(), szVer);
}

int32_t main(int32_t argc, char** argv)
{

    if ((2 == argc) && ('1' == argv[1][0])){   ; }

    signal(SIGPIPE, SIG_IGN);//socket连接断开不处理

    string          szRunPath        = "";
    char            szPath[MAX_PATH] = {0};

    cs_login  m_pwd;
    memcpy(m_pwd.name,"几乎都是覅和任务\0",USER_NAME_LEN);
    memcpy(m_pwd.pwd,"而我ssssssssssssssssssss",REG_PWD_LEN);
    printf("\n---->[%s]",m_pwd.name);
    printf("\n---->[%s]",m_pwd.pwd);

    CEncrypt rc6(RC4_KEY);
    rc6.rc4_crypt((unsigned char*)&m_pwd,sizeof(cs_login));

    printf("\n---->[%s]",m_pwd.name);
    printf("\n---->[%s]",m_pwd.pwd);

    LoadCfgInfo(&m_CfgInfo);

    // 日志管理器启动
    CLogController* m_pLogger = CLogController::getinstance();
    LOGGER_INFO(CLogController::getinstance(), "日志线程ID[" <<m_pLogger->m_pid << "] ");

    ShowSysVersion();   // 服务器版本信息

    //在日志启动后加载lua才能用日志
    reload_lua( CLogController::getinstance()->m_l, "lua/pid_log.lua");

    InstallSysSignal();//安装信号

    pMgr= new CGServerMgr(&m_CfgInfo,0);
    LOGGER_INFO(CLogController::getinstance(), "主线程ID[" << pMgr->m_pid << "] ");

    while (true)
    {
        ::sleep(5);
    }

    mysql_library_end();

    return 0;
}
