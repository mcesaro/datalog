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
%%   basic datalog test suite
-module(datalog_basic_SUITE).
-include_lib("common_test/include/ct.hrl").

%% common test
-export([
   all/0
  ,groups/0
  ,init_per_suite/1
  ,end_per_suite/1
  ,init_per_group/2
  ,end_per_group/2
]).
-export([
   basic_all/1
  ,imdb_person_1/1
  ,imdb_person_2/1
  ,imdb_actor_of/1
]).

%%%----------------------------------------------------------------------------   
%%%
%%% factory
%%%
%%%----------------------------------------------------------------------------   

all() ->
   [
      {group, basic}, {group, imdb}
   ].

groups() ->
   [
      {basic, [], [
         basic_all
      ]}
     ,{imdb,  [], [
         imdb_person_1
        ,imdb_person_2
        ,imdb_actor_of
      ]}
   ].


%%%----------------------------------------------------------------------------   
%%%
%%% init
%%%
%%%----------------------------------------------------------------------------   

%%
%%
init_per_suite(Config) ->
   application:start(datalog),
   Config.

%%
%%
end_per_suite(_Config) ->
   application:stop(datalog).

%%   
%%
init_per_group(basic, Config) ->
   List = [{a,1}, {b,1}, {c,2}, {d,2}, {e,3}, {f,3}, {g,4}, {h,4}, {i,5}, {j,5}],
   [{list, List} | Config];

init_per_group(imdb, Config) ->
   {ok, List} = file:consult(filename:join([code:priv_dir(datalog), "imdb.config"])),
   [{list, List} | Config];

init_per_group(_, Config) ->
   Config.

%%
%%
end_per_group(_, _Config) ->
   ok.

%%%----------------------------------------------------------------------------   
%%%
%%% unit test
%%%
%%%----------------------------------------------------------------------------   

%%
%%
basic_all(Config) ->
   List = ?config(list, Config),
   Eval = datalog:q(
      datalog:horn([x,y], [
         datalog:list(#{'_' => [x,y]})
      ]),
      List
   ),
   List = stream:list( 
      stream:map(
         fun(#{x := X, y := Y}) ->
            {X, Y}
         end,
         Eval
      )
   ).

%%
%%
imdb_person_1(Config) ->
   Eval  = datalog:q(
      datalog:horn([a,b,c], [
         datalog:list(#{'_' => [a,b,c], b => name, c => <<"Ridley Scott">>})
      ]),
      ?config(list, Config)
   ),
   [
      #{
         a := <<"urn:person:137">>, 
         b := name, 
         c := <<"Ridley Scott">>
      }
   ] = stream:list( Eval ).

%%
%%
imdb_person_2(Config) ->
   Eval  = datalog:q(
      datalog:horn([a,c], [
         datalog:list(#{'_' => [a,b,c], b => name})
      ]),
      #{c => <<"Ridley Scott">>},
      ?config(list, Config)
   ),
   [
      #{
         a := <<"urn:person:137">>, 
         c := <<"Ridley Scott">>
      }
   ] = stream:list( Eval ).


%%
%%
imdb_actor_of(Config) ->
   Eval = datalog:q(
      datalog:horn([n], [
         datalog:list(#{'_' => [m,x,t], x => title}),
         datalog:list(#{'_' => [m,y,p], y => cast}),
         datalog:list(#{'_' => [p,z,n], z => name})
      ]),
      #{t => <<"Lethal Weapon">>},
      ?config(list, Config)
   ),
   [
      #{n := <<"Mel Gibson">>},
      #{n := <<"Danny Glover">>},
      #{n := <<"Gary Busey">>}
   ] = stream:list( Eval ).
