% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http:%www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(hqueue_tests).


-include_lib("eunit/include/eunit.hrl").


simple_test() ->
    ?assertMatch({ok, _}, hqueue:new()).


empty_extract_max_test() ->
    {ok, HQ} = hqueue:new(),
    ?assertMatch({error, empty}, hqueue:extract_max(HQ)).


simple_insert_test() ->
    {ok, HQ} = hqueue:new(),
    ?assertEqual(ok, hqueue:insert(HQ, 1.1, foo)).


simple_insert_extract_max_test() ->
    {ok, HQ} = hqueue:new(),
    ?assertEqual(ok, hqueue:insert(HQ, 1.1, foo)),
    ?assertEqual({1.1, foo}, hqueue:extract_max(HQ)).


negative_priority_test() ->
    {ok, HQ} = hqueue:new(),
    ?assertError(badarg, hqueue:insert(HQ, -1.2345, foo)).


insert_extract_max_test() ->
    {ok, HQ} = hqueue:new(),
    Elems = [{1.5, foo}, {1.1, bar}, {0.4, baz}],
    [?assertEqual(ok, hqueue:insert(HQ, P, E)) || {P,E} <- Elems],
    [?assertEqual({P,E}, hqueue:extract_max(HQ)) || {P,E} <- Elems].


check_pid_test() ->
    Fun = fun() -> receive Parent -> Parent ! {self(), hqueue:new()} end end,
    Pid = spawn(Fun),
    Pid ! self(),
    {ok, HQ} = receive
        {Pid, Resp} ->
            Resp
        after 2000 ->
            timeout
    end,
    ?assertError(badarg, hqueue:extract_max(HQ)).


size_test() ->
    {ok, HQ} = hqueue:new(),
    ?assertEqual(0, hqueue:size(HQ)),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,10)],
    ?assertEqual(10, hqueue:size(HQ)),
    [hqueue:extract_max(HQ) || _ <- lists:seq(1,10)],
    ?assertEqual(0, hqueue:size(HQ)).


is_empty_test() ->
    {ok, HQ} = hqueue:new(),
    ?assertEqual(true, hqueue:is_empty(HQ)),
    hqueue:insert(HQ, 1.0, foo),
    ?assertEqual(false, hqueue:is_empty(HQ)).


full_test() ->
    {ok, HQ} = hqueue:new([{max_elems, 5}]),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,5)],
    ?assertEqual({error, full}, hqueue:insert(HQ, 1.0, 6)),
    ?assertEqual(5, hqueue:size(HQ)),
    {1.0, _} = hqueue:extract_max(HQ),
    ?assertEqual(4, hqueue:size(HQ)),
    ?assertEqual(ok, hqueue:insert(HQ, 1.0, 6)),
    ?assertEqual({error, full}, hqueue:insert(HQ, 1.0, 6)),
    ?assertEqual(5, hqueue:size(HQ)).


max_elems_test() ->
    {ok, HQ} = hqueue:new([{max_elems, 1024}]),
    ?assertEqual(1024, hqueue:max_elems(HQ)).


empty_to_list_test() ->
    {ok, HQ} = hqueue:new(),
    ?assertEqual([], hqueue:to_list(HQ)).


to_list_test() ->
    {ok, HQ} = hqueue:new([{max_elems, 3}]),
    Elems = [{1.1, foo}, {2.2, bar}, {3.3, baz}],
    [hqueue:insert(HQ, P, E) || {P, E} <- Elems],
    ?assertEqual(Elems, lists:keysort(1, hqueue:to_list(HQ))).


empty_from_list_test() ->
    Elems = [],
    {ok, HQ} = hqueue:from_list(Elems),
    ?assertEqual(Elems, hqueue:to_list(HQ)).


from_list_test() ->
    Elems = [{1.1, foo}, {2.2, bar}, {3.3, baz}],
    {ok, HQ} = hqueue:from_list(Elems),
    ?assertEqual(Elems, lists:keysort(1, hqueue:to_list(HQ))).


scale_test() ->
    {ok, HQ} = hqueue:new(),
    Elems = [{1.1, foo}, {2.2, bar}, {3.3, baz}],
    Scale = 1.7,
    [hqueue:insert(HQ, P, E) || {P, E} <- Elems],
    ?assertEqual(Elems, lists:keysort(1, hqueue:to_list(HQ))),
    ?assertEqual(ok, hqueue:scale_by(HQ, Scale)),
    Elems1 = [{P*Scale, E} || {P, E} <- Elems],
    ?assertEqual(Elems1, lists:keysort(1, hqueue:to_list(HQ))).


small_heap_size_test() ->
    {ok, HQ} = hqueue:new([{max_elems, 8}]),
    ?assertEqual(8, hqueue:max_elems(HQ)),
    ?assertEqual(8, hqueue:heap_size(HQ)).


heap_size_test() ->
    {ok, HQ} = hqueue:new([{max_elems, 2048}, {heap_size, 1024}]),
    ?assertEqual(2048, hqueue:max_elems(HQ)),
    ?assertEqual(1024, hqueue:heap_size(HQ)).


