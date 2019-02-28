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

-module(hqueue_statem).

-ifdef(WITH_PROPER).
-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").


-behaviour(proper_statem).


-export([
    hqueue_works/0
]).
-export([
    command/1,
    initial_state/0,
    next_state/3,
    postcondition/3,
    precondition/2
]).


-type priority() :: float().
-type val() :: integer().
-type job() :: {priority(), val()}.


-record(state, {
    queue :: [job()]
}).


hqueue_works_test_() ->
    {
        timeout,
        100000,
        ?_assertEqual(
            true,
            proper:quickcheck(
                ?MODULE:hqueue_works(),
                [{to_file, user}, {numtests, 100}]))
    }.


hqueue_works() ->
    ?FORALL(Cmds, commands(?MODULE),
        ?TRAPEXIT(
            begin
                {ok, HQ} = hqueue:new(),
                {History,State,Result} = run_commands(?MODULE, Cmds, [{hq, HQ}]),
                ?WHENFAIL(io:format("History: ~w\nState: ~w\nResult: ~w\n",
                        [History,State,Result]),
                    aggregate(command_names(Cmds), Result =:= ok))

            end)).


initial_state() ->
    #state{queue=[]}.


command(_) ->
    frequency([
        {30, {call, hqueue, insert, [{var, hq}, non_neg_float(), integer()]}},
        {30, {call, hqueue, extract_max, [{var, hq}]}},
        {1, {call, hqueue, size, [{var, hq}]}},
        {1, {call, hqueue, is_empty, [{var, hq}]}},
        {1, {call, hqueue, max_elems, [{var, hq}]}}
    ]).


precondition(_, _) ->
    true.


next_state(#state{queue=Q0}=S, _RV, {call, _, insert, [_, P, V]}) ->
    Q1 = lists:reverse(lists:keysort(1, [{P, V} | Q0])),
    S#state{queue=Q1};
next_state(#state{queue=[]}=S, _RV, {call, _, extract_max, [_]}) ->
    S;
next_state(#state{queue=[_|Q]}=S, _RV, {call, _, extract_max, [_]}) ->
    S#state{queue=Q};
next_state(S, _RV, {call, _, size, [_]}) ->
    S;
next_state(S, _RV, {call, _, is_empty, [_]}) ->
    S;
next_state(S, _RV, {call, _, max_elems, [_]}) ->
    S.


postcondition(_S, {call, _, insert, _}, Result) ->
    ok =:= Result;
postcondition(#state{queue=[]}, {call, _, extract_max, [_]}, {error, empty}) ->
    true;
postcondition(#state{queue=[{_P1,V}|_]}, {call, _, extract_max, [_]},
        {_P2, Result}) ->
    V =:= Result;
postcondition(#state{queue=Q}, {call, _, size, [_]}, Result) ->
    length(Q) =:= Result;
postcondition(#state{queue=Q}, {call, _, is_empty, [_]}, Result) ->
    (length(Q) =:= 0) =:= Result;
postcondition(_S, {call, _, max_elems, [_]}, Result) ->
    0 < Result.

-endif.
