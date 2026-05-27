-module(tcp_client).
-export([start/2, call/3]).


start(Host, Port) ->
    % // connecting to localhost on port 5555, 
    % // using binary mode and no packet framing
    {ok, Socket} = gen_tcp:connect(
        Host,
        Port,
    % active = true the socket automatically sends messages to your process mailbox:
    %% 4 byte header + payload
        [binary, {active, true}, {packet, 4}] %% EACH SHELL ITS OWN TCP CLIENT
    ),
    io:format("Received socket handle: ~p~n", [Socket]),
    %% connection done


    Api = parse_api(),
    make_all_calls(Socket, maps:get(<<"functions">>, Api)),


    wait_forever().


%%%%% ----------------- RPC ------------------- %%%%


call(Socket, Cmd, Args) ->
    Req = #{
        id => erlang:unique_integer([positive]),
        cmd => Cmd,%% binary_to_list(Cmd), %% otheriwse cpp will see list of imts
        args => Args
    },

    Bin = jsx:encode(Req),
    gen_tcp:send(Socket, encode_msg(Bin)),
    io:format("Sent RPC (raw): ~p~n", [binary_to_list(Bin)]),
    ok.


%% encode msg to send
encode_msg(Msg) ->
    Len = byte_size(Msg),
    <<Len:32/big, Msg/binary>>.









%%%%% ----------------- Helpers ------------------- %%%%




%%%
wait_forever() ->
    receive
        {tcp, _Socket, Data} ->
            io:format("Response: ~p~n", [binary_to_term(Data)]),
            wait_forever();
        Any ->
            io:format("received something: ~p~n", [Any]),
            wait_forever()
    after 10000 ->
        io:format("still alive...~n"),
        wait_forever()
    end.




parse_api() ->
    {ok, Bin} = file:read_file("api_spec.json"),
    Api = jsx:decode(Bin, [return_maps]),
    io:format("====  API SPEC  ====~n"),
    Functions = maps:get(<<"functions">>, Api),
    lists:foreach(fun(F) ->
        Name = maps:get(<<"name">>, F),
        Args = maps:get(<<"args">>, F),
        Ret  = maps:get(<<"returns">>, F),
        io:format("~s(~p) -> ~s~n", [Name, Args, Ret])
    end, Functions),
    io:format("==========~n"),
    Api.








%%%%% ---- future 
make_all_calls(_socket, []) ->
    ok;

make_all_calls(Socket, [Function | Rest]) ->
    Name = maps:get(<<"name">>, Function),

    FakeArgs =
        case Name of
            <<"add_values">> -> [2, 3];
            <<"multiply_values">> -> [4.0, 5.0];
            <<"reverse_string">> -> ["hello world"];
            _ -> []
        end,
    
    io:format("~n~nCalling ~s~n", [Name]),

    call_and_wait(Socket, Name, FakeArgs),
    make_all_calls(Socket, Rest).

%% to send one command and wait for response before moving to next
call_and_wait(Socket, Name, FakeArgs) ->

    call(Socket, Name, FakeArgs),
    receive % extracts from mailbox
        {tcp, _Socket, Data} ->
            io:format("Response: ~p~n", [jsx:decode(Data, [return_maps])]);
        {tcp_closed, _Socket} ->
            io:format("Server closed connection~n");
        {tcp_error, _Socket, Reason} ->
            io:format("Socket error: ~p~n", [Reason])
    after 5000 ->  %% 5 second timeout
        io:format("No response from server~n")
    end.
