# gleam_qs

A query string parser for Gleam. Based on https://github.com/ljharb/qs

QS uses `[]` for lists.

E.g.

```
?ids[]=1&ids[]=2
```

## Parse

```
import qs
import gleam/map

"?color=red&tags[]=large&tags[]=wool"
|> qs.parse

> Ok([ #("color", qs.One("red")), #("tags", qs.Many(["large", "wool"])) ] |> map.from_list)
```

## Serialize

TODO

## Installation

If [available in Hex](https://rebar3.org/docs/configuration/dependencies/#declaring-dependencies)
this package can be installed by adding `gleam_qs` to your `rebar.config` dependencies:

```erlang
{deps, [
    gleam_qs
]}.
```
