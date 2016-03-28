/*----------------------------------------------------------------
 *
 *  Description:  简单的日志管理器
 ----------------------------------------------------------------*/
#ifndef __CST_LOGGER_H__
#define __CST_LOGGER_H__

#include "isq_thread.h"
#include "isq_database.h"
#include <iostream>

const unsigned int  LOG_LEVEL_NUM = 3;
const unsigned int  DEBUG_BUF_SIZE = 3001;

// 日志级别
typedef enum tagLogLevel_E
{
  LOG_LEVEL_DEBUG    = 0,  // 调试日志
  LOG_LEVEL_INFO     = 1,  // 模块相关资源占用日志
  LOG_LEVEL_ERROR    = 2,  // 错误日志
  LOG_LEVEL_OFF      = 3,  // 关闭所有日志记录
}LogLevel_E;

struct log_task     //日志任务
{
    unsigned int player_id;
    char  str[1024];
};

class CLogController;

#define LOGGER_MACRO_BODY(logger, logEvent, logLevel) \
  do                                                 \
  {                                                  \
    stringstream ss;                               \
    ss << logEvent << endl;                        \
    (logger)->WriteLog(syscall(SYS_gettid),logLevel, ss.str(), __FILE__, __FUNCTION__, __LINE__);\
  } while (0);

// 调试日志
#define LOGGER_DEBUG(logger,logEvent) LOGGER_MACRO_BODY(logger,logEvent,LOG_LEVEL_DEBUG)

// malloc日志
#define LOG_MALLOC(size)  malloc(size)

// lua日志
#define LOG_LUA_GET(lua,str)  lua_getglobal(lua,str); // LOGGER_DEBUG(CLogController::getinstance(),"lua")


// 资源占用或其它日志
#define LOGGER_INFO(logger,logEvent) LOGGER_MACRO_BODY(logger,logEvent,LOG_LEVEL_INFO)

// 错误信息
#define LOGGER_ERROR(logger,logEvent) LOGGER_MACRO_BODY(logger,logEvent,LOG_LEVEL_ERROR)

extern CfgInfo m_CfgInfo;

class CLogController : public CThread
{
private:
  FILE*        m_pFile[LOG_LEVEL_NUM];
  char         m_szBuf1[DEBUG_BUF_SIZE];
  char         m_szBuf2[DEBUG_BUF_SIZE];
  int   m_eLogLevel;
  uint16_t     m_usSaveCycle;
  CLogController* m_Instance;
  CMutex m_Mutex;

  // 写日志锁
  CMutex m_WriteMutex;

  CfgInfo *pm_CfgInfo;
public:
    lua_State*    m_l;

  static CLogController* getinstance()
  {
      static CLogController instance;
      return &instance;
  }

  CLogController(uint16_t usSaveCycle=5, LogLevel_E eLogLevel=LOG_LEVEL_DEBUG):CThread(99)
  {

    m_eLogLevel = eLogLevel;
    m_usSaveCycle = usSaveCycle;
    pm_CfgInfo = &m_CfgInfo;
    m_l =  luaL_newstate();
    memset(m_szBuf1, 0, DEBUG_BUF_SIZE);
    memset(m_szBuf2, 0, DEBUG_BUF_SIZE);

    for (uint32_t k = 0; k < LOG_LEVEL_NUM; k++)
    {
      m_pFile[k] = NULL;
    }

    if (false == Start())
    {
        printf("Logger start fail, main exit\n");
    }


  }

  virtual ~CLogController(void)
  {
      DBClose(m_l);
  }
protected:

  bool      OnStart(void)
  {

    // 检查日志文件目录./log是否存在,不存在创建
    struct stat stEntryInfo;
    if (stat("./log", &stEntryInfo) < 0)
    {
      mkdir("./log", 0755);
    }

    SwitchLogFile();


    return true;
  }

  void      OnStop(void)
  {
    CLock x(m_WriteMutex);

    for (uint32_t k = 0; k < LOG_LEVEL_NUM; k++)
    {
      if (m_pFile[k])
      {
        fclose(m_pFile[k]);
        printf("Logger file close\n");
        m_pFile[k] = NULL;
      }
    }
  }
   CQueue<log_task>  m_task;// 任务队列

