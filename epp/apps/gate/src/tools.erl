-module(tools).
-include("../include/common.hrl").

-export([ getRec/2, getSrv/1, getCli/1, getPlayer/1 ]).

getRec(Tab, Key) ->
    case mnesia:dirty_read(Tab, Key) of
        [] -> no;
        {aborted, Reason} -> 
            ?WARN("what error ~p", [Reason]),
            no;
        [A] -> A
    end.

getSrv(MapId) ->
    case ets:lookup(esrv, MapId) of
        [] ->
            no;
        [A] ->
            A#srv.hid
    end.

getCli(Pid) ->
    case get(Pid) of
        undefined ->
            ?WARN("nohit Pid=~p", [Pid]),
            case ets:lookup(ecli, Pid) of
                [] ->
                    case getRec(cli, Pid) of
                        no -> no;
                        A -> A#cli.hid
                    end;
                [A] ->
                    A#cli.hid
            end;
        Hid ->
            Hid
    end.

getPlayer(Pid) ->
    case ets:lookup(ecli, Pid) of
        [] ->
            case mnesia:dirty_read(cli, Pid) of
                [] -> 
                    no;
                {aborted, Reason} -> 
                    ?WARN("what error ~p", [Reason]),
                    no;
                [A] -> A
            end;
        [A] ->
            A
    end.

