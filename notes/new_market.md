# Markets 2.0

## 

Markets are no longer lone processes. They are supervised sub-trees (in the context of the application wide
supervision tree).

Each market contains:

+ An orderbook
+ A websocket
+ A mediator
+ An event logger

### Orderbook

The orderbook agent, already completed.

### Websocket

A stateful process which receives, translates and forwards l2f data for a specific exchange:market.

The websocket has an internal receive loop which handles the incoming data from it's socket.
Incoming data is translated using an exchange specific translation scheme, which returns an updated state
(for sync checking) and an internal data representation of the received data:

+ trans\_scheme :: {state, json} -> {state', delta | snapshot}

The websocket should implement the following functions:

+ start/3 takes a translation scheme, websocket url and mediator PID. Starts the websocket
+ await\_l2f/1 takes a state, recurs after receiving data (with an updated state)
+ translate/2 takes a translation scheme and some received json/binary and returns the translated json as
    an elixir object
+ deliver/2 takes the mediator PID and a data object, sens the data to the mediator
+ die/0 ends the process (used when websocket loses sync)

### Mediator

A stateful process which maintains an orderbook and decides when the event logger should be notified about
new data received by the web socket.

A mediator should implement the following functions:

+ start/1 takes the pid of the event logger to notify
+ message\_loop/1 takes an initial state (which it will maintain), recurs after each message from websocket
+ apply\_delta/1 apply a delta to the logbook
+ apply\_snapshot/1 apply a snapshot to the logbook
+ deliver/1, takes an event logger PID to  notify (if the the best bid/ask has changed)

### Event Logger
Currently a very simple process which logs changes bid/ask levels. Has the following:

+ best\_bid\_change
+ best\_ask\_change
+ log\_event/1 log event in some way (print to terminal, store in DB etc.)


