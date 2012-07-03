%%% The MIT License
%%%
%%% Copyright (C) 2011-2012 by Joseph Wayne Norton <norton@alum.mit.edu>
%%% Copyright (C) 2002 by Joe Armstrong
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in
%%% all copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%%% THE SOFTWARE.

%%%-------------------------------------------------------------------
%%% Copyright (c) 2008-2011 Gemini Mobile Technologies, Inc.  All rights reserved.
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%
%%% File    : qc_ubf.erl
%%% Purpose : QuickCheck wrappers for UBF
%%%-------------------------------------------------------------------

-module(qc_ubf, [MOD, CONTRACTS]).

-ifdef(QC).

%% API
-export([qc_run/2]).
-export([qc_sample/1]).
-export([qc_prop/1]).
-export([qc_counterexample/2]).
-export([qc_counterexample_read/2]).
-export([qc_counterexample_write/2]).

%% Misc API
-export([ubf_gen_command/5, ubf_gen_command_type/5]).
-export([ubf_rpc/3]).

%% qc_statem Callbacks
-behaviour(qc_statem).
-export([command_gen/2]).
-export([initial_state/0, state_is_sane/1, next_state/3, precondition/2, postcondition/3]).
-export([setup/1, teardown/1, teardown/2, aggregate/1]).

%% Interface Functions
-export([behaviour_info/1]).

-include("qc_statem.hrl").

%% Define the behaviour's required mods.
behaviour_info(callbacks) ->
    [{ubf_command_contract,2}
     , {ubf_command_typename,3}
     , {ubf_command_typegen,6}
     , {ubf_command_gen,5}
     , {ubf_command_gen_custom,3}
     , {ubf_rpc,3}
     , {ubf_initial_state,0}
     , {ubf_state_is_sane,1}
     , {ubf_next_state,3}
     , {ubf_precondition,2}
     , {ubf_postcondition,3}
     , {ubf_setup,1}
     , {ubf_teardown,1}
     , {ubf_teardown,2}
     , {ubf_aggregate,1}
    ];
behaviour_info(_Other) ->
	undefined.

%%%=========================================================================
%%%  Records, Types, Macros
%%%=========================================================================

-define(UBF_DEFAULT_TYPENAMES,
        [info_req,description_req,contract_req,keepalive_req]).

%%%=========================================================================
%%%  API
%%%=========================================================================

qc_run(NumTests, Options) ->
    qc_statem:qc_run(THIS, NumTests, Options).

qc_sample(Options) ->
    qc_statem:qc_sample(THIS, Options).

qc_prop(Options) ->
    qc_statem:qc_prop(THIS, Options).

qc_counterexample(Options, CounterExample) ->
    qc_statem:qc_counterexample(THIS, Options, CounterExample).

qc_counterexample_read(Options, FileName) ->
    qc_statem:qc_counterexample_read(THIS, Options, FileName).

qc_counterexample_write(FileName, CounterExample) ->
    qc_statem:qc_counterexample_write(FileName, CounterExample).

ubf_gen_command(Mod, S, Contract, TypeName, TypeStack) ->
    Gen = fun ubf_gen_command_type/5,
    try_command_typegen(Gen, Mod, S, Contract, TypeName, TypeStack).

ubf_gen_command_type(Mod, S, Contract, TypeName, TypeStack) ->
    Gen = fun(TN) ->
                  G = fun ubf_gen_command_type/5,
                  case lists:member(TypeName, TypeStack) of
                      true ->
                          ?SIZED(Size,resize(round(math:sqrt(Size)),
                                             try_command_typegen(G, Mod, S, Contract, TN, [TypeName|TypeStack])));
                      false ->
                          try_command_typegen(G, Mod, S, Contract, TN, [TypeName|TypeStack])
                  end
          end,
    qc_ubf_types:type(Gen, Contract, TypeName).

ubf_rpc(Contract,_TypeName,Type) ->
    case ubf_client:lpc(Contract, Type) of
        {reply,Reply,_State} ->
            Reply;
        Err ->
            erlang:error(Err)
    end.

