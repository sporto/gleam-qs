import gleam/dict
import gleam/float
import gleam/int
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

pub type Scheme {
  SchemeListAsMultipleValues(list_suffix: String)
  SchemeListAsSingleValue(list_suffix: String, separator: String)
}

pub fn scheme_rails_like() -> Scheme {
  SchemeListAsMultipleValues(list_suffix: "[]")
}

pub type Config {
  Config(fail_on_invalid: Bool, scheme: Scheme)
}

pub fn default_config() -> Config {
  Config(fail_on_invalid: False, scheme: scheme_rails_like())
}

pub type ParseInput {
  ParseInput(query: String, config: Config)
}

/// Parse a query string
///
/// ## Example
///
/// ```
/// "?color=red&tags[]=large&tags[]=wool"
/// |> qs.default_parse
///
/// ==
///
/// Ok(
///   dict.from_list(
///     [ #("color", One("red")), #("tags", Many(["large", "wool"])) ]
///   )
/// )
/// ```
///
pub fn default_parse(qs: String) -> Result(QueryAdv, String) {
  parse_input(qs)
  |> parse
}

pub fn parse_input(query: String) -> ParseInput {
  ParseInput(query: query, config: default_config())
}

/// Replace the configuration on ParseInput
pub fn with_config(input: ParseInput, config: Config) -> ParseInput {
  ParseInput(..input, config: config)
}

pub fn with_fail_on_invalid(input: ParseInput, value: Bool) -> ParseInput {
  ParseInput(..input, config: Config(..input.config, fail_on_invalid: value))
}

pub fn with_scheme(input: ParseInput, scheme: Scheme) -> ParseInput {
  ParseInput(..input, config: config_with_scheme(input.config, scheme))
}

pub fn config_with_scheme(config: Config, scheme: Scheme) -> Config {
  Config(..config, scheme: scheme)
}

pub fn parse(input: ParseInput) -> Result(QueryAdv, String) {
  use key_values <- result.then(qs.split_and_parse(
    input.query,
    input.config.fail_on_invalid,
  ))

  list.fold(over: key_values, from: empty(), with: fn(query, key_value) {
    add_key_value(input.config.scheme, query, key_value)
  })
  |> Ok
}

fn add_key_value(
  scheme: Scheme,
  query: QueryAdv,
  key_value: qs.RawKeyValue,
) -> QueryAdv {
  let list_suffix = scheme.list_suffix
  let #(raw_key, raw_value) = key_value

  let #(is_list, key) = case string.ends_with(raw_key, list_suffix) {
    True -> #(True, string.replace(raw_key, list_suffix, ""))
    False -> #(False, raw_key)
  }

  let updater = fn(res) {
    case is_list, res {
      True, Some(existing) -> {
        case existing {
          One(_) -> value_as_many(raw_value, [], scheme)
          Many(existing_values) ->
            value_as_many(raw_value, existing_values, scheme)
        }
      }
      // The list doesn't exist yet
      True, None -> value_as_many(raw_value, [], scheme)
      // A single value is always replaced
      // So we don't care if it exists
      False, _ -> One(raw_value)
    }
  }

  dict.upsert(in: query, update: key, with: updater)
}

fn value_as_many(
  raw_value: String,
  existing_values: List(String),
  scheme: Scheme,
) -> OneOrMany {
  let added_values = get_list_value(raw_value, scheme)
  let next_values = list.append(existing_values, added_values)
  Many(next_values)
}

fn get_list_value(raw_value: String, scheme: Scheme) -> List(String) {
  case scheme {
    SchemeListAsSingleValue(_, separator) -> {
      string.split(raw_value, separator)
    }
    SchemeListAsMultipleValues(_) -> [raw_value]
  }
}

/// Serialize a query
///
/// ## Example
///
/// ```
/// [ #("color", One("red")), #("tags", Many(["large", "wool"])) ]
/// |> qs.serialize
///
/// ==
///
/// "?color=red&tags[]=large&tags[]=wool"
/// ```
pub fn default_serialize(query: QueryAdv) -> String {
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

/// Attempt to get one value as a String.
/// If the value is a list this fails.
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

/// Attempt to get one value as a Bool.
/// If the value is a list this fails.
/// If the value cannot be parsed to a Bool this fails.
pub fn get_as_bool(query: QueryAdv, key: String) -> Result(Bool, String) {
  get_as_string(query, key)
  |> result.then(parse_bool)
}

/// Attempt to get one value as an Int.
/// If the value is a list this fails.
/// If the value cannot be parsed to an Int this fails.
pub fn get_as_int(query: QueryAdv, key: String) -> Result(Int, String) {
  use value <- result.then(get_as_string(query, key))

  value
  |> int.parse
  |> result.replace_error(
    "Invalid Int "
    |> string.append(value),
  )
}

/// Attempt to get one value as an Float.
/// If the value is a list this fail.
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
/// If key is not present this defaults to an empty list.
pub fn get_as_list(query: QueryAdv, key: String) -> List(String) {
  maybe_get_as_list(query, key)
  |> result.unwrap([])
}

/// Attempt to get values as a list of Bool.
pub fn get_as_list_of_bool(
  query: QueryAdv,
  key: String,
) -> Result(List(Bool), String) {
  get_as_list(query, key)
  |> list.map(parse_bool)
  |> result.all
}

/// Attempt to get values as a list of Int.
pub fn get_as_list_of_int(
  query: QueryAdv,
  key: String,
) -> Result(List(Int), String) {
  get_as_list(query, key)
  |> list.map(int.parse)
  |> result.all
  |> result.replace_error("Couldn't parse all values")
}

/// Attempt to get values as a list of Float.
pub fn get_as_list_of_float(
  query: QueryAdv,
  key: String,
) -> Result(List(Float), String) {
  get_as_list(query, key)
  |> list.map(float.parse)
  |> result.all
  |> result.replace_error("Couldn't parse all values")
}

/// Get values from the query as a list of strings.
/// If key is not present this returns an Error.
pub fn maybe_get_as_list(
  query: QueryAdv,
  key: String,
) -> Result(List(String), String) {
  get(query, key)
  |> result.map(to_list)
}

/// Tell if the query has the given key.
pub fn has_key(query: QueryAdv, key: String) -> Bool {
  qs.has_key(query, key)
}

/// Insert value.
pub fn insert(query: QueryAdv, key: String, value: OneOrMany) {
  qs.insert(query, key, value)
}

/// Set a unique value in the query.
pub fn insert_one(query: QueryAdv, key: String, value: String) {
  insert(query, key, One(value))
}

/// Set a list of values in the query.
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
