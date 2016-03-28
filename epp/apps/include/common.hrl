-record(cli, {id=0,hid=0,map=0}). %% pid to process id
-record(srv, {id=0,hid=0}). %% mid to process id
%-record(con, {id=0,hid=0}). %% uniq id to process id
%-record(uni, {id=0,val=0}). %% just for get uniqid to table con
%-record(pro, {id=0,pid=0}). %% process id to player id, for gate_srv find the pid to be remove from local dictionry

%-record(uniqid, {item, uid}).

-define(NET_PING        , 1).
-define(NET_PONG        , 2).
-define(NET_ADD_LISTEN  , 3).
-define(NET_ADD_INCOME  , 4).
-define(NET_CMD_CLOSE   , 5).
-define(NET_MSG_CLOSE   , 6 ).
-define(NET_CMD_STOP    , 7).
-define(NET_SET_MAP_ID  , 8).
-define(NET_SET_SRV_ID  , 9).
-define(NET_MSG_CONN_COMP , 10 ).
-define(NET_MSG_CONN_FAIL  , 11).
-define(NET_ECHO  , 12).
-define(NET_CHG_SRV  , 13).
-define(NET_CERTIFY  , 14).

-define(NET_FIRST_PACKET, 1122052733).
-define(NET_LOGIN, 1233071922).
-define(NET_GM_CMD, 1916553151).

-define(PT_onQryCross, 313726030).
-define(PT_onAckCross, 1458768439).


-define (LOG, lager:debug).
-define (INFO, lager:info).
-define (WARN, lager:error).

