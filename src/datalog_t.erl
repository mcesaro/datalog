%%
%%   Copyright 2014 - 2015 Dmitry Kolesnikov, All Rights Reserved
%%
%%   Licensed under the Apache License, Version 2.0 (the "License");
%%   you may not use this file except in compliance with the License.
%%   You may obtain a copy of the License at
%%
%%       http://www.apache.org/licenses/LICENSE-2.0
%%
%%   Unless required by applicable law or agreed to in writing, software
%%   distributed under the License is distributed on an "AS IS" BASIS,
%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%   See the License for the specific language governing permissions and
%%   limitations under the License.
%%
%% @doc
%%   abstraction : predicate term
-module(datalog_t).
-include("datalog.hrl").

-export([
   compile/1
  ,prepare/1
  ,rewrite/2
  ,input/2
]).

%%
%% compile query, replace predicate term with abstract syntax
compile(Datalog) -> 
   lists:mapfoldl(fun compile/2, dict:new(), Datalog).

compile({Id, Term0}, Acc0) ->
   {Term1, Acc1} = lists:mapfoldl(fun compile/2, Acc0, Term0),
   {{Id, Term1}, Acc1};   

compile(#h{head = Head0, body = Body0}=X, Acc0) ->
   {Body1, Acc1} = lists:mapfoldl(fun compile/2, Acc0, Body0),
   Head1 = [dict:fetch(H, Acc1) || H <- Head0],
   {X#h{head = Head1, body = Body1}, Acc1};

compile(#f{t = Term0}=X, Acc0) ->
   Term1 = [dict:fetch(T, Acc0) || T <- Term0],
   {X#f{t = Term1}, Acc0};

compile(#p{t = Term0}=X, Acc0) ->
   {Term1, Acc1} = lists:mapfoldl(fun compile/2, Acc0, Term0),
   {X#p{t = Term1}, Acc1};

compile(Id, Acc0)
 when is_atom(Id) ->
   % term is variable
   case dict:find(Id, Acc0) of
      {ok, I} ->
         {{I, '_'}, Acc0};
      error   ->
         I = dict:size(Acc0) + 1,
         {{I, '_'}, dict:store(Id, I, Acc0)}
   end;

compile(Id, Acc0) ->
   % term is literal
   {{'_', {'=', Id}}, Acc0}.

%%
%% prepare query, replace predicate term with evaluation order
prepare(Datalog) ->
   erlang:element(1, 
      lists:mapfoldl(fun prepare/2, [], Datalog)
   ).

prepare(#h{body = Body}=X, Acc0) ->
   {Pred, Cond} = lists:partition(fun(#p{}) -> true; (_) -> false end, Body),
   {Body1,   _} = lists:mapfoldl(fun prepare/2, [], Pred),
   {X#h{body = filter(Body1, Cond)}, Acc0};

prepare(#p{t = Term0}=X, Acc0) ->
   {Term1, Acc1} = lists:mapfoldl(fun prepare/2, Acc0, Term0),
   {X#p{t = Term1}, Acc1};   

prepare({'_', _}=T, Acc0) ->
   {T, Acc0};

prepare({I, '_'}, Acc0) ->
   case lists:member(I, Acc0) of
      true  ->
         {{I, in}, Acc0};
      false ->
         {{I, eg}, [I|Acc0]}
   end;
   
prepare(Any, Acc) ->
   {Any, Acc}.

%%
%% optimize query, inject filters to egress terms
filter({I, eg}, Cond) ->
   case lists:filter(fun(X) -> X#f.t =:= [I] end, Cond) of
      []   ->
         {I, eg};
      List ->
         {I, [{Id, Value} || #f{id = Id, s = Value} <- List]}
   end;

filter({_, _}=Term, _Cond) ->
   Term;

filter(#p{t = Term}=X, Cond) ->
   X#p{t = [filter(T, Cond) || T <- Term]};

filter(Body, Cond) ->
   [filter(Pred, Cond) || Pred <- Body].

%%
%% rewrite term specification using heap.
%% the role of term is flipped from egress to ingress if
%% it's value is defined outside of clause (e.g. defined by goal) 
rewrite({_, in}=T, #datalog{}) ->
   T;
rewrite({I,  _}=T, #datalog{heap = Heap}) ->
   case erlang:element(I, Heap) of
      '_' -> T;
      _   -> {I, in}
   end;

rewrite(Term, Datalog) ->
   [rewrite(T, Datalog) || T <- Term].


%%
%% map term specification to predicate function arguments using current heap
input({I, in}, #datalog{heap = Heap}) ->
   case erlang:element(I, Heap) of
      '_' -> throw(undefined);
      X   -> X
   end; 

input({_, eg}, _Datalog) ->
   '_';

input({_, Pred}, _Datalog) ->
   Pred;

input(Term, Datalog) ->
   [input(T, Datalog) || T <- Term].






