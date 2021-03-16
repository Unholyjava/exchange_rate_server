%%%-------------------------------------------------------------------
%% @doc exchange_rate_server public API
%% @end
%%%-------------------------------------------------------------------

-module(exchange_rate_server_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Port = 8080,
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/api/exchange_rate_server", data_handler, []}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(http, [{port, Port}], #{
        env => #{dispatch => Dispatch}
    }),

    case exchange_rate_server_sup:start_link() of
        {ok, Pid} ->
            {ok, Pid};
        Other ->
            {error, Other}
    end.

stop(_State) ->
    ok = cowboy:stop_listener(http).

