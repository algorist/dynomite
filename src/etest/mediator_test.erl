-include_lib("include/eunit/eunit.hrl").

init_integrated(Good, Bad, {R, W, N}) ->
  {ok, _} = membership:start_link(),
  {ok, _} = mediator:start_link({R, W, N}),
  ok = start_storage_servers(dict_storage, good_store, Good),
  ok = start_storage_servers(fail_storage, bad_store, Bad).
  
stop_integrated(Good, Bad) ->
  ok = stop_storage_servers(bad_store, Bad),
  ok = stop_storage_servers(good_store, Good),
  mediator:stop(),
  membership:stop().
  
start_storage_servers(_Module, _Name, 0) -> ok;
start_storage_servers(Module, Name, N) ->
  {ok, _} = storage_server:start_link(Module, ok, list_to_atom(lists:concat([Name, N]))),
  start_storage_servers(Module, Name, N-1).
  
stop_storage_servers(_Name, 0) -> ok;
stop_storage_servers(Name, N) ->
  storage_server:close(list_to_atom(lists:concat([Name, N]))),
  stop_storage_servers(Name, N-1).
  
all_servers_working_test() ->
  init_integrated(3, 0, {2, 2, 3}),
  {ok, 3} = mediator:put(<<"key1">>, [], <<"value1">>),
  {ok, {_Context, [<<"value1">>]}} = mediator:get(<<"key1">>),
  {ok, {true, 3}} = mediator:has_key(<<"key1">>),
  {ok, 3} = mediator:delete(<<"key1">>),
  {ok, {false, 3}} = mediator:has_key(<<"key1">>),
  {ok, not_found} = mediator:get(<<"key1">>),
  stop_integrated(3, 0).
  
one_bad_server_test() ->
  init_integrated(2, 1, {2, 2, 3}),
  {ok, 2} = mediator:put(<<"key1">>, [], <<"value1">>),
  {ok, {_Context, [<<"value1">>]}} = mediator:get(<<"key1">>),
  {ok, {true, 2}} = mediator:has_key(<<"key1">>),
  {ok, 2} = mediator:delete(<<"key1">>),
  {ok, {false, 2}} = mediator:has_key(<<"key1">>),
  {ok, not_found} = mediator:get(<<"key1">>),
  stop_integrated(2, 1).
  
two_bad_servers_test() ->
  init_integrated(1, 2, {2, 2, 3}),
  {failure, _} = mediator:put(<<"key1">>, [], <<"value1">>),
  {failure, _} = mediator:get(<<"key1">>),
  {failure, _} = mediator:delete(<<"key1">>),
  {failure, _} = mediator:has_key(<<"key1">>),
  stop_integrated(1, 2).
  
three_bad_servers_test() ->
  init_integrated(0, 3, {2, 2, 3}),
  {failure, _} = mediator:put(<<"key1">>, [], <<"value1">>),
  {failure, _} = mediator:get(<<"key1">>),
  {failure, _} = mediator:delete(<<"key1">>),
  {failure, _} = mediator:has_key(<<"key1">>),
  stop_integrated(0, 3).