#include "isq_database.h"
#include "isq_logger.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

int c_mysql(lua_State *L)
{
    lua_getglobal(L, "m_DB");
    long i=lua_tonumber(L, -1);
    MYSQL* pms=(MYSQL*)i;

    //获取参数
    int num = lua_tonumber(L, 1);//返回数据的字段数量
    char * sql = (char*)lua_tostring(L, 2);
    int log = lua_tonumber(L, 3);//1:记日志 0：不记日志
    int player = lua_tonumber(L, 4);//玩家id

    if (mysql_query(pms, sql))
    {
       lua_pushnumber(L, 1); /* 在完成计算后，只需将结果重新写入虚拟堆栈即可（写入的这个值就是函数的返回值） */
       return 1; /* 函数的返回值是函数返回参数的个数。没错，Lua函数可以有多个返回值。 */
    }

    if ( num ==0 )
    {
        lua_pushnumber(L, 0); /* 在完成计算后，只需将结果重新写入虚拟堆栈即可（写入的这个值就是函数的返回值） */
        return 1; /* 函数的返回值是函数返回参数的个数。没错，Lua函数可以有多个返回值。 */
    }

    MYSQL_RES *pResult = mysql_store_result(pms);
    if (!pResult)
    {
        lua_pushnumber(L, 2); /* 在完成计算后，只需将结果重新写入虚拟堆栈即可（写入的这个值就是函数的返回值） */
       return 1; /* 函数的返回值是函数返回参数的个数。没错，Lua函数可以有多个返回值。 */
    }

    lua_newtable(L);//创建一个lua父表
    int m = 1;
    MYSQL_ROW   row;
    while((row = mysql_fetch_row(pResult)))
    {
        for (int i=0;i<num;i++)
        {
            lua_pushnumber(L, m++);
            lua_pushstring(L, row[i]);
            lua_settable(L, -3);
        }
    }
    mysql_free_result(pResult);  //释放mysql空间

    if ( log>0 )
    {
        CLogController::getinstance()->log_sql_write(player,sql);
    }
    return 1; /* 函数的返回值是函数返回参数的个数。没错，Lua函数可以有多个返回值。 */
}

char* reload_lua(lua_State* L,char* path)
{
    luaL_openlibs(L);
    lua_register(L, "c_connect_db", DBConnect );
    lua_register(L, "_sql", c_mysql);
    if (luaL_dofile(L, path) != 0)
    {
          LOGGER_ERROR(CLogController::getinstance(),lua_tostring(L,-1));
          lua_pop(L, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
    }

    return NULL;
}

int DBConnect(lua_State *L)
{
    //获取参数
    char * pIP = (char*)lua_tostring(L, 1);
    char * pUserName = (char*)lua_tostring(L, 2);
    char * pPwd = (char*)lua_tostring(L, 3);
    char * pDBName = (char*)lua_tostring(L, 4);
    unsigned int uiPort=lua_tonumber(L, 5);

    MYSQL* pms = mysql_init(NULL);
    if (pms == NULL)
    {
        mysql_library_end();
        lua_pushnumber(L, 0); /* 这个值就是函数的返回值 */
        return 1; /* 函数的返回值是函数返回参数的个数。 */
    }

    if (mysql_real_connect(pms, pIP, pUserName, pPwd, pDBName, uiPort, NULL, 0) == NULL)
    {
        mysql_close(pms);
        mysql_library_end();
        lua_pushnumber(L, 0); /* 这个值就是函数的返回值 */
        return 1; /* 函数的返回值是函数返回参数的个数。 */
    }

    char  Flag = 1;
    mysql_options(pms, MYSQL_OPT_RECONNECT, (char*)&Flag);

    if (0 != mysql_query(pms, "SET NAMES 'utf8'"))
    {
        mysql_close(pms);
        mysql_library_end();
       lua_pushnumber(L, 0); /* 这个值就是函数的返回值 */
       return 1; /* 函数的返回值是函数返回参数的个数 */
    }

    lua_pushnumber(L, (long)pms);
    return 1; /* 函数的返回值是函数返回参数的个数。 */
}

int DBClose(lua_State *L)
{
    lua_getglobal(L, "m_DB");
    long i=lua_tonumber(L, -1);
    MYSQL* pms=(MYSQL*)i;

    mysql_close(pms);

    lua_close(L);

    return PROC_SUCCESS;
}
