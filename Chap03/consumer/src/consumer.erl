-module(consumer).
%%%-------------------------------------------------------------------
-behaviour(gen_server).
%%%-------------------------------------------------------------------
-export([start_link/0]).

-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
%%%-------------------------------------------------------------------
-include_lib("amqp_client/include/amqp_client.hrl").
-include("../include/consumer.hrl").
%%%-------------------------------------------------------------------
%%% API Functions
-spec start_link() -> {ok, pid()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, null, []).

%%%-------------------------------------------------------------------
%%% Callback Functions
%%%-------------------------------------------------------------------
init(null) ->
    process_flag(trap_exit, true),
    self() ! ?FUNCTION_NAME,
    {ok, #{}}.

handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(init, _State) ->
    {ok, Connection} = amqp_connection:start(#amqp_params_network{}),
    {ok, Channel} = amqp_connection:open_channel(Connection),

    ExchangeDeclare = #'exchange.declare'{ exchange = ?EXCHANGE },
    #'exchange.declare_ok'{} = amqp_channel:call(Channel, ExchangeDeclare),

    QueueDeclare = #'queue.declare'{ queue = ?QUEUE },
    #'queue.declare_ok'{} = amqp_channel:call(Channel, QueueDeclare),

    Binding = #'queue.bind'{ queue =?QUEUE,
                             exchange=?EXCHANGE,
                             routing_key=?ROUTING_KEY },
    #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),

    BasicConsume = #'basic.consume'{ queue=?QUEUE },
    #'basic.consume_ok'{ consumer_tag=Tag } =
        amqp_channel:subscribe(Channel, BasicConsume, self()),
    State = #{ tag => Tag, channel => Channel, count => 0 },
    {noreply, State};
handle_info(#'basic.consume_ok'{ consumer_tag=Tag }, State=#{ tag := Tag }) ->
    {noreply, State};
handle_info({#'basic.deliver'{ delivery_tag=Tag },
             #amqp_msg{ props=_Props, payload=_Payload }},
             State) ->
    amqp_channel:cast(maps:get(channel, State), #'basic.ack'{ delivery_tag=Tag }),
    {noreply, State};
handle_info(Info, State) ->
    io:format("Info: ~p~n", [Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.