# A simple makefile generator by KiSoft, 2007. mailto: kisoft@rambler.ru

# Project Variables start
CPP=g++
CC=gcc
LD=g++
LIB=ar


MYSQL_INC="/usr/include/mysql"
MYSQL_LIB="/usr/lib64/mysql/"

LUA_INC="/usr/local/include"
LUA_LIB="/usr/local/lib"

BOOST_INC="/usr/local/include"
BOOST_LIB="/usr/local/lib/"

BASE=$(PWD)
BASE_SOURCE=$(BASE)/source
BINPATH=$(BASE)/../bin

OBJPATH=$(BASE)/obj
VPATH=$(BASE_SOURCE):$(OBJPATH):$(BASE):$(BINPATH)


ifeq ($(mode),debug)
	CFLAGS = -rdynamic -Wall -Wconversion -Wextra -Wstack-protector -ggdb3 -fexceptions -fstack-protector-all -Wstack-protector -D__DEBUG__
else
	CFLAGS = -rdynamic -Wall -Wconversion -Wextra
endif

INCDIR = -I $(MYSQL_INC) -I $(LUA_INC) -I $(BOOST_INC)  -I../include -I./include -I./source
LIBDIR =  -Wl,-rpath=../bin/:$(MYSQL_LIB)  -L../../bin/ -L$(BOOST_LIB)  -L$(MYSQL_LIB) -L$(LUA_LIB)
LIBFILE = -lpthread -lboost_system -lboost_thread-mt -lmysqlclient $(LUA_LIB)/liblua.a -lm -DLUA_USE_READLINE -ldl
OBJS=main.o \
     isq_gserver_mgr.o \
     isq_receiver.o \
     isq_sender.o \
     isq_database.o

TARGET=../../bin_gserver/isq_gserver1.1

# Project Variables end

Debug: $(TARGET)

$(TARGET): $(OBJS)
	@echo Building dynamic library $(TARGET)
	@cd $(OBJPATH);	$(LD) -o $(TARGET) $(OBJS) $(LIBDIR) $(LIBFILE)

all: $(OBJS)
$(OBJS): %.o: %.cpp
	@echo $(PWD)
	$(LD) -c $(CFLAGS) -g $(INCDIR) $< -o $(OBJPATH)/$@

.PHONY: clean

clean:
	@echo Delete $(OBJS) $(TARGET)
	@cd $(OBJPATH); rm -f $(OBJS) $(TARGET)
