# PubSub

Distributed PubSub

## Usage

Connect two nodes and start `pubsub` on both. In this example `bar@pong`
subscribes to the channel `world`, `foo@ping` publishes the message `"Hello!"`
and `bar@pong` receives it:

```erlang
(foo@ping)1> pubsub:start().
(bar@pong)1> pubsub:start().
(bar@pong)2> pubsub:subscribe(world).
(foo@ping)2> pubsub:publish("Hello!", world).
(bar@pong)3> pubsub:recv(stuff).
"Hello!"
```
