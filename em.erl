-module(em).
-export([start_handler/1, start_logger/0]).

-record(action, {service, command, caller, timeout=1000}).
-record(service, {name, needs=[]}).

subprocess(Cmd, Caller, Timeout) ->
    io:format("executing ~p~n", [Cmd]),
    P = erlang:open_port(
        {spawn, Cmd},
        [stderr_to_stdout, in, exit_status, stream, {line, 255}]),
    loop(P, #action{service="foo", command="bar", caller=Caller, timeout=Timeout}),
    io:format("done.~n").

loop(P, Action=#action{service=_Service, command=_Command, caller=Caller, timeout=Timeout}) ->
    receive
        {P, {exit_status, ExitStatus}} ->
            Caller ! {exit_status, ExitStatus};
        {P, {data, {eol, Line}}} ->
            Caller ! Line,
            loop(P, Action)
    after Timeout ->
        Caller ! timeout
    end.

start_handler(Name) ->
    spawn_link(fun() -> handle(#service{name=Name}) end).


handle(Service=#service{name=Name, needs=Needs}) ->
    receive
        {status, Pid} ->
            subprocess("./service.sh " ++ Name ++ " status", Pid, 1000),
            handle(Service);
        {start, Pid} ->
            subprocess("./service.sh " ++ Name ++ " start", Pid, 1000),
            handle(Service);
        {stop, Pid} ->
            subprocess("./service.sh " ++ Name ++ " stop", Pid, 1000),
            handle(Service);

        {add_needs, NewNeed} ->
            handle(#service{name=Name, needs=NewNeed});

        quit ->
            ok
    end.




start_logger() ->
    spawn_link(fun logger/0).

logger() ->
    receive
        status ->
            io:format("** still up and running **~n");
        Data ->
            io:format("~p~n", [Data])
    end,
    logger().
