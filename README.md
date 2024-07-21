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

qs.default_serialize(query)

> "?color=red&pet=cat&pet=dog"
```

### Advanced parsing

By default advanced uses a Rails like query scheme. E.g.

```gleam
import qs_adv
import gleam/dict

"?color=red&pets[]=cat&pets[]=dog"
|> qs_adv.default_parse

==

Ok(
  dict.from_list(
    [
      #("color", One("red")),
      #("pets", Many(["cat", "dog"])),
    ]
  )
)
```

But this is configurable.

```gleam
let scheme = qs_adv.SchemeListAsSingleValue(
  list_suffix: "[]",
  separator: "|"
)

let config = qs_adv.default_config()
  |> qs_adv.with_scheme(scheme)

"?color=red&pets[]=cat|dog"
  |> qs_adv.parse(config)
```

### Advanced serialization

```gleam
import qs_adv
import gleam/dict

let query = [
    #("color", ["red"]),
    #("pets", ["cat", "dog"])
  ]
  |> dict.from_list

qs_adv.default_serialize(query)

> "?color=red&pets[]=cat&pets[]=dog"
```
