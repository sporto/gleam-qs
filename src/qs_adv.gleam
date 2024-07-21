import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import qs

pub type OneOrMany {
  One(String)
  Many(List(String))
}

pub type QueryAdv =
  qs.Query(OneOrMany)

/// Parse a query string
///
/// ## Example
///
/// ```
/// "?color=red&tags[]=large&tags[]=wool"
/// |> qs.parse
///
/// > Ok([ #("color", qs.One("red")), #("tags", qs.Many(["large", "wool"])) ] |> dict.from_list)
/// ```
///
pub fn parse(qs: String) -> Result(QueryAdv, String) {
  use key_values <- result.then(qs.split_and_parse(qs))

  list.fold(over: key_values, from: empty(), with: add_key_value)
  |> Ok
}

fn add_key_value(query: QueryAdv, key_value: qs.RawKeyValue) -> QueryAdv {
  let list_suffix = "[]"
  let #(raw_key, raw_value) = key_value

  let #(is_list, key) = case string.ends_with(raw_key, list_suffix) {
    True -> #(True, string.replace(raw_key, list_suffix, ""))
    False -> #(False, raw_key)
  }

  let updater = fn(res) {
    case res {
      Some(existing) ->
        // If OneOrMany doesn't match, we replace
        case is_list {
          True ->
            case existing {
              One(_) -> Many([raw_value])
              Many(existing_list) ->
                Many(list.append(existing_list, [raw_value]))
            }

          False -> One(raw_value)
        }

      None ->
        case is_list {
          True -> Many([raw_value])
          False -> One(raw_value)
        }
    }
  }

  dict.upsert(in: query, update: key, with: updater)
}

/// Serialize a query
///
/// ## Example
///
/// ```
/// [ #("color", qs.One("red")), #("tags", qs.Many(["large", "wool"])) ] |> qs.serialize
/// > "?color=red&tags[]=large&tags[]=wool"
/// ```
pub fn serialize(query: QueryAdv) -> String {
  qs.serialize_with(query, serialize_key_value)
}

fn serialize_key_value(key_value: #(String, OneOrMany)) -> List(String) {
  let #(key, one_or_many) = key_value

  case one_or_many {
    One(value) -> [qs.join_key_value(key, value, "=")]

    Many(values) -> {
      values
      |> list.map(qs.join_key_value(key, _, "[]="))
    }
  }
}

pub fn empty() -> QueryAdv {
  qs.empty()
}

pub fn get(query: QueryAdv, key: String) -> Result(OneOrMany, String) {
  qs.get(query, key)
}

/// Attempt to get one value as a string
/// If the value is a list this will fail
pub fn get_as_string(query: QueryAdv, key: String) -> Result(String, String) {
  use one_or_many <- result.then(get(query, key))

  case one_or_many {
    One(value) -> Ok(value)
    Many(_) ->
      Error(
        key
        |> string.append(" is a list"),
      )
  }
}

/// Attempt to get one value as a Bool
/// If the value is a list this will fail
pub fn get_as_bool(query: QueryAdv, key: String) -> Result(Bool, String) {
  get_as_string(query, key)
  |> result.then(parse_bool)
}

/// Attempt to get one value as an Int
/// If the value is a list this will fail
pub fn get_as_int(query: QueryAdv, key: String) -> Result(Int, String) {
  use value <- result.then(get_as_string(query, key))

  value
  |> int.parse
  |> result.replace_error(
    "Invalid Int "
    |> string.append(value),
  )
}

/// Attempt to get one value as an Float
/// If the value is a list this will fail
pub fn get_as_float(query: QueryAdv, key: String) -> Result(Float, String) {
  use value <- result.then(get_as_string(query, key))

  value
  |> float.parse
  |> result.replace_error(
    "Invalid Float "
    |> string.append(value),
  )
}

/// Get values from the query as a list of strings (regardless if one or many).
/// If keys are not present this defaults to an empty list
pub fn get_as_list(query: QueryAdv, key: String) -> List(String) {
  maybe_get_as_list(query, key)
  |> result.unwrap([])
}

/// Attempt to get values as a list of Bool
pub fn get_as_list_of_bool(
  query: QueryAdv,
  key: String,
) -> Result(List(Bool), String) {
  get_as_list(query, key)
  |> list.map(parse_bool)
  |> result.all
}

/// Attempt to get values as a list of Int
pub fn get_as_list_of_int(
  query: QueryAdv,
  key: String,
) -> Result(List(Int), String) {
  get_as_list(query, key)
  |> list.map(int.parse)
  |> result.all
  |> result.replace_error("Couldn't parse all values")
}

/// Attempt to get values as a list of Float
pub fn get_as_list_of_float(
  query: QueryAdv,
  key: String,
) -> Result(List(Float), String) {
  get_as_list(query, key)
  |> list.map(float.parse)
  |> result.all
  |> result.replace_error("Couldn't parse all values")
}

// Get values from the query as a list of strings. If key is not present this returns an Error.
pub fn maybe_get_as_list(
  query: QueryAdv,
  key: String,
) -> Result(List(String), String) {
  get(query, key)
  |> result.map(to_list)
}

/// Tell if the query has the given key
pub fn has_key(query: QueryAdv, key: String) -> Bool {
  qs.has_key(query, key)
}

pub fn insert(query: QueryAdv, key: String, value: OneOrMany) {
  qs.insert(query, key, value)
}

/// Set a unique value in the query
pub fn insert_one(query: QueryAdv, key: String, value: String) {
  insert(query, key, One(value))
}

/// Set a list of values in the query
pub fn insert_list(query: QueryAdv, key: String, values: List(String)) {
  insert(query, key, Many(values))
}

pub fn merge(a: QueryAdv, b: QueryAdv) {
  qs.merge(a, b)
}

pub fn delete(query: QueryAdv, key: String) {
  qs.delete(query, key)
}

fn to_list(one_or_many: OneOrMany) -> List(String) {
  case one_or_many {
    One(value) -> [value]
    Many(values) -> values
  }
}

fn parse_bool(s: String) -> Result(Bool, String) {
  case s {
    "true" -> Ok(True)
    "false" -> Ok(False)
    _ ->
      Error(
        "Invalid "
        |> string.append(s),
      )
  }
}