  void      Execute(void)
  {
    time_t  ulCurTime = time(NULL);
    time_t  ulOldTime = time(NULL);
    struct tm TMCur;
    struct tm TMOld;

     char g_DebugLevel[] = {"debug_"};
     char g_ErrorLevel[] = {"error_"};
     char g_InfoLevel[] = {"info_"};

    if (NULL == localtime_r(&ulOldTime, &TMOld))
    {
      LOGGER_ERROR(this, "localtime_r error" << endl);
      return;
    }

    while (CThread::IsRunning())
    {
        if (1==m_bProcExit)
        {
            break;
        }

      ulCurTime = time(NULL);
      if (NULL == localtime_r(&ulCurTime, &TMCur))
      {
        LOGGER_ERROR(this, "localtime_r error" << endl);
        continue;
      }

      if (TMCur.tm_mday != TMOld.tm_mday)
      {
        // ulOldTime后续用后再修改，这里用ulCurTime
        if (NULL == localtime_r(&ulCurTime, &TMOld))
        {
          LOGGER_ERROR(this, "localtime_r error" << endl);
          continue;
        }

        // 日志文件切换
        SwitchLogFile();

        // 清理历史日志
        ClearHistoryLogFile(g_DebugLevel, strlen(g_DebugLevel));
        ClearHistoryLogFile(g_ErrorLevel, strlen(g_ErrorLevel));
        ClearHistoryLogFile(g_InfoLevel, strlen(g_InfoLevel));
      }

      if ((ulCurTime - ulOldTime) <= 0)
      {
        ::sleep(1);
        continue;
      }

      ulOldTime = ulCurTime;
      memset(m_szBuf1, 0, DEBUG_BUF_SIZE);

      ::sleep(1);

      log_task* e = NULL;
        if ( m_task.Pop(&e) )
        {
            if (NULL != e)
            {
                lua_getglobal(m_l, "player_log");
                lua_pushnumber(m_l, e->player_id);
                lua_pushstring(m_l, e->str);

                if (lua_pcall(m_l, 2, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
                {
                    LOGGER_ERROR(this, lua_tostring(m_l,-1));
                }

                lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
                free(e);
                e=NULL;
            }
        }
    }
  }
public:
    bool log_sql_write(unsigned int player_id,char * pstr)
    {
        log_task *e = (log_task*)malloc(sizeof(log_task));
        e->player_id =  player_id;
        memcpy(e->str,pstr,sizeof(e->str));
        return m_task.Push(e);
    }
  void      SetParameter(uint16_t usSaveCycle, int eLogLevel)
  {
    m_eLogLevel = eLogLevel;
    m_usSaveCycle = usSaveCycle;
  }

  void      GetRunPath(string& szFileName)
  {
    char     szFullPath[PATH_MAX] = {0};
    ssize_t  ilRet = readlink( "/proc/self/exe", szFullPath, PATH_MAX);

    if (ilRet < 0 || ilRet >= PATH_MAX)
    {
      assert(NULL);
      return;
    }

    // 去除文件名，仅留下路径
    szFileName = szFullPath;
    size_t uiPos = szFileName.find_last_of('/');
    szFileName = szFileName.substr(0, uiPos + 1);
  }

  void    WriteLog(const int pid,const LogLevel_E eLevel, const string& strEvent, const char* pFile, const char* pFun,  const int iLine)
  {
    CLock x(m_WriteMutex);

    if (false == CThread::IsRunning())
    {
      return;
    }

    if ( !((pFile) && (pFun)) ) {
        return;
    }

    FILE*   pFileHandle = NULL;
    struct  tm  stTM;
    time_t  ulCurTime = time(NULL);
    char    szLevel[15] = {0};

    try
    {
      if ( !(localtime_r(&ulCurTime, &stTM)) ) {
        return;
      }

      switch (eLevel)
      {
      case LOG_LEVEL_DEBUG:
        {
          if ((m_eLogLevel > LOG_LEVEL_DEBUG)) {
              return;
          }
          pFileHandle = m_pFile[0];
          snprintf(szLevel, sizeof(szLevel)-1, "DEBUG");
        }
        break;
      case LOG_LEVEL_INFO:
        {
          if ((m_eLogLevel > LOG_LEVEL_INFO)) {
              return;
          }
          pFileHandle = m_pFile[1];

          int  iTLen = snprintf(m_szBuf2, DEBUG_BUF_SIZE-1, "[%04d-%02d-%02d %02d:%02d:%02d %d]\t%s", \
            stTM.tm_year+1900, stTM.tm_mon+1, stTM.tm_mday, stTM.tm_hour, stTM.tm_min, stTM.tm_sec, pid,strEvent.c_str());

          fwrite(m_szBuf2, iTLen, 1, pFileHandle);
          fflush(pFileHandle);
          return;
        }
        break;
      case LOG_LEVEL_ERROR:
        {
          if ((m_eLogLevel > LOG_LEVEL_ERROR)) {
              return;
          }
          pFileHandle = m_pFile[2];
          snprintf(szLevel, sizeof(szLevel)-1, "ERROR");
        }
        break;
      default:
        {
          if ((m_eLogLevel > LOG_LEVEL_INFO)) {
              return;
          }
          pFileHandle = m_pFile[1];
          snprintf(szLevel, sizeof(szLevel)-1, "INFO");
        }
        break;
      }

      int  iLen = 0;

      const char* pPch = strrchr(pFile, '/');
      if (pPch)
      {
        iLen = snprintf(m_szBuf2, DEBUG_BUF_SIZE-1, "[%04d-%02d-%02d %02d:%02d:%02d %d][%s][%s:%s:%d] %s", \
          stTM.tm_year+1900, stTM.tm_mon+1, stTM.tm_mday, stTM.tm_hour, stTM.tm_min, stTM.tm_sec,pid, szLevel, pPch+1, pFun, iLine, strEvent.c_str());
      }
      else
      {
        iLen = snprintf(m_szBuf2, DEBUG_BUF_SIZE-1, "[%04d-%02d-%02d %02d:%02d:%02d %d][%s][%s:%s:%d] %s", \
          stTM.tm_year+1900, stTM.tm_mon+1, stTM.tm_mday, stTM.tm_hour, stTM.tm_min, stTM.tm_sec,pid, szLevel, pFile, pFun, iLine, strEvent.c_str());
      }

      if (pFileHandle)
      {
        fwrite(m_szBuf2, iLen, 1, pFileHandle);
        fflush(pFileHandle);
      }
    }
    catch (...)
    {
    }
  }
private:
  void  SwitchLogFile(void)
  {
    CLock x(m_WriteMutex);

    for (uint32_t k = 0; k < LOG_LEVEL_NUM; k++)
    {
      if (m_pFile[k])
      {
        fclose(m_pFile[k]);
        m_pFile[k] = NULL;
      }
    }

    char     szFN[MAX_PATH] = {0};
    time_t   uiNow = 0;
    struct tm TmpNow;

    time(&uiNow);
    if (NULL == localtime_r(&uiNow, &TmpNow))
    {
      cerr<<"Call localtime_r error"<<endl;
      return;
    }

    string  szRunPath;
    GetRunPath(szRunPath);

    snprintf(szFN,  MAX_PATH-1, "%slog/debug_%04d%02d%02d.log", szRunPath.c_str(), TmpNow.tm_year+1900, TmpNow.tm_mon+1, TmpNow.tm_mday);
    m_pFile[0] = fopen(szFN, "a");
    if (NULL == m_pFile[0])
    {
      cout << "fopen failed. errno:" << errno << " strerr:" << strerror(errno) << endl;
      assert(NULL);
    }

    memset(szFN, 0, MAX_PATH);
    snprintf(szFN,  MAX_PATH-1, "%slog/info_%04d%02d%02d.log", szRunPath.c_str(), TmpNow.tm_year+1900, TmpNow.tm_mon+1, TmpNow.tm_mday);
    m_pFile[1] = fopen(szFN, "a");
    if (NULL == m_pFile[1])
    {
      cout << "fopen failed. errno:" << errno << " strerr:" << strerror(errno) << endl;
      assert(NULL);
    }

    memset(szFN, 0, MAX_PATH);
    snprintf(szFN,  MAX_PATH-1, "%s/log/error_%04d%02d%02d.log", szRunPath.c_str(), TmpNow.tm_year+1900, TmpNow.tm_mon+1, TmpNow.tm_mday);
    m_pFile[2] = fopen(szFN, "a");
    if (NULL == m_pFile[2])
    {
      cout << "fopen failed. errno:" << errno << " strerr:" << strerror(errno) << endl;
      assert(NULL);
    }
  }

  void ClearHistoryLogFile(char* pFix, size_t uiFixLen)
  {
    DIR* pMyDir = NULL;
    struct dirent* pMyDirp = NULL;
    struct tm when;
    time_t now;
    time_t result;

    time(&now);
    if (NULL == localtime_r(&now, &when))
    {
      LOGGER_ERROR(this, "localtime_r error" << endl);
      return;
    }

    if(NULL == (pMyDir=opendir("log/")))
    {
      return;
    }

    char szTmpBuff[MAX_PATH] = {0};
    char szLogFile[MAX_PATH] = {0};
    std::string strTmp = "";
    std::string strFix = "";

    when.tm_mon = when.tm_mon - m_usSaveCycle;
    if ( (result = mktime(&when)) != (time_t)-1)
    {
      snprintf(szTmpBuff, MAX_PATH, "%s%04d%02d%02d.log", pFix, when.tm_year+1900, when.tm_mon+1, when.tm_mday);
    }
    else
    {
      return;
    }

    while (NULL != (pMyDirp = readdir(pMyDir)))
    {
      strTmp = pMyDirp->d_name;
      strFix = strTmp.substr(0, uiFixLen);

      if ( (0 == strcmp(".", pMyDirp->d_name)) || (0 == strcmp("..", pMyDirp->d_name)) || (0 != strcmp(pFix, strFix.c_str())) )
      {
        continue;
      }

      if (strcmp(szTmpBuff, pMyDirp->d_name) >= 0)
      {
        snprintf(szLogFile, MAX_PATH, "log/%s", pMyDirp->d_name);
        if (0 != remove(szLogFile))
        {
          LOGGER_ERROR(this, "Del history log file(" << szLogFile << ") failed or file inexistence." << endl);
          break;
        }

        LOGGER_DEBUG(this, "Del history log file=" << szLogFile << endl);
      }
    }

    closedir(pMyDir);
  }
};

#endif // __CST_LOGGER_H__
