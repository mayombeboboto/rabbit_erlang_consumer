%%%-------------------------------------------------------------------
%% @doc consumer public API
%% @end
%%%-------------------------------------------------------------------
-module(consumer_app).
%%%-------------------------------------------------------------------
-behaviour(application).
%%%-------------------------------------------------------------------
-export([start/2]).
-export([stop/1]).
%%%-------------------------------------------------------------------
-spec start(normal, []) -> {ok, pid()}.
start(_StartType, _StartArgs) ->
    consumer_sup:start_link().

-spec stop(term()) -> no_return().
stop(_State) ->
    ok.