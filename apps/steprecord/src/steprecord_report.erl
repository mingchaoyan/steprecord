-module(steprecord_report).
-export([report/1]).

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
    Ratio = case lists:foldl(fun(X, S) -> X + S end, 0, CountList) of
        0 -> lists:duplicate([{count, 0}, {ratio, 0}], 7);
        Sum -> [[{count, Count}, {ratio, Count/Sum}] || Count <- CountList]
    end,
    lists:zip(lists:seq(0, 6), Ratio).

new_ets(EtsName) ->
    case ets:info(EtsName) of
        undefined -> ets:new(EtsName, [named_table, public]);
        _ -> ignore
    end.

get_count(EtsName) ->
    fun(StepNum) -> ets:select_count(EtsName, 
                                     [{{'_', '_', '$3', '_', '_', '_'}, 
                                       [{'=:=', '$3', StepNum}],
                                       [true]
                                      }])
    end.
