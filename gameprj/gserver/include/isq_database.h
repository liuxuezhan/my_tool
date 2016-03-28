#ifndef __ISQ_DATABASE_H__
#define __ISQ_DATABASE_H__

//#include <mysql.h>
#include "/usr/include/mysql/mysql.h"
#include "isq_gserver_define.h"
extern "C"
{
    #include <stdio.h>
    #include "lua.h"
    #include "lualib.h"
    #include "lauxlib.h"
}

struct DATABASE
{
    MYSQL* ms;
};

int c_mysql(lua_State *L);
char* reload_lua(lua_State* L,char* path);

// ------------------------------------------------------------------------
int DBConnect(lua_State *L);
int DBClose(lua_State *L);

#endif // __ISQ_DATABASE_H__