%%%=========================================================================
%%%  Callbacks - eqc_statem
%%%=========================================================================

%% initial state
initial_state() ->
    try
        MOD:ubf_initial_state()
    catch
        error:undef ->
            undefined
    end.

%% state is sane
state_is_sane(S) ->
    try
        MOD:state_is_sane(S)
    catch
        error:undef ->
            true
    end.

%% command generator
command_gen(Mod, S) ->
    %% (S::symbolic_state(),Contracts::list(atom())) -> atom()
    ?LET(Contract,try_command_contract(Mod, S, CONTRACTS),
         begin
             Gen = fun ubf_gen_command/5,
             if Contract =/= undefined ->
                     InputTypeNames = extract_input_typenames(Contract),
                     %% (S::symbolic_state(),Contract::atom(),InputTypeNames::list(atom()) -> atom()
                     ?LET(InputTypeName,try_command_typename(Mod, S, Contract, InputTypeNames),
                          %% (Gen, S::symbolic_state(),Contract::atom(),InputTypeName::atom()) -> gen()
                          try_command_gen(Gen, Mod, S, Contract, InputTypeName));
                true ->
                     Mod:ubf_command_gen_custom(Gen, Mod, S)
             end
         end).

%% next state
next_state(S,R,C) ->
    try
        MOD:ubf_next_state(S,R,C)
    catch
        error:undef ->
            S
    end.

%% precondition
precondition(S,C) ->
    try
        MOD:ubf_precondition(S,C)
    catch
        error:undef ->
            true
    end.

%% postcondition
postcondition(_S,_C,{clientBrokeContract,_,_}) ->
    false;
postcondition(_S,_C,{serverBrokeContract,_,_}) ->
    false;
postcondition(S,C,R) ->
    try
        MOD:ubf_postcondition(S,C,R)
    catch
        error:undef ->
            true
    end.

%% setup
setup(Hard) ->
    try
        MOD:setup(Hard)
    catch
        error:undef ->
            {ok,undefined}
    end.

%% teardown
teardown(Ref) ->
    try
        MOD:teardown(Ref)
    catch
        error:undef ->
            ok
    end.

teardown(Ref, State) ->
    try
        MOD:teardown(Ref, State)
    catch
        error:undef ->
            ok
    end.

%% aggregate
aggregate(L) ->
    try
        MOD:aggregate(L)
    catch
        error:undef ->
            []
    end.

%%%========================================================================
%%% Internal functions
%%%========================================================================

extract_input_typenames(Contract) ->
    [ Input || {{prim,1,1,Input},{prim,1,1,_Output}}
                   <- Contract:contract_anystate(), not lists:member(Input, ?UBF_DEFAULT_TYPENAMES) ].

try_command_typegen(Gen, Mod, S, Contract, TypeName, TypeStack) ->
    try
        Mod:ubf_command_typegen(Gen, Mod, S, Contract, TypeName, TypeStack)
    catch
        error:undef ->
            Gen(Mod,S,Contract,TypeName,TypeStack)
    end.

try_command_contract(Mod, S, Contracts) ->
    try
        Mod:ubf_command_contract(Mod, S, Contracts)
    catch
        error:undef ->
            oneof(Contracts)
    end.

try_command_typename(Mod, S, Contract, InputTypeNames) ->
    try
        Mod:ubf_command_typename(Mod, S, Contract, InputTypeNames)
    catch
        error:undef ->
            oneof(InputTypeNames)
    end.

try_command_gen(Gen, Mod, S, Contract, InputTypeName) ->
    try
        Mod:ubf_command_gen(Gen, Mod, S, Contract, InputTypeName)
    catch
        error:undef ->
            ?LET(Type,Gen(Mod,S,Contract,InputTypeName,[]),
                 {call,THIS,ubf_rpc,[Contract,InputTypeName,Type]})
    end.

-endif. %% -ifdef(QC).
