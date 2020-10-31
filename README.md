# ![Logo](https://raw.githubusercontent.com/am-kantox/agency/master/stuff/agency-48x48.png)  Agency

![Test](https://github.com/am-kantox/agency/workflows/Test/badge.svg)    [![Kantox ❤ OSS](https://img.shields.io/badge/❤-kantox_oss-informational.svg)](https://kantox.com/)    **One more unnecessary abstraction on top of `Agent`**

## Introduction

`Agency` is an abstraction layer above `Agent` allowing to use any
container supporting `Access` behind and simplifying the client API
handling.

`Agency` itself implements `Access` behaviour, making it possible to
embed instances in the middle of `Access.keys` chains.

In a nutshell, `Agency` backs up the `Agent` holding a container.
All the standard CRUD-like calls are done through containers’
`Access` implementation, allowing transparent shared access.

The set of `after_***/1` functions are introduced, so that the main
`Agent` feature distinguishing it from the standard `GenServer`
holding state—namely, a separation of client and server APIs—is
exposed transparently to the consumers.

## Installation

```elixir
def deps do
  [
    {:agency, "~> 0.1"}
  ]
end
```

### Changelog

- **`0.3.1`** `Agency.Multi` support is not optional anymore
- **`0.3.0`** `Agency.Multi` supporting the locally distributed agency (eliminating `:gen_server` mailbox bottleneck)

## [Documentation](https://hexdocs.pm/agency).
