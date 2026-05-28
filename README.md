# Erlang TCP Client

An Erlang TCP client for communicating with the C++ JSON RPC server.

The client connects to the server, sends JSON-based RPC requests, and receives structured responses over a TCP socket.

## Features

* TCP client using `gen_tcp`
* JSON request/response communication
* Length-prefixed binary protocol
* Automatic API parsing from `api_spec.json` generated from the server
* Sequential RPC testing
* Asynchronous socket handling


## Requirements

* Erlang/OTP

## Compile

```bash
rebar3 compile
```

## Run

Start Erlang shell:

```bash
rebar3 shell
```

Run client:

```erlang
tcp_client:start("localhost", 5555).
```

## Protocol

Messages use:

```text
[4-byte big-endian length][JSON payload]
```

Example request:

```json
{
  "id": 1,
  "cmd": "add_values",
  "args": [2, 3]
}
```

Example response:

```json
{
  "id": 1,
  "status": "ok",
  "result": 5
}
```

---

## Supported RPC Calls

| Command           | Arguments  | Description           |
| ----------------- | ---------- | --------------------- |
| `add_values`      | `[a, b]`   | Adds two integers     |
| `multiply_values` | `[a, b]`   | Multiplies two values |
| `reverse_string`  | `["text"]` | Reverses a string     |


## Workflow

```text
Erlang Client
      |
gen_tcp:connect()
      |
JSON RPC Request
      |
Length Encoding
      |
TCP Socket
      |
C++ Server
      |
JSON Response
      |
Erlang Process Mailbox
```


## Notes

* Uses `{packet, 4}` for automatic 4-byte packet framing.
* Uses `{active, true}` for asynchronous message delivery to the Erlang mailbox.
* Requests are encoded using `jsx`.
* Responses are decoded back into Erlang maps.