-module(data).
-behaviour(gen_server).
-define(SERVER, ?MODULE).
-include("../include/common.hrl").

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0]).
-export([initDb/0]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(TableList,   [cli]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link() ->
    gen_server:start_link({global, ?SERVER}, ?MODULE, [], []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

initDb() ->
    ?INFO("----initDb----", []),
    application:stop(mnesia),
    mnesia:delete_schema([node()]),
    mnesia:create_schema([node()]),
    application:start(mnesia),

    mnesia:create_table(cli,   [ {ram_copies, [node()]}, {type, set}, {attributes, record_info(fields, cli)} ]),
    %mnesia:create_table(srv,   [ {ram_copies, [node()]}, {type, set}, {attributes, record_info(fields, srv)} ]),
    %mnesia:create_table(con,   [ {ram_copies, [node()]}, {type, set}, {attributes, record_info(fields, con)} ]),
    %mnesia:create_table(uniqid,[ {ram_copies, [node()]}, {type, set}, {attributes, record_info(fields, uniqid)} ]),
    %mnesia:dirty_write(uniqid, #uniqid{item=proc, uid=1}),
    %mnesia:dirty_update_counter(uniqid, proc, 1).
    ok.


init(Args) ->
    application:start(mnesia),
    initDb(),
    {ok, Args}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({joinDbm, From, Node}, State) ->
    From ! start,
    ?INFO("joinDbm, Node=~p", [Node]),
    addNode(Node),
    From ! accomplete,
    %rpc:call(Node, netcli, dbInitComplete, []),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

addNode(NewNode) ->  
    RunningNodeList = mnesia:system_info(running_db_nodes),  
    addExtraNode(RunningNodeList, NewNode),  
    _Rtn = mnesia:change_table_copy_type(schema, NewNode, disc_copies),  
    rpc:call(NewNode, mnesia, stop, []),  
    timer:sleep(1000),  
    rpc:call(NewNode, mnesia, start, []),  
    timer:sleep(1000),  
    addTableList(?TableList, NewNode),  
    ?INFO("-----------Over All---------~n").
  
addExtraNode([], _NewNode) ->  
    null;  

addExtraNode(_RunningNodeList = [Node | T], NewNode) ->  
    Rtn = rpc:call(Node, mnesia, change_config, [extra_db_nodes, [NewNode]]),  
    ?INFO("Node = ~p, Rtn=~p~n", [Node, Rtn]),  
    addExtraNode(T, NewNode).  
  
addTableList([], _NewNode) ->  
    null;  

addTableList(_TableList = [Table | T], NewNode) ->  
    Rtn = mnesia:add_table_copy(Table, NewNode, ram_copies),  
    ?INFO("Add Table ~p To ~p, Rtn = ~p~n", [Table, NewNode, Rtn]),  
    addTableList(T, NewNode).  


%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

