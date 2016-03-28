-module(login).
-export([start_link/4, init/4]).

-define(SERVER, ?MODULE).


start_link(Ref, Socket, Transport, Opts) ->
	Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
	{ok, Pid}.

init(Ref, Socket, Transport, _Opts = []) ->
    io:format("income client, port = ~p, ~p ~n", [inet:port(Socket), Socket]),
	ok = ranch:accept_ack(Ref),
    Transport:setopts(Socket, [{active, once},{packet,4}]),
	loop(Socket, Transport).
    
loop(Socket, Transport) ->
    receive
        {tcp, Socket, _Data} ->
            loop(Socket, Transport);

        {tcp_closed, Socket} ->
            Transport:close(Socket);

        _What ->
            Transport:close(Socket)
	end.

