/*
 *  Description:  公共类(互斥量、锁、线程、队列等封装
 ----------------------------------------------------------------*/

#ifndef   __MPDK_THREAD_H__
#define   __MPDK_THREAD_H__

#include <sys/syscall.h>

class CThread
{
public:
    pthread_attr_t attr;
    CThread(int lv)
    {
        m_bRunning = false;
        m_pid = 0;
        int ret = pthread_attr_init(&attr);
        ret = pthread_attr_setscope (&attr, PTHREAD_SCOPE_SYSTEM);
        ret = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        ret = pthread_attr_setschedpolicy(&attr, SCHED_RR);
        struct sched_param sched;
        sched.sched_priority = lv;
        ret = pthread_attr_setschedparam(&attr,&sched);
    }
    virtual ~CThread(void)
    {
        if (m_bRunning)
        {
            Stop();
        }
    }
public:
        pthread_t m_hThread;
    pid_t m_pid;
    static void* ThreadFunc(void* pParam = NULL)
    {
        m_exitnum++;
        CThread* pThread = (CThread*)pParam;
        pthread_detach(pthread_self());
        if ( NULL != pThread )
        {
            pThread->Run();
        }
        return NULL;
    }
    void   Run(void)
    {
        m_pid = syscall(SYS_gettid);
        printf("创建线程%d[%lu]\n",m_exitnum,m_pid);

        m_bRunning = true;
        ::sleep(1);

        Execute();
        m_bRunning = false;
        m_exitnum--;
        printf("退出线程%d[%lu]\n",m_exitnum,m_pid);

        Destory();
    }

    bool   Start(void)
    {
        if (m_bRunning)
        {
            return false;
        }

        if ( !OnStart() )
        {
            return m_bRunning;
        }

        if (pthread_create(&m_hThread, &attr, ThreadFunc, (void*)this) != 0)
        {
            return m_bRunning;
        }

        m_bRunning = true;
        return m_bRunning;
    }

    void   Stop(void)
    {
        m_bRunning = false;
        OnStop();
    }

    bool   IsRunning(void) const
    {
        return m_bRunning;
    }

protected:

    void   Destory(void)
    {
        pthread_exit(NULL);
    }
    virtual bool  OnStart(void)
    {
        return true;
    }
    virtual void  OnStop(void){};
    virtual void  Execute(void) = 0;
private:

private:
    bool      m_bRunning;
};

class CMutex
{
public:
    CMutex(void)
    {
        pthread_mutex_init(&m_Mutex,NULL);
    }
    virtual ~CMutex(void)
    {
        pthread_mutex_destroy(&m_Mutex);
    }
public:
    void Lock(void)
    {
        pthread_mutex_lock(&m_Mutex);
    }
    void UnLock(void)
    {
        pthread_mutex_unlock(&m_Mutex);
    }
private:
    pthread_mutex_t m_Mutex;
};

class CLock
{
public:
    CLock(CMutex& mutex) : m_Mutex(mutex)
    {
        m_Mutex.Lock();
    }
    virtual ~CLock(void)
    {
        m_Mutex.UnLock();
    }
private:
    CMutex& m_Mutex;
};



template <typename T>
class CQueue
{
public:
    CQueue(unsigned int uiSize = 10000000);
    virtual ~CQueue(void);
public:
    inline bool    Push(T* e);
    inline bool    Pop(T** e);
    inline unsigned int  Size(void);
private:
    T**  m_pQueue;
    unsigned int m_uiSize;
    unsigned int m_uiPop;
    unsigned int m_uiPush;
    unsigned int m_uiNum;
    CMutex m_Mutex;
};

template <typename T>
inline unsigned int CQueue<T>::Size( void )
{
    CLock x(m_Mutex);

    return m_uiNum;
}

template <typename T>
inline bool CQueue<T>::Pop( T** e )
{
    CLock x(m_Mutex);

    if (!m_uiNum)
    {
        return false;
    }

    if (m_uiPop == m_uiSize)
    {
        m_uiPop = 0;
    }

    *e = *(m_pQueue + m_uiPop%m_uiSize);
    m_uiPop++;
    m_uiNum--;
    return true;
}

template <typename T>
inline bool CQueue<T>::Push( T* e )
{
    CLock x(m_Mutex);

    if (m_uiNum >= m_uiSize)
    {
        printf("Msg Push fail(e=%lu)\n", (uint64_t)e);
        return false;
    }

    if (m_uiPush == m_uiSize)
    {
        m_uiPush = 0;
    }

    *(m_pQueue + m_uiPush%m_uiSize) = e;
    m_uiPush++;
    m_uiNum++;
    return true;
}

template <typename T>
CQueue<T>::CQueue( unsigned int uiSize /*= 50000000*/ ) : m_uiSize(uiSize), m_uiPop(0), m_uiPush(0), m_uiNum(0)
{
    m_pQueue = ( new T*[uiSize] );
    assert(m_pQueue);
}

template <typename T>
CQueue<T>::~CQueue(void)
{
    if (m_pQueue)
    {
        delete[] m_pQueue;
        m_pQueue = NULL;
    }
}




#endif // __MPDK_THREAD_H__
