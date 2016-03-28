-module(gate_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).
%-include("common.hrl").
-include("../../include/common.hrl").

%% ===================================================================
%% Application callbacks
%% ===================================================================


ping_data(Master) ->
    case net_adm:ping(Master) of
        pong -> 
            ?INFO("net_adm:ping(~p) = ~p", [Master, pong]),
            ok;
        What -> 
            ?WARN("net_adm:ping(~p) = ~p", [Master, What]),
            timer:sleep(2000),
            ping_data(Master)
    end.

join_dbm() ->
    gen_server:cast({global, data}, {joinDbm, self(), node()}),
    receive
        start ->
            receive 
                accomplete -> 
                    ?INFO("~p join_dbm, accomplete", [node()]),
                    ok
            after 10000 ->
                no
            end;
        accomplete ->
            ok
    after 2000 ->
        ?WARN("join_dbm, timeout"),
        join_dbm()
    end.

start(_StartType, _StartArgs) ->
    lager:set_loglevel(lager_console_backend, debug),
    {ok,PortS} = application:get_env(gate, portSrv),
    {ok,PortC} = application:get_env(gate, portCli),
    {ok,DataM} = application:get_env(gate, dataMaster),
    {ok,DataC} = application:get_env(gate, dataCookie),

    erlang:set_cookie(node(),DataC),
    ping_data(DataM),

    application:stop(mnesia),
    mnesia:delete_schema([node()]),
    application:start(mnesia),

    timer:sleep(1000),
    join_dbm(),

    {ok, _Srv} = ranch:start_listener(srv, 32, ranch_tcp, [{port,PortS},{reuseaddr,true}], gate_srv, []),
    ?INFO("listen 8002, srv"),
    ranch:set_max_connections(srv, 1024),

    {ok, _Cli} = ranch:start_listener(cli, 64, ranch_tcp, [{port,PortC},{reuseaddr,true},{backlog,512}], gate_cli, []),
    ?INFO("listen 8001, cli"),
    ranch:set_max_connections(cli, 10240),

    gate_sup:start_link().

stop(_State) ->
    ok.
