%%%-------------------------------------------------------------------
%% @doc steprecord public API
%% @end
%%%-------------------------------------------------------------------

-module(steprecord_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    case dets:open_file(database_imei, [{file, "database_imei"}]) of
        {ok, database_imei} ->
            true;
        {error, Reason} ->
            io:format("cannot open dest table~n"),
            exit(Reason)
    end,
    case dets:open_file(database_clientid, [{file, "database_clientid"}]) of
        {ok, database_clientid} ->
            true;
        {error, Reason1} ->
            io:format("cannot open dest table~n"),
            exit(Reason1)
    end,
    {ok, Pid} = steprecord_sup:start_link(),
    Routes = [{
      '_',
      [
       {"/", steprecord_root, []}
      ]
     }],
    Dispatch = cowboy_router:compile(Routes),
    NumAcceptors = 10,
    TransOpts = [{ip, {0, 0, 0, 0}}, {port, 8080}],
    ProtoOpts = [{env, [{dispatch, Dispatch}]}],
    {ok, _} = cowboy:start_http(chicken_poo_poo,
                                NumAcceptors, TransOpts, ProtoOpts),
    {ok, Pid}.

%%--------------------------------------------------------------------
stop(_State) ->
    dets:close(database),
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
