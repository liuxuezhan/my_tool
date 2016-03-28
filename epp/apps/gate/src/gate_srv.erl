-module(gate_srv).
-export([start_link/4, init/4]).

-define(SERVER, ?MODULE).
-include("../../include/common.hrl").
-import(tools, [ getSrv/1, getCli/1, getPlayer/1 ]).

start_link(Ref, Socket, Transport, Opts) ->
	Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
	{ok, Pid}.

init(Ref, Socket, Transport, _Opts = []) ->
	ok = ranch:accept_ack(Ref),
    erlang:process_flag(priority, high),
    process_flag(trap_exit, true),
    put(sock, Socket),
    put(tran, Transport),
    put(sid, self()),

    ?INFO("income server, port = ~p, ~p", [inet:port(Socket), Transport:peername(Socket)]),

    Transport:setopts(Socket, [{active, true},{packet,raw}, {delay_send, true}]),
	loop(Socket, Transport, <<>>).


loop(Socket, Transport, Remain) ->
    receive
        {tcp, Socket, Data} ->
            Remain2 = split_packet(<< Remain/binary, Data/binary >>),
            loop(Socket, Transport, Remain2);

        {send, Data} ->
            Transport:send(Socket, Data),
            loop(Socket, Transport, Remain);

        {'DOWN', _Ref, process, Hid, Reason} ->
            case get(Hid) of
                undefined -> 
                    ?WARN("'EXIT', Hid=~p, Reason=~p", [ Hid, Reason]);

                Pid -> 
                    ?INFO("EXIT, Pid=~p, Hid=~p, Reason=~p", [Pid, Hid, Reason]),
                    erase(Pid),
                    erase(Hid),
                    Transport:send(Socket, << 8:32/big, Pid:32/big, ?NET_MSG_CLOSE:32/big >> )
            end,
            loop(Socket, Transport, Remain);
            
        {'EXIT', Hid, Reason} ->
            case get(Hid) of
                undefined -> 
                    ?WARN("'EXIT', Hid=~p, Reason=~p, cann't found hid", [ Hid, Reason]);

                Pid -> 
                    erase(Hid),
                    case get(Pid) of
                        Hid ->
                            ?INFO("EXIT, Pid=~p, Hid=~p, Reason=~p", [Pid, Hid, Reason]),
                            erase(Pid),
                            Transport:send(Socket, << 8:32/big, Pid:32/big, ?NET_MSG_CLOSE:32/big >> );
                        Other ->
                            ?INFO("EXIT, Pid=~p, Hid=~p, Reason=~p, dup=~p, already duplicate, do nothing", [Pid, Hid, Reason, Other])
                    end
            end,
            loop(Socket, Transport, Remain);
           
        {join, Pid, Hid} ->
            case get(Pid) of
                undefined ->
                    ok;
                Old ->
                    Old ! {duplicate, Pid},
                    erase(Pid),
                    erase(Old)
            end,
            put(Pid, Hid),
            put(Hid, Pid),
            ?INFO("pid ~p (~p) join map ~p", [Pid,Hid,get(map)]),
            erlang:link(Hid),
            loop(Socket, Transport, Remain);

        {tcp_closed, Socket} ->
            ?INFO("srv close, map=~p", [get(map)]);

        What ->
            ?WARN("srv loop recve msg ~p, map=~p~n", [What, get(map)])

	end.


split_packet(Data) ->
    case size(Data) >= 12 of
        true ->
            << Len:32/big, Remain/binary >> = Data,
            case size(Remain) >= Len of
                true ->
                    LenP = Len - 4,
                    << Pid:32/big, Msg:LenP/binary, Remain2/binary >> = Remain,
                    if 
                        Pid == 0 -> 
                            << Cmd:32/big, Body/binary >> = Msg,
                            doCmd(Cmd, Body);
                        true ->
                            sendToCli(Pid, Msg)
                    end,
                    split_packet(Remain2);
                _ ->
                    Data
            end;
        _ ->
            Data
    end.


