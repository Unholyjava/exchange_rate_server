%%%-------------------------------------------------------------------
%%% @author Gregory
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. лют 2021 20:54
%%%-------------------------------------------------------------------
-module(data_handler).
-author("gregory").

%% API
-export([init/2]).

init(Req0, Opts) ->
  Method = cowboy_req:method(Req0),
  Req = request_client(Method, Req0),
  {ok, Req, Opts}.

request_client(<<"GET">>, Req0) ->
  response_server(exchange_rate_server:show_all_rates(), Req0);

request_client(_, Req) ->
  cowboy_req:reply(404, [], <<"Method is invalid">>, Req).

response_server({error, Reason}, Req) ->
  cowboy_req:reply(400, [], <<"Problem with connect to PrivatBank server.">>, {error, Reason, Req});

response_server({ok, from_PB, List_Body}, Req) ->
  cowboy_req:reply(200, #{<<"content-type">> => <<"text/xml; charset=utf-8">>},
    response_List_to_xml(List_Body), Req);

response_server({ok, from_ets, Body_DB}, Req) ->
  cowboy_req:reply(200, #{<<"content-type">> => <<"text/xml; charset=utf-8">>},
    response_List_to_xml(Body_DB), Req);

response_server(_, Req) ->
  cowboy_req:reply(400, [], <<"Unexpected response from exchange_rate_server ~n">>, Req).

response_List_to_xml(Response) ->
  Base_Part_Xml = [{<<"row">>,[],[{<<"exchangerate">>,Row_of_Response,[]}]} || Row_of_Response <- Response],
  exomler:encode({<<"exchangerates">>,[],Base_Part_Xml}).
