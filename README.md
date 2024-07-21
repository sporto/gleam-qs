# Gleam QS

A query string parser for Gleam.

## Install

```
gleam add valid
```

## Usage

QS has two modules `qs` (Basic) and `qs_adv` (Advance).

### Basic

A query `(QueryBasic)` in basic is a `Dict(String, List(String))`.

Basic has not concept of single or list values. Every value is a `List(String)`.

### Advanced

The Advance module provides configuration to explicitly define how single and list values are serialized.

A query `(QueryAdv)` is a `Dict(String, OneOrMany)`.

### Basic parsing

```gleam
import qs
import gleam/dict

"?color=red&pet=cat&pet=dog"
|> qs.default_parse

==

Ok(
  dict.from_list(
    [
      #("color", ["red"]),
      #("pet", ["cat", "dog"]),
    ]
  )
)
```

### Basic serialization

```gleam
import qs
import gleam/dict

let query = [
    #("color", ["red"]),
    #("pet", ["cat", "dog"])
  ]
  |> dict.from_list

qs.serialize(query)

> "?color=red&pet=cat&pet=dog"
```
