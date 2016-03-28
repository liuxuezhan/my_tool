-module(gate_cli).
-export([start_link/4, init/4]).

-define(SERVER, ?MODULE).

-include("../../include/common.hrl").

-import(tools, [ getSrv/1 ]).

start_link(Ref, Socket, Transport, Opts) ->
	Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
	{ok, Pid}.

init(Ref, Socket, Transport, _Opts = []) ->
    ?INFO("income client, port = ~p, ~p", [inet:port(Socket), Transport:peername(Socket)]),
	ok = ranch:accept_ack(Ref),
    Transport:setopts(Socket, [{active, once},{packet,4}, {delay_send, true}]),
	shake(Socket, Transport),
    case get(pid) of
        undefined -> 
            ok;
        Pid ->
            case get(dup) of
                true ->
                    ?WARN("duplicate exit, self_pid=~p, self=~p", [Pid, self()]),
                    ok;
                _ ->
                    ets:delete(ecli, Pid),
                    mnesia:dirty_delete(cli, Pid)
            end
    end.

shake(Socket, Transport) ->
    receive 
        {tcp, Socket, Data} ->
            << Cmd:32/big, _/binary >> = Data,
                case Cmd of
                    ?NET_FIRST_PACKET ->
                        ?INFO("data=~p", [Data]),
                        <<_:32/big, M:32/big, _/binary>> = Data,
                        case getSrvRandom(M) of
                            no ->
                                Transport:close(Socket);
                            Tid ->
                                Pid = list_to_binary(pid_to_list(self())),
                                Lpid = size(Pid),
                                Packet = <<0:32/big, Data/binary, Lpid:16/big, Pid/binary, 20100731:32/big>>,
                                put(fstPck, Packet),
                                Len = size(Packet),
                                Tid ! {send, << Len:32/big, Packet/binary >>},
                                shake(Socket, Transport)
                        end;

                    ?NET_GM_CMD ->
                        << Cmd:32/big, Srv:32/big, _/binary >> = Data,
                        case getSrv(Srv) of
                            no -> 
                                ok;
                            Tid ->
                                Pid = list_to_binary(pid_to_list(self())),
                                Lpid = size(Pid),
                                Packet = <<0:32/big, Data/binary, Lpid:16/big, Pid/binary, 20100731:32/big>>,
                                Len = size(Packet),
                                Tid ! {send, << Len:32/big, Packet/binary >>},
                                shake(Socket, Transport)
                        end;

                    _ ->
                        ?WARN("Not first packet, Data=~p~n", [Data])
                end;

        {chgSrvId, Mid} ->
            case getSrv(Mid) of
                no ->
                    ?WARN("Not found Mid=~p~n", [Mid]),
                    Transport:close(Socket);

                Tid ->
                    Packet = get(fstPck),
                    Len = size(Packet),
                    Tid ! {send, << Len:32/big, Packet/binary >>},
                    shake(Socket, Transport)
            end;

        {gmCmd, Val} ->
            Packet = << ?NET_GM_CMD:32/big, Val/binary >>,
            Transport:send(Socket, Packet),
            shake(Socket, Transport);

        {certify, Code} ->
            Packet = << ?NET_CERTIFY:32/big, Code:32/big >>,
            Transport:send(Socket, Packet),
            shake(Socket, Transport);

        {setSrvId, Pid, Mid} ->
            case getSrv(Mid) of
                no ->
                    ?WARN("Not found Mid=~p~n", [Mid]),
                    Transport:close(Socket);
                Sid ->
                    erase(fstPck),
                    process_flag(trap_exit, true),
                    put(sid, Sid),
                    put(pid, Pid),
                    put(map, Mid),
                    Sid ! {join, Pid, self()},

                    R = #cli{id=Pid, hid=self(), map=Mid},
                    mnesia:dirty_write(cli, R),
                    ets:insert(ecli, R),

                    Transport:setopts(Socket, [{active, once}]),
                    Len = 8,
                    Sid ! {send, << Len:32/big, Pid:32/big, ?NET_LOGIN:32/big >> },
                    loop(Socket, Transport)
            end;

        What ->
            Transport:close(Socket),
            ?WARN("shake recve msg ~p~n", [What])
    end.

getSrvRandom(M) ->
    case getSrv(M) of
        no -> 
            ?INFO("map ~p not found, random", [M]),
            getSrvRandom();
        Sid -> 
            ?INFO("map ~p found, hit", [M]),
            Sid
    end.
    
getSrvRandom() ->
    Ns = ets:match(esrv, {'_', '_', '$2'}),
    Num = length(Ns),
    R = erlang:system_time(seconds),
    Idx = (R rem Num) + 1,
    [ Sid ] = lists:nth(Idx, Ns),
    Sid.

loop(Socket, Transport) ->
    receive
        {tcp, Socket, Data} ->
            << Cmd:32/big, _/binary >> = Data,
            case Cmd of
                ?NET_ECHO ->
                    Transport:send(Socket, Data);
                _ ->
                    sendToSrv(Data)
            end,
            %% flow control
            Transport:setopts(Socket, [{active, once}]),
            loop(Socket, Transport);

        {send, Data} ->
            Transport:send(Socket, Data),
            loop(Socket, Transport);

        {tcp_closed, Socket} ->
            Transport:close(Socket),
            ?INFO("client close, pid=~p, ~p", [get(pid), Transport:peername(Socket)]);

        {'EXIT', Hid, Reason} ->
            case get(sid) of
                Hid ->
                    erase(sid),
                    Pid=get(pid),
                    rand:seed(exs1024, {Pid, Pid*2166136261, Pid*16777619}),
                    Wait = rand:uniform(10000),
                    ?WARN("map down, Reason=~p, pid=~p, wait=~p", [ Reason, get(pid), Wait]),
                    timer:send_after(Wait, {check_map, get(map)});
                _ ->
                    ok
            end,
            loop(Socket, Transport);

        {check_map, Map} ->
            case getSrv(Map) of
                no -> 
                    ?WARN("Map ~p still down, pid=~p", [Map,get(pid)]),
                    timer:send_after(5000, {check_map, get(map)});
                Sid ->
                    case is_process_alive(Sid) of
                        true ->
                            put(sid, Sid),
                            Sid ! {join, get(pid), self()},
                            ?INFO("rejoin map=~p, pid=~p", [Map, get(pid)]),
                            case get(pend) of
                                undefined ->
                                    ok;
                                Pends ->
                                    lists:foreach(
                                        fun(Pack) -> 
                                            Sid ! {send, Pack} 
                                        end,
                                        lists:reverse(Pends)
                                    ),
                                    erase(pend)
                            end;
                        _ ->
                            ?WARN("Map ~p still down, pid=~p", [Map,get(pid)]),
                            timer:send_after(5000, {check_map, get(map)})
                    end
            end,
            loop(Socket, Transport);

        {duplicate, Pid} ->
            ?WARN("duplicate, self_pid=~p, ack_pid=~p, self=~p", [get(pid), Pid, self()]),
            put(dup, true);

        What ->
            Transport:close(Socket),
            ?WARN("cli loop recve msg ~p", [What])
	end.

sendToSrv(Msg) ->
    Pid = get(pid),
    Len = size(Msg) + 4,
    Packet = <<Len:32/big, Pid:32/big, Msg/binary>>,
    case get(sid) of
        undefined ->
            case get(pend) of
                undefined ->
                    put(pend, [ Packet ]);
                Pend ->
                    put(pend, [ Packet | Pend ])
            end;
        Sid ->
            Sid ! { send, Packet }
    end.

