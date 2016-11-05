-module(steprecord_root).

-export([init/2]).

-export([allowed_methods/2]).

-export([handle_post/2,
         handle_get/2
        ]).
-export([content_types_accepted/2,
content_types_provided/2]).

init(Req, Opts) ->
    {cowboy_rest, Req, Opts}.

allowed_methods(Req, State) ->
    {[<<"GET">>, <<"POST">>], Req, State}.

content_types_accepted(Req, State) ->
    {[{{<<"application">>, <<"json">>, []}, handle_post}], Req, State}.

content_types_provided(Req, State) ->
    {[{{<<"application">>, <<"json">>, []}, handle_get}], Req, State}.

handle_get(Req, State) ->
    ImeiResult = steprecord_report:report(imei),
    ClientIdResult = steprecord_report:report(client_id),
    Body = jsx:encode(#{<<"imei">> => ImeiResult, <<"client_id">> => ClientIdResult}),
    {Body, Req, State}.

handle_post(Req, State) ->
    {ok, Body, _} = cowboy_req:body(Req),
    Json = jsx:decode(Body, [return_maps]),
    Imei = maps:get(<<"imei">>, Json),
    Channel = maps:get(<<"channel">>, Json),
    ClientId = maps:get(<<"clientId">>, Json),
    Device = maps:get(<<"device">>, Json),
    Mem = maps:get(<<"mem">>, Json),
    Step = maps:get(<<"step">>, Json),
    case dets:lookup(database_imei, Imei) of
        [{Imei, _, Step0, _, _, _}] when Step0 >= Step ->
            ignore;
        _ ->
            dets:insert(database_imei, 
                        {Imei, ClientId, Step, Channel, Device, Mem})
    end,
    case dets:lookup(database_client_id, ClientId) of
        [{ClientId, _, Step00, _, _, _}] when Step00 >= Step ->
            ignore;
        _ ->
            dets:insert(database_client_id, 
                        {ClientId, Imei, Step, Channel, Device, Mem})
    end,
    {true, Req, State}.

