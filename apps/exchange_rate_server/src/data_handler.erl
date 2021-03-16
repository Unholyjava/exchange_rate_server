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
  HasBody = cowboy_req:has_body(Req0),
  Req = response_database(Method, HasBody, Req0),
  {ok, Req, Opts}.

response_database(<<"GET">>, false, Req0) ->
  response_PBServer(httpc:request("https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=5"), Req0);

response_database(_, _, Req) ->
  cowboy_req:reply(404, [], <<"Missing request">>, Req).

response_PBServer({error, Reason}, Req) ->
  cowboy_req:reply(400, [], <<"Problem with connect to PrivatBank server.">>, {error, Reason, Req});

response_PBServer({ok, {_Status, _Header, Body}}, Req) ->
  case exchange_rate_server:show_life_status() of
    old ->
      io:format("Output data from PBServer ~n"),
      exchange_rate_server:insert_rates(jsx:decode(list_to_binary(Body), [{return_maps, false}])),
      cowboy_req:reply(200, #{<<"content-type">> => <<"text/xml; charset=utf-8">>},
        response_List_to_xml(jsx:decode(list_to_binary(Body), [{return_maps, false}])), Req);
    new ->
      io:format("Output data from etsDB ~n"),
      Body_DB = exchange_rate_server:show_all_rates(),
      cowboy_req:reply(200, #{<<"content-type">> => <<"text/xml; charset=utf-8">>},
        response_List_to_xml(Body_DB), Req);
    _Another ->
      cowboy_req:reply(404, [], <<"Missing DB-status">>, Req)
  end.

response_List_to_xml(Response) ->
  Base_Part_Xml = [{<<"row">>,[],[{<<"exchangerate">>,Row_of_Response,[]}]} || Row_of_Response <- Response],
  exomler:encode({<<"exchangerates">>,[],Base_Part_Xml}).