sendToCli(Pid, Msg) ->
    case getCli(Pid) of
        no -> 
            ?WARN("not found player pid=~p", [Pid]),
            no;
        Hid ->
            Hid ! { send, Msg }
    end.

doCmd(?NET_SET_MAP_ID, Body) ->
    << Map:32/big >> = Body,
    R = #srv{id=Map, hid=self()},
    ?INFO("set_map_id, map=~p", [Map]),
    ets:insert(esrv, R),
    put(map, Map),
    ok;

doCmd(?NET_SET_SRV_ID, Body) ->
    << Pid:32/big, Mid:32/big, Len:16/big, Proc:Len/binary >> = Body,
    ?INFO("set_srv_id, pid=~p, mid=~p, proc=~p", [Pid, Mid, Proc]),
    Hid = list_to_pid(binary_to_list(Proc)),
    case is_process_alive(Hid) of
        true ->
            Hid ! {setSrvId, Pid, Mid};
        _ ->
            ?WARN("hid ~p not exist", [Hid])
    end;

doCmd(?NET_CERTIFY, Body) ->
    << Code:32/big, Len:16/big, Proc:Len/binary >> = Body,
    ?INFO("certify, code=~p, proc=~p", [Code, Proc]),
    Hid = list_to_pid(binary_to_list(Proc)),
    case is_process_alive(Hid) of
        true ->
            Hid ! {certify, Code};
        _ ->
            ?WARN("hid ~p not exist", [Hid])
    end;


doCmd(?NET_CHG_SRV, Body) ->
    << Mid:32/big, Len:16/big, Proc:Len/binary >> = Body,
    ?INFO("chg_srv_id, mid=~p, proc=~p", [Mid, Proc]),
    Hid = list_to_pid(binary_to_list(Proc)),
    case is_process_alive(Hid) of
        true ->
            Hid ! {chgSrvId, Mid};
        _ ->
            ?WARN("hid ~p not exist", [Hid])
    end;

doCmd(?NET_GM_CMD, Body) ->
    <<Len:16/big, Proc:Len/binary, Ack/binary >> = Body,
    Hid = list_to_pid(binary_to_list(Proc)),
    case is_process_alive(Hid) of
        true ->
            Hid ! {gmCmd, Ack};
        _ ->
            ?WARN("hid ~p not exist", [Hid])
    end;


doCmd(?PT_onQryCross, Body) ->
    <<ToPid:32/big-signed, Sn:32/big, _/binary >> = Body,
    case ToPid > 0 of
        true -> 
            case getPlayer(ToPid) of
                no -> Mid = 0;
                A -> Mid = A#cli.map
            end;
        _ ->
            Mid = -ToPid
    end,

    case getSrv(Mid) of
        no -> 
            case Sn > 0 of
                true ->
                    Msg = << 0:32/big, ?PT_onAckCross:32/big, ToPid:32/big, Sn:32/big, -1:32/big, 1:32/big, 192 >>,
                    Len = size(Msg),
                    get(sid) ! {send, << Len:32/big, Msg/binary >> };
                _ ->
                    none
            end;

        Hid -> 
            Msg = << 0:32/big, ?PT_onQryCross:32/big, Body/binary >>,
            Len = size(Msg),
            Hid ! {send, << Len:32/big, Msg/binary >> }
    end;

doCmd(?PT_onAckCross, Body) ->
    <<Mid:32/big, _/binary >> = Body,
    case getSrv(Mid) of
        no ->
            no;
        Hid ->
            Msg = << 0:32/big, ?PT_onAckCross:32/big, Body/binary >>,
            Len = size(Msg),
            Hid ! {send, << Len:32/big, Msg/binary >> }
    end;

doCmd(Cmd, Body) ->
    ?WARN("Cmd=~p, Body=~p~n", [Cmd, Body]),
    ok.

