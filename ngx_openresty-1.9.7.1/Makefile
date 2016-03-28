.PHONY: all install clean

all:
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/LuaJIT-2.1-20151219 && $(MAKE) TARGET_STRIP=@: CCDEBUG=-g CC=cc PREFIX=/www/luajit
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-cjson-2.1.0.3 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/my_tool/ngx_openresty-1.9.7.1/build/luajit-root/www/luajit/include/luajit-2.1 LUA_CMODULE_DIR=/www/lualib LUA_MODULE_DIR=/www/lualib CJSON_CFLAGS="-g -fpic" CC=cc
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-redis-parser-0.12 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/my_tool/ngx_openresty-1.9.7.1/build/luajit-root/www/luajit/include/luajit-2.1 LUA_LIB_DIR=/www/lualib CC=cc
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-rds-parser-0.06 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/my_tool/ngx_openresty-1.9.7.1/build/luajit-root/www/luajit/include/luajit-2.1 LUA_LIB_DIR=/www/lualib CC=cc
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/nginx-1.9.7 && $(MAKE)

install: all
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/LuaJIT-2.1-20151219 && $(MAKE) install TARGET_STRIP=@: CCDEBUG=-g CC=cc PREFIX=/www/luajit DESTDIR=$(DESTDIR)
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-cjson-2.1.0.3 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/my_tool/ngx_openresty-1.9.7.1/build/luajit-root/www/luajit/include/luajit-2.1 LUA_CMODULE_DIR=/www/lualib LUA_MODULE_DIR=/www/lualib CJSON_CFLAGS="-g -fpic" CC=cc
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-redis-parser-0.12 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/my_tool/ngx_openresty-1.9.7.1/build/luajit-root/www/luajit/include/luajit-2.1 LUA_LIB_DIR=/www/lualib CC=cc
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-rds-parser-0.06 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/root/my_tool/ngx_openresty-1.9.7.1/build/luajit-root/www/luajit/include/luajit-2.1 LUA_LIB_DIR=/www/lualib CC=cc
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-dns-0.14 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-memcached-0.13 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-redis-0.22 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-mysql-0.15 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-string-0.09 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-upload-0.09 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-websocket-0.05 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-lock-0.04 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-lrucache-0.04 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-core-0.1.3 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/lua-resty-upstream-healthcheck-0.03 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/www/lualib INSTALL=/root/my_tool/ngx_openresty-1.9.7.1/build/install
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/resty-cli-0.05 && /root/my_tool/ngx_openresty-1.9.7.1/build/install resty $(DESTDIR)/www/bin/
	cd /root/my_tool/ngx_openresty-1.9.7.1/build/nginx-1.9.7 && $(MAKE) install DESTDIR=$(DESTDIR)

clean:
	rm -rf build