init_heap_size_test() ->
    {ok, HQ} = hqueue:new([{max_elems, 2048}, {heap_size, 16}]),
    ?assertEqual(2048, hqueue:max_elems(HQ)),
    ?assertEqual(16, hqueue:heap_size(HQ)).


small_heap_resize_test() ->
    {ok, HQ} = hqueue:new([{max_elems, 29}, {heap_size, 4}]),
    ?assertEqual(0, hqueue:size(HQ)),
    ?assertEqual(29, hqueue:max_elems(HQ)),
    ?assertEqual(4, hqueue:heap_size(HQ)),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,5)],
    ?assertEqual(5, hqueue:size(HQ)),
    ?assertEqual(8, hqueue:heap_size(HQ)),
    ?assertEqual(29, hqueue:max_elems(HQ)),
    [?assertEqual(ok, hqueue:insert(HQ, 1.0, E)) || E <- lists:seq(1,7)],
    ?assertEqual(12, hqueue:size(HQ)),
    ?assertEqual(16, hqueue:heap_size(HQ)),
    ?assertEqual(29, hqueue:max_elems(HQ)),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,9)],
    ?assertEqual(21, hqueue:size(HQ)),
    ?assertEqual(29, hqueue:heap_size(HQ)),
    ?assertEqual(29, hqueue:max_elems(HQ)),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,8)],
    ?assertEqual(29, hqueue:size(HQ)),
    ?assertEqual(29, hqueue:heap_size(HQ)),
    ?assertEqual(29, hqueue:max_elems(HQ)),
    ?assertEqual({error, full}, hqueue:insert(HQ, 1.0, 1.4)).


resize_heap_test() ->
    Max = 4,
    {ok, HQ} = hqueue:new([{max_elems, Max}]),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,Max)],
    ?assertEqual(Max, hqueue:max_elems(HQ)),
    ?assertEqual(Max, hqueue:heap_size(HQ)),
    ?assertEqual({error, full}, hqueue:insert(HQ, 1.0, 5)),
    ?assertEqual(Max, hqueue:resize_heap(HQ, Max*2)),
    ?assertEqual(Max*2, hqueue:heap_size(HQ)),
    ?assertEqual(Max, hqueue:size(HQ)),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,Max)],
    ?assertEqual(Max*2, hqueue:heap_size(HQ)),
    ?assertEqual({error, full}, hqueue:insert(HQ, 1.0, 5)).


resize_heap_too_small_test() ->
    {ok, HQ} = hqueue:new([{max_elems, 8}]),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,8)],
    ?assertEqual({error, too_small}, hqueue:resize_heap(HQ, 4)).


simple_set_max_elems_test() ->
    Max = 4,
    {ok, HQ} = hqueue:new([{max_elems, Max}]),
    ?assertEqual(Max, hqueue:max_elems(HQ)),
    ?assertEqual(Max, hqueue:set_max_elems(HQ, Max*2)),
    ?assertEqual(Max*2, hqueue:max_elems(HQ)).


set_max_elems_test() ->
    Max = 8,
    NewMax = Max div 2,
    {ok, HQ} = hqueue:new([{max_elems, Max}]),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,Max)],
    ?assertEqual(Max, hqueue:max_elems(HQ)),
    ?assertEqual(Max, hqueue:size(HQ)),
    ?assertEqual({error, full}, hqueue:insert(HQ, 1.0, 9)),
    [hqueue:extract_max(HQ) || _ <- lists:seq(1,NewMax)],
    ?assertEqual(Max, hqueue:set_max_elems(HQ, NewMax)),
    ?assertEqual(NewMax, hqueue:max_elems(HQ)),
    ?assertEqual(NewMax, hqueue:size(HQ)),
    ?assertEqual({error, full}, hqueue:insert(HQ, 1.0, 5)).


set_max_elems_too_small_test() ->
    {ok, HQ} = hqueue:new([{max_elems, 8}]),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,8)],
    ?assertEqual({error, too_small}, hqueue:set_max_elems(HQ, 4)).


simple_info_test() ->
    MaxElems = 256,
    HeapSize = 64,
    {ok, HQ} = hqueue:new([{max_elems, MaxElems}, {heap_size, HeapSize}]),
    ?assertEqual(
        [{heap_size, HeapSize}, {max_elems, MaxElems}, {size, 0}],
        hqueue:info(HQ)
    ).


size_info_test() ->
    MaxElems = 256,
    HeapSize = 64,
    {ok, HQ} = hqueue:new([{max_elems, MaxElems}, {heap_size, HeapSize}]),
    [hqueue:insert(HQ, 1.0, E) || E <- lists:seq(1,10)],
    ?assertEqual(
        [{heap_size, HeapSize}, {max_elems, MaxElems}, {size, 10}],
        hqueue:info(HQ)
    ).


duplicates_test() ->
    {ok, HQ} = hqueue:new(),
    {P,V} = {1.9, foo},
    ok = hqueue:insert(HQ, P, V),
    ok = hqueue:insert(HQ, P, V),
    ?assertEqual({P, V}, hqueue:extract_max(HQ)),
    ?assertEqual({P, V}, hqueue:extract_max(HQ)),
    ?assertEqual({error, empty}, hqueue:extract_max(HQ)).

