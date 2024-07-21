import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri

pub type Query(v) =
  Dict(String, v)

pub type QueryBasic =
  Query(List(String))

pub type Config {
  Config(fail_on_invalid: Bool)
}

pub fn default_config() -> Config {
  Config(fail_on_invalid: False)
}

@internal
pub type RawKeyValue =
  #(String, String)

@internal
pub fn parse_key_value(segment: String) -> Result(RawKeyValue, String) {
  let decoded =
    segment
    |> uri.percent_decode
    |> result.unwrap(segment)

  let split_result = string.split_once(decoded, on: "=")
  let unabled_to_parse = "Unable to parse " <> segment

  case split_result {
    Ok(#(key, value)) -> {
      case value {
        "" -> Error(unabled_to_parse)
        _ -> Ok(#(key, value))
      }
    }
    Error(_) -> Error(unabled_to_parse)
  }
}

/// Parse a query string.
/// Values that cannot be parsed are ignored.
///
/// ## Example
///
/// ```
/// "?color=red&tags=large&tags=wool"
/// |> qs.default_parse
///
/// ==
///
/// Ok(
///   dict.from_list(
///     [ #("color", ["red"]), #("tags", ["large", "wool"]) ]
///   )
/// )
/// ```
///
pub fn default_parse(qs: String) -> Result(QueryBasic, String) {
  parse(qs, default_config())
}

pub fn parse(input: String, config: Config) -> Result(QueryBasic, String) {
  use key_values <- result.then(split_and_parse(input, config.fail_on_invalid))

  list.fold(over: key_values, from: empty(), with: add_key_value)
  |> Ok
}

@internal
pub fn split_and_parse(query: String, fail_on_invalid: Bool) -> Result(
  List(RawKeyValue),
  String,
) {
  let results =
    query
    |> string.replace("?", "")
    |> string.split(on: "&")
    |> list.map(parse_key_value)

  case fail_on_invalid {
    True -> results |> result.all
    False -> results |> result.values |> Ok
  }
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

/// Serialize a query
///
/// ## Example
///
/// ```
/// [ #("color", ["red"]), #("tag", ["large", "wool"]) ]
/// |> qs.default_serialize
///
/// ==
///
/// "?color=red&tag=large&tag=wool"
/// ```
pub fn default_serialize(query: QueryBasic) -> String {
  query
  |> dict.to_list
  |> list.flat_map(serialize_key_value)
  |> string.join("&")
  |> add_question_mark
}

fn serialize_key_value(key_value: #(String, List(String))) -> List(String) {
  let #(key, values) = key_value
  list.map(values, fn(value) {
    uri.percent_encode(key) <> "=" <> uri.percent_encode(value)
  })
}

@internal
pub fn add_question_mark(query: String) -> String {
  "?" <> query
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

/// Merge two Querys.
/// Second query takes precedence.
pub fn merge(a: Query(a), b: Query(a)) {
  dict.merge(a, b)
}

/// Delete a key from the query
pub fn delete(query: Query(a), key: String) {
  dict.delete(query, key)
}
