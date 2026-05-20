-module(tcp_client).
-export([start/0]).
    % , stop/0, send_message/1.

start() ->
    % // connecting to localhost on port 5555, 
    % // using binary mode and no packet framing
    {ok, Socket} = gen_tcp:connect(
        "localhost",
        5555,
        % when dta arrives accept as binary 
        % 0 = raw data no length prefix
    % active = true the socket automatically sends messages to your process mailbox:
        [binary, {active, true}, {packet, 0}]
    ),
    io:format("Received socket handle: ~p~n", [Socket]),
    %% connection done


    %% establidhing response
    gen_tcp:send(Socket, <<"PING from erlang client">>),
    io:format("Sent: PING and waiting ...... ~n"),


    %% Wait for response as a message
    receive % extracts from mailbox
        {tcp, Socket, Data} ->
            io:format("Received msg from server: ~s~n", [Data]);
        {tcp_closed, Socket} ->
            io:format("Server closed connection~n");
        {tcp_error, Socket, Reason} ->
            io:format("Socket error: ~p~n", [Reason])
    after 5000 ->  %% 5 second timeout
        io:format("No response from server~n")
    end,
    

    %% close conn
    gen_tcp:close(Socket).