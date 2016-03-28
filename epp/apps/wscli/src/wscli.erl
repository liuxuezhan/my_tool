-module(wscli).

-export([init/2]).
-export([websocket_handle/3]).
-export([websocket_info/3]).

-include("../../include/common.hrl").

init(Req, Opts) ->
	%erlang:start_timer(1000, self(), <<"Hello!">>),
	{cowboy_websocket, Req, Opts}.

websocket_handle({text, Msg}, Req, State) ->
    Info = jsx:decode(Msg),
    Cmd = proplists:get_value(<<"_CMD_">>, Info, 0),
    Reply = doCli(Cmd, Info),
    case Reply of
        nil ->
            {ok, Req, State};
        _ ->
            {reply, {text, Reply}, Req, State}
    end;

websocket_handle(_Data, Req, State) ->
	{ok, Req, State}.

websocket_info({timeout, _Ref, Msg}, Req, State) ->
	erlang:start_timer(1000, self(), <<"How' you doin'?">>),
	{reply, {text, Msg}, Req, State};

websocket_info({tcp,_Sock,Data}, Req, State) ->
    %===========================================================================================================
    Cmds = [ "onLogin", "say", "say1", "qryInfo", "loadData", "tips", "chat", "qryAround", "addEty", "remEty", "stateBuild", "statePro", "stateEf", "fightInfo", "gmCmd"],
    %===========================================================================================================
    << Cmd:32/big, Body/binary >> = Data,
    Res = tryRecv(Cmd, Cmds, Body),
    case Res of
        nil -> {ok, Req, State};
        _ -> {reply, {text, Res}, Req, State}
    end;

websocket_info(Info, Req, State) ->
    ?INFO("what info ~p", [Info]),
	{ok, Req, State}.

tryRecv(Cmd, Cmds, Body) ->
    case Cmds of 
        [] -> 
            %%Val = base64:encode_to_string(Body),
            Val = base64:encode(Body),
            jsx:encode([ {<<"Cmd">>, Cmd}, {<<"base64">>, Val} ]);

        [A|Bs] ->
            Hash = hashStr(A),
            if
                Hash == Cmd -> doSrv(A, Body);
                true -> tryRecv(Cmd, Bs, Body)
            end
    end.

%%%%%%%%%%% doSrv &&&&&&&&&&&&
%%%%%%%%%%% doSrv &&&&&&&&&&&&
%%%%%%%%%%% doSrv &&&&&&&&&&&&

doSrv("onLogin", Body) ->
    << Pid:32/big, Len:16/big, Name:Len/binary >> = Body,
    jsx:encode([ {<<"Recv">>, <<"onlogin">>}, {<<"pid">>, Pid}, {<<"name">>, Name} ]);

doSrv("qryInfo", Body) ->
    << Len:32/big, Val:Len/binary >> = Body,
    {ok, Info} = msgpack:unpack(Val, [jsx]),
    ?INFO("unpack ~p", [Info]),
    jsx:encode([ {<<"Recv">>, <<"qryInfo">>}, {<<"info">>, Info}]);

doSrv("loadData", Body) ->
    << Len:32/big, Val:Len/binary >> = Body,
    {ok, Info} = msgpack:unpack(Val, [jsx]),
    ?INFO("unpack ~p", [Info]),
    jsx:encode([ {<<"Recv">>, <<"loadData">>}, {<<"info">>, Info}]);

doSrv("say1", Body) ->
    << Len:16/big, Say:Len/binary, Nouse:32/big >> = Body,
    jsx:encode([ {<<"Recv">>, <<"say1">>}, {<<"say">>, Say}, {<<"nouse">>, Nouse} ]);

doSrv("tips", Body) ->
    << Len:16/big, Tip:Len/binary >> = Body,
    jsx:encode([ {<<"Recv">>, <<"tips">>}, {<<"Tip">>, Tip} ]);


doSrv("chat", Body) ->
    << Pid:32/big, Lname:16/big, Name:Lname/binary, Lword:16/big, Word:Lword/binary >> = Body,
    jsx:encode([ {<<"Recv">>, <<"chat">>}, {<<"Pid">>, Pid}, {<<"name">>, Name}, {<<"word">>, Word} ]);

doSrv("qryAround", Body) ->
    << X:32/big, Y:32/big, Len:32/big, Val:Len/binary >> = Body,
    {ok, Info} = msgpack:unpack(Val, [jsx]),
    jsx:encode([ {<<"Recv">>, <<"qryAround">>}, {<<"x">>, X}, {<<"y">>, Y}, {<<"info">>, Info}]);

doSrv("addEty", Body) ->
    << Len:32/big, Val:Len/binary >> = Body,
    {ok, Info} = msgpack:unpack(Val, [jsx]),
    ?INFO("addEty, Info=~p", [Info]),
    jsx:encode([ {<<"Recv">>, <<"addEty">>}, {<<"info">>, Info}]);

doSrv("remEty", Body) ->
    << Eid:32/big >> = Body,
    jsx:encode([ {<<"Recv">>, <<"remEty">>}, {<<"eid">>, Eid}]);


doSrv("stateEf", Body) ->
    << Len:32/big, Val:Len/binary >> = Body,
    {ok, Info} = msgpack:unpack(Val, [jsx]),
    jsx:encode([ {<<"Recv">>, <<"stateEf">>}, {<<"info">>, Info}]);

doSrv("statePro", Body) ->
    << Len:32/big, Val:Len/binary >> = Body,
    {ok, Info} = msgpack:unpack(Val, [jsx]),
    jsx:encode([ {<<"Recv">>, <<"statePro">>}, {<<"info">>, Info}]);

doSrv("stateBuild", Body) ->
    << Len:32/big, Val:Len/binary >> = Body,
    {ok, Info} = msgpack:unpack(Val, [jsx]),
    jsx:encode([ {<<"Recv">>, <<"stateBuild">>}, {<<"info">>, Info}]);

doSrv("fightInfo", Body) ->
    << Len:32/big, Val:Len/binary >> = Body,
    {ok, Info} = msgpack:unpack(Val, [jsx]),
    jsx:encode([ {<<"Recv">>, <<"fightInfo">>}, {<<"info">>, Info}]);

doSrv("gmCmd", Body) ->
    << Len:16/big, Val:Len/binary >> = Body,
    jsx:encode([ {<<"Recv">>, <<"gmCmd">>}, {<<"info">>, Val}]);

doSrv(_Cmd, _Body) ->
    nil.

%%%%%%%%%%% doCli &&&&&&&&&&&&
%%%%%%%%%%% doCli &&&&&&&&&&&&
%%%%%%%%%%% doCli &&&&&&&&&&&&

doCli(<<"firstPacket">>, Info) ->
    case get(sock) of
        undefined ->
            ok;
        Sock ->
            gen_tcp:close(Sock),
            erase(sock)
    end,

    Uid =  proplists:get_value(<<"uid">>, Info, 1),
    Name = proplists:get_value(<<"name">>, Info, <<"">>),
    Pasw = proplists:get_value(<<"pasw">>, Info, <<"">>),
    sendTo("firstPacket", [Uid, Name, Pasw]),
    nil;

doCli(<<"hashStr">>, Info) ->
    As = proplists:get_value(<<"strs">>, Info, <<"[]">>),
    ?INFO("As = ~p", [As]),
    Strs = jsx:decode(proplists:get_value(<<"strs">>, Info, <<"[]">>)),
    Fun = fun(Elem, Acc) ->
                  Cmd = hashStr(Elem),
                  [Cmd|Acc]
          end,
    Cmds = lists:foldr(Fun, [], Strs),
    jsx:encode([ {<<"Strs">>, Strs}, {<<"Cmds">>, Cmds} ]);

doCli(<<"gmCmd">>, Info) ->
    Time =  proplists:get_value(<<"time">>, Info, 1),
    ChSum = proplists:get_value(<<"checksum">>, Info, 1),
    Val = proplists:get_value(<<"command">>, Info, <<"">>),
    sendTo("gmCmd", [Time, ChSum, Val]),
    nil;

doCli(<<"seige">>, Info) ->
    Deid = proplists:get_value(<<"deid">>, Info, <<"2">>),
    Troops = jsx:decode(proplists:get_value(<<"troops">>, Info, <<"{}">>)),
    ?INFO("seige, Troops = ~p", [Troops]),
    T3 = msgpack:pack(Troops, [{format,jsx}]),
    ?INFO("T3 = ~p", [T3]),

    %%T4 = msgpack:unpack(T3),
    %%?INFO("T4 = ~p", [T4]),

    %%Len = size(T3),
    %%Cid = hashStr("seige"),
    %%gen_tcp:send(get(sock), <<Cid:32/big, Deid:32/big, Len:32/big, T3/binary >>),

    sendTo("seige", [ Deid, T3 ]),

    nil;

doCli(<<"restart">>, _Info) ->
    ok;

doCli(Cmd, Info) ->
    ?INFO("Cmd = ~p, Info = ~p", [Cmd, Info]),
    Info1 = proplists:delete(<<"_CMD_">>, Info),
    Fun = fun(Elem, Acc) ->
                  {_, Val} = Elem,
                  [Val|Acc]
          end,
    Param = lists:foldr(Fun, [], Info1),
    sendTo(Cmd, Param),
    nil.

packArgs(Params, Acc) ->
    case Params of
        [] -> 
            Acc;
        [A|B] ->
            if
                is_integer(A) -> packArgs(B, << Acc/binary, A:32/big >>);
                is_float(A) -> packArgs(B, << Acc/binary, A:32/float >>);
                is_binary(A) -> 
                    Len = size(A),
                    packArgs(B, << Acc/binary, Len:16/big, A/binary >>);
                is_bitstring(A) ->
                    A1 = list_to_binary(A),
                    Len = size(A1),
                    packArgs(B, << Acc/binary, Len:16/big, A1/binary >>)
        end
    end.


sendTo(Cmd, Params) ->
    ?INFO("sendTo Cmd=~p, Params=~p", [Cmd, Params]),
    case get(sock) of
        undefined ->
            {ok,Host} = application:get_env(wscli,gatehost),
            {ok,Port} = application:get_env(wscli,gateport),
            {ok,Sock} = gen_tcp:connect(Host, Port, [binary,{packet,4},{active,true}]),
            put(sock, Sock);
        _ ->
            ok
    end,

    if
        is_list(Cmd) -> Cid = hashStr(Cmd);
        is_binary(Cmd) -> Cid = hashStr(Cmd);
        is_integer(Cmd) -> Cid = Cmd
    end,
    Args = packArgs(Params, <<>>),
    gen_tcp:send(get(sock), << Cid:32/big, Args/binary >>).


hashStr(Str) when is_list(Str) ->
    hashStr(list_to_binary(Str));

hashStr(Str) when is_binary(Str) ->
    doHash(2166136261, Str).

doHash(Hash, Str) ->
    case size(Str) > 0 of
        true ->
            << A:8/unsigned-integer, Remain/binary >> = Str,
            Hash1 = (Hash bxor A) * 16777619,
            doHash(Hash1, Remain);
        _ ->
            Hash band 16#7FFFFFFF
    end.

