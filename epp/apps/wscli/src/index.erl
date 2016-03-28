-module(index).

-export([init/2]).

%init(_Transport, Req, []) ->
%	{ok, Req, undefined}.

init(Req, Opts) ->
	Html = get_html(),
	Req2 = cowboy_req:reply(200, [
		{<<"content-type">>, <<"text/html">>}
	], Html, Req),
	{ok, Req2, Opts}.

get_html() ->
    {ok,Home} = application:get_env(wscli,homepage),
    lager:info("Home = ~p", [Home]),
	{ok, Binary} = file:read_file(Home),
	Binary.

