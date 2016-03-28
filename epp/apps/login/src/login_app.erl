-module(login_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    ok = application:start(bson),
    ok = application:start(crypto),
    ok = application:start(mongodb),
    %ok = application:start(dbcon),
    {ok, Cli} = ranch:start_listener(login, 64, ranch_tcp, [{port,8000},{reuseaddr,true},{backlog,512}], login, []),
    ranch:set_max_connections(login, 10240),
    login_sup:start_link().

stop(_State) ->
    ok.
