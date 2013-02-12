-module(pubsub).

-export([start/0, subscribe/0, subscribe/1, unsubscribe/0, unsubscribe/1,
	publish/1, publish/2, recv/0, recv/1, recv_all_channels/0]).


%% API

-spec start() -> ok.
start() ->
	application:load(gproc),
	application:set_env(gproc, gproc_dist, all),
	application:start(gproc),
	application:load(pubsub),
	ok.

-spec subscribe() -> ok.
subscribe() ->
	subscribe(default).

-spec subscribe(term()) -> ok.
subscribe(Channel) ->
	true = gproc:reg({p, l, {?MODULE, Channel}}),
	% Register the subscription globally, too, so that publishing nodes know
	% which other nodes are actually interested in a channel.
	true = gproc:reg({p, g, {?MODULE, Channel}}),
	ok.

-spec unsubscribe() -> ok.
unsubscribe() ->
	unsubscribe(default).

-spec unsubscribe(term()) -> ok.
unsubscribe(Channel) ->
	gproc:unreg({p, l, {?MODULE, Channel}}),
	gproc:unreg({p, g, {?MODULE, Channel}}),
	ok.

publish(Msg) ->
	publish(Msg, default).

publish(Msg, Channel) ->
	Subscribers = gproc:lookup_pids({p, g, {?MODULE, Channel}}),
	Nodes = subscriber_nodes(Subscribers),
	gproc:bcast(Nodes,
		{p, l, {?MODULE, Channel}}, {self(), {?MODULE, Channel}, Msg}),
	ok.

-spec recv() -> {term(), term()}.
recv() ->
	recv(default).

-spec recv(term()) -> {term(), term()}.
recv(Channel) ->
	receive
		{_From, {?MODULE, Channel}, Msg} -> Msg
	end.

recv_all_channels() ->
	receive
		{_From, {?MODULE, Channel}, Msg} -> {Channel, Msg}
	end.


%% internal

subscriber_nodes(Subscribers) ->
	subscriber_nodes(Subscribers, ordsets:new()).

subscriber_nodes([], Nodes) ->
	ordsets:to_list(Nodes);

subscriber_nodes([Subscriber | Subscribers], Nodes) ->
	Node = node(Subscriber),
	subscriber_nodes(Subscribers, ordsets:add_element(Node, Nodes)).

