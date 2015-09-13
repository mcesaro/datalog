%%
%%   Copyright 2012 Dmitry Kolesnikov, All Rights Reserved
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
-define(NULL,    {}).

-record(datalog, {
   ns   = undefined :: atom() %% data query global namespace (IStream interface)
  ,heap = undefined :: any()  %% head state of the query 
}).

%%
%% rule predicate
-record(p, {
   ns = undefined :: atom(),         %% predicate namespace (IStream interface)
   id = undefined :: atom(),         %% predicate identity
   t  = []        :: list(),         %% predicate terms    
   s  = {}        :: datum:stream()  %% stream bound to predicate  
}).


%%
%% rule (horn clause)
-record(h, {
   id   = undefined :: atom(),       %% rule identity
   head = []        :: list(),       %% rule egress variables
   body = []        :: [#p{}]        %% rule body 
}).

