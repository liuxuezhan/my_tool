-module(wscli_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================


start(_StartType, _StartArgs) ->
    {ok,Port} = application:get_env(wscli,port),
    {ok,Root} = application:get_env(wscli,docroot),
    Dispatch = cowboy_router:compile([
                                      {'_', [
                                                {"/", index, []},
                                                {"/ws", wscli, []},
			                                    %{"/[...]", cowboy_static, {priv_dir, wscli, "", [{mimetypes, cow_mimetypes, all}]}}
			                                    {"/[...]", cowboy_static, {dir, Root}}

                                            ]}
                                     ]),

    {ok, _} = cowboy:start_http(http, 100, [
                                            {port, Port}
                                           ],
                                [
                                 {env, [{dispatch, Dispatch}]}
                                ]),

    wscli_sup:start_link().

stop(_State) ->
    ok.
