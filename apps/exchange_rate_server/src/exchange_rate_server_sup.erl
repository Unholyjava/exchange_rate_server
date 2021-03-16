%%%-------------------------------------------------------------------
%% @doc exchange_rate_server top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(exchange_rate_server_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
  Server = {exchange_rate_server, {exchange_rate_server, start_link, []},
    permanent, 2000, worker, [exchange_rate_server]},
  Children = [Server],
  RestartStrategy = {one_for_one, 0, 1},
  {ok, {RestartStrategy, Children}}.

