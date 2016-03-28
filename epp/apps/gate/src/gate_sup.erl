-module(gate_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

-include("../../include/common.hrl").

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    ets:new(ecli, [public, set, named_table, {write_concurrency, true}, {read_concurrency, true}, {keypos, #cli.id}]),
    ets:new(esrv, [public, set, named_table, {write_concurrency, true}, {read_concurrency, true}, {keypos, #srv.id}]),
    {ok, { {one_for_one, 500, 500}, []} }.

