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
import gleam/dict

"?color=red&tags[]=large&tags[]=wool"
|> qs.parse

> Ok([ #("color", qs.One("red")), #("tags", qs.Many(["large", "wool"])) ] |> dict.from_list)
```

## Serialize

```
import qs
import gleam/dict

let query = [
    #("a", qs.One("1")),
    #("b", qs.Many(["2", "3"]))
  ]
  |> dict.from_list

qs.serialize(query)

> "?a=1&b[]=2&b[]=3"
```

## Installation

If available on Hex this package can be added to your Gleam project:

```sh
gleam add gleam_qs
```

and its documentation can be found ad <https://hexdocs.pm/gleam_qs>
