import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri

pub type Query(v) =
  Dict(String, v)

pub type QueryBasic =
  Query(List(String))

@internal
pub type RawKeyValue =
  #(String, String)

@internal
pub fn parse_key_value(segment: String) -> Result(RawKeyValue, String) {
  segment
  |> uri.percent_decode
  |> result.unwrap(segment)
  |> string.split_once(on: "=")
  |> result.replace_error(
    "Unable to parse "
    |> string.append(segment),
  )
}

/// Parse a query string
///
/// ## Example
///
/// ```
/// "?color=red&tags=large&tags=wool"
/// |> qs.parse
///
/// > Ok([ #("color", ["red")], #("tags", ["large", "wool"]) ] |> dict.from_list)
/// ```
///
pub fn parse(qs: String) -> Result(QueryBasic, String) {
  use key_values <- result.then(split_and_parse(qs))

  list.fold(over: key_values, from: empty(), with: add_key_value)
  |> Ok
}

@internal
pub fn split_and_parse(qs: String) -> Result(List(RawKeyValue), String) {
  qs
  |> string.replace("?", "")
  |> string.split(on: "&")
  |> list.map(parse_key_value)
  |> result.values
  |> Ok
}

fn add_key_value(query: QueryBasic, key_value: RawKeyValue) -> QueryBasic {
  let #(key, value) = key_value

  let updater = fn(res) {
    case res {
      Some(existing) -> list.append(existing, [value])
      None -> [value]
    }
  }

  dict.upsert(in: query, update: key, with: updater)
}

// fn reverse_many(_k: String, v: OneOrMany) -> OneOrMany {
//   case v {
//     Many(values) -> Many(list.reverse(values))

//     _ -> v
//   }
// }

/// Serialize a query
///
/// ## Example
///
/// ```
/// [ #("color", qs.One("red")), #("tags", qs.Many(["large", "wool"])) ] |> qs.serialize
/// > "?color=red&tags[]=large&tags[]=wool"
/// ```
pub fn serialize(query: QueryBasic) -> String {
  serialize_with(query, serialize_key_value)
}

@internal
pub fn serialize_with(query: Query(v), serialize_key_value: fn(#(String, v)) ->
  List(String)) -> String {
  query
  |> dict.to_list
  |> list.flat_map(serialize_key_value)
  |> string.join("&")
  |> add_question_mark
}

fn serialize_key_value(key_value: #(String, List(String))) -> List(String) {
  let #(key, values) = key_value
  list.map(values, fn(value) { join_key_value(key, value, "=") })
}

@internal
pub fn join_key_value(key: String, value: String, join: String) -> String {
  uri.percent_encode(key) <> join <> uri.percent_encode(value)
}

fn add_question_mark(query: String) -> String {
  "?"
  |> string.append(query)
}

/// Make an empty Query
pub fn empty() -> Query(v) {
  dict.new()
}

/// Get values from the query
pub fn get(query: Query(v), key: String) -> Result(v, String) {
  let error = "Invalid key " <> key

  dict.get(query, key)
  |> result.replace_error(error)
}

/// Tell if the query has the given key
pub fn has_key(query: Query(b), key: String) -> Bool {
  dict.has_key(query, key)
}

/// Insert a value in the query
/// Replaces existing values
pub fn insert(query: Query(b), key: String, value: b) {
  dict.insert(query, key, value)
}

// pub fn push(query: Query, key: String, value: String) {
//   div.update(in: query, update: key, with: fn(res) {
//     case res {
//       Some(current) ->
//         case current {
//           One(one) -> Many([one, value])

//           Many(many) -> Many(list.append(many, [value]))
//         }

//       None -> Many([value])
//     }
//   })
// }

/// Adds one value to a list
/// If the key is not a list then it will be promoted to a list
/// If the key doesn't exist then it will be added as a list of one item
/// Merge two Querys.
/// If there are entries with the same keys in both maps the entry from the second query takes precedence.
pub fn merge(a: Query(a), b: Query(a)) {
  dict.merge(a, b)
}

/// Delete a key from the query
pub fn delete(query: Query(a), key: String) {
  dict.delete(query, key)
}
