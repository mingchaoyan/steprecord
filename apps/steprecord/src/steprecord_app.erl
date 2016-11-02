%%%-------------------------------------------------------------------
%% @doc steprecord public API
%% @end
%%%-------------------------------------------------------------------

-module(steprecord_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).
-export([report/1]).

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
    case dets:open_file(database_client_id, [{file, "database_client_id"}]) of
        {ok, database_client_id} ->
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

report(imei) ->
    new_ets(ets_imei),
    ets:from_dets(ets_imei, database_imei),
    CountList = lists:map(get_count(ets_imei), lists:seq(0, 6)),
    report2(CountList);
report(client_id) ->
    new_ets(ets_client_id),
    ets:from_dets(ets_client_id, database_client_id),
    CountList = lists:map(get_count(ets_client_id), lists:seq(0, 6)),
    report2(CountList).

report2(CountList) ->
    Sum = lists:foldl(fun(X, S) -> X + S end, 0, CountList),
    case Sum =:= 0 of
        true ->
            io:format("sum is 0~n");
        false ->
            Result = lists:zip(lists:map(fun(Count) -> Count/Sum end, CountList),
                      lists:seq(0, 6)),
            lists:foreach(fun({Step, Ratio}) -> 
                                  io:format("~p ==> ~p~n", [Step, Ratio]) 
                          end, Result)
    end.

new_ets(EtsName) ->
    case ets:info(EtsName) of
        undefined ->
            ets:new(EtsName, [named_table, public]);
        _ ->
            ignore
    end.

get_count(EtsName) ->
    fun(StepNum) ->
        ets:select_count(EtsName, 
                        [{{'_', '_', '$3', '_', '_', '_'}, 
                          [{'=:=', '$3', StepNum}],
                          [true]
                         }])
    end.

%%--------------------------------------------------------------------
stop(_State) ->
    dets:close(database_imei),
    dets:close(database_client_id),
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
