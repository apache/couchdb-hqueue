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

-module(hqueue_proper).

-ifdef(WITH_PROPER).
-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").


-define(QC(Prop), proper:quickcheck(Prop, [{to_file, user}])).


prop_simple() ->
    ?FORALL({P, V}, {non_neg_float(), nat()},
        begin
            {ok, HQ} = hqueue:new(),
            hqueue:insert(HQ, P, V),
            {P, V} == hqueue:extract_max(HQ)
        end).


simple_test_() ->
    ?_assertEqual(true, ?QC(prop_simple())).

-endif.
