%%%-------------------------------------------------------------------
%%% @author Gregory
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. бер 2021 22:54
%%%-------------------------------------------------------------------
-module(exchange_rate_server).
-author("gregory").
-behaviour(gen_server).

%% API
-export([start_link/0, init/1, handle_call/3,
  handle_cast/2, handle_info/2, terminate/2,
  stop/0, insert_rates/1, show_all_rates/0]).


start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
  gen_server:cast(?MODULE, {create_rate_table}),
  {ok, #{life_period => 60, life_status => old}}.

insert_rates(Rates) ->
  gen_server:cast(?MODULE, {add, Rates}).

show_all_rates() ->
  gen_server:call(?MODULE, {read_all}).

stop() ->
  gen_server:call(?MODULE, terminate).

handle_call({read_all}, _From, #{life_status := new} = State) ->
  io:format("Output data from etsDB ~n"),
  [Rate_number] = lists:max(ets:match(rate_table, {'_','$1'})),
  Reply = {ok, from_ets, read_all_data(Rate_number)},
  {reply, Reply, State};

handle_call({read_all}, _From, #{life_status := old} = State) ->
  io:format("Output data from PBServer ~n"),
  Reply = response_PBServer(httpc:request("https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=5")),
  {reply, Reply, State};

handle_call(terminate, _From, State) ->
  {stop, normal, ok, State};

handle_call(Msg, _From, State) ->
  io:format("Unexpected message in handle_call ~p~n", [Msg]),
  {reply, Msg, State}.

handle_cast({create_rate_table}, State) ->
  io:format("Create table ~n"),
  ets:new(rate_table, [duplicate_bag, public, named_table, {keypos, 2}]),
  {noreply, State};

handle_cast({add, Rates}, State) ->
  io:format("Adds ~p into table ~n", [Rates]),
  list_to_ets(Rates, State),
  New_State = State#{life_status => new},
  erlang:start_timer(maps:get(life_period, New_State) * 1000, ?MODULE, data_timeout),
  {noreply, New_State};

handle_cast(Msg, State) ->
  io:format("Unexpected message in handle_cast ~p~n", [Msg]),
  {noreply, State}.

handle_info({timeout, _Ref, data_timeout}, State) ->
  New_State = State#{life_status => old},
  ets:delete_all_objects(rate_table),
  {noreply, New_State};

handle_info(Msg, State) ->
  io:format("Unexpected message in handle_info ~p~n", [Msg]),
  {noreply, State}.

terminate(normal, State) ->
  io:format("work with the server has finished ~p~n",[State]),
  ok.


list_to_ets(Rates, State) ->
  list_to_ets(Rates, 0, State).

list_to_ets([], _Number_of_rows, _State) ->
  true;

list_to_ets([H|T], Number_of_rows, State) ->
  Rates_plus_order = [{A, Number_of_rows + 1} || A <- H],
  ets:insert(rate_table, Rates_plus_order),
  list_to_ets(T, Number_of_rows + 1, State).

read_all_data(Rate_Number) ->
  read_all_data(Rate_Number, []).

read_all_data(0, Acc) ->
  Acc;

read_all_data(Rate_Number, Acc) ->
  read_all_data(Rate_Number - 1, [ets:lookup_element(rate_table, Rate_Number, 1) | Acc]).

response_PBServer({ok, {_Status, _Header, Body}}) ->
  List_Body = jsx:decode(list_to_binary(Body), [{return_maps, false}]),
  insert_rates(List_Body),
  {ok, from_PB, List_Body};

response_PBServer({error, Reason}) ->
  {error, Reason}.