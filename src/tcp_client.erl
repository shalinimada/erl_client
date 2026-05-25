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
        [binary, {active, true}, {packet, 4}]
    ),
    io:format("Received socket handle: ~p~n", [Socket]),
    %% connection done


    Api = parse_api(),

    [First | _Rest] = maps:get(<<"functions">>, Api),

    % make_all_calls(Socket, Functions),

    Name = maps:get(<<"name">>, First),
    % Args = maps:get(<<"args">>, First),

    io:format("Auto calling: ~s~n", [Name]),

    %% fake args just for testing
    FakeArgs =
        case Name of
            <<"add">> -> [2, 3];
            <<"multiply">> -> [4.0, 5.0];
            <<"reverse">> -> ["hello"];
            _ -> []
        end,

    %% bin to list because cpp doesnt understand erlang binaries 
    call(Socket, Name, FakeArgs),

    % %% Wait for response as a message
    %% Wait for response as a message
    receive % extracts from mailbox
        {tcp, _Socket, Data} ->
            io:format("Response: ~p~n", [jsx:decode(Data, [return_maps])]);
        {tcp_closed, _Socket} ->
            io:format("Server closed connection~n");
        {tcp_error, _Socket, Reason} ->
            io:format("Socket error: ~p~n", [Reason])
    after 5000 ->  %% 5 second timeout
        io:format("No response from server~n")
    end,



    %% close conn
    % gen_tcp:close(Socket).
    wait_forever().


%%%%% ----------------- RPC ------------------- %%%%


call(Socket, Cmd, Args) ->
    Req = #{
        id => erlang:unique_integer([positive]),
        cmd => Cmd,
        args => Args
    },

    Bin = jsx:encode(Req),
    gen_tcp:send(Socket, encode_msg(Bin)),
    io:format("Sent RPC: ~p~n", [Bin]),
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
    {ok, Bin} = file:read_file("api.json"),
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
            <<"add">> -> [2, 3];
            <<"multiply">> -> [4.0, 5.0];
            <<"reverse">> -> ["hello-world"];
            _ -> []
        end,
    
    io:format("Calling ~s~n", [Name]),

    call(Socket, binary_to_list(Name), FakeArgs),
    make_all_calls(Socket, Rest).

