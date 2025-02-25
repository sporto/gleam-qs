import gleam/dict
import gleeunit/should
import qs/qs_adv.{Many, One} as qsa

fn config_compressed() {
  let scheme = qsa.SchemeListAsSingleValue(list_suffix: "[]", separator: "|")

  qsa.default_config()
  |> qsa.with_scheme(scheme)
}

fn test_roundtrip(
  config config: qsa.Config,
  input input: String,
  output output: String,
  query query: List(#(String, qsa.OneOrMany)),
) {
  let expected_query = dict.from_list(query)

  // Parse
  let assert Ok(parsed) =
    input
    |> qsa.parse(config)

  parsed
  |> should.equal(expected_query)

  // Serialize
  qsa.serialize(expected_query, config)
  |> should.equal(output)

  // Roundtrip
  parsed
  |> qsa.serialize(config)
  |> should.equal(output)
}

pub fn default_parse_test() {
  let config = qsa.default_config()

  let qs_1 = "?a=1"

  test_roundtrip(
    config: config,
    input: qs_1,
    query: [#("a", One("1"))],
    output: qs_1,
  )

  // It can parse two values
  let qs_2 = "?a=1&b=2"
  test_roundtrip(
    config: config,
    input: qs_2,
    query: [#("a", One("1")), #("b", One("2"))],
    output: qs_2,
  )

  // It can parse a list
  // And the list is in the given order
  let qs_3 = "?a[]=1&a[]=2"
  test_roundtrip(config: config, input: qs_3, output: qs_3, query: [
    #("a", Many(["1", "2"])),
  ])

  // A single value gets replaced with a list value
  let qs_4 = "?a=1&a[]=2"
  test_roundtrip(config: config, input: qs_4, output: "?a[]=2", query: [
    #("a", Many(["2"])),
  ])

  // A list value gets replaced with a single value
  let qs_5 = "?a[]=1&a=2"
  test_roundtrip(config: config, input: qs_5, output: "?a=2", query: [
    #("a", One("2")),
  ])

  // Empty value
  test_roundtrip(config: config, input: "?a[]", output: "", query: [])
}

pub fn decode_encode_test() {
  let config = qsa.default_config()

  // Decodes / Encodes the value
  let qs_1 = "?a=100%25%20great"
  let query_1 = [#("a", One("100% great"))]
  test_roundtrip(config: config, input: qs_1, output: qs_1, query: query_1)

  // Decodes / Encodes the key
  let qs_2 = "?a%25=great"
  let query_2 = [#("a%", One("great"))]
  test_roundtrip(config: config, input: qs_2, output: qs_2, query: query_2)

  // Can use already encoded keys
  let qs_3 = "?a%5B%5D=1"
  let query_3 = [#("a", Many(["1"]))]
  test_roundtrip(config: config, input: qs_3, output: "?a[]=1", query: query_3)

  // Decodes / Encodes the key
  let qs_4 = "?a%25[]=a|b"
  let query_4 = [#("a%", Many(["a", "b"]))]
  test_roundtrip(
    config: config_compressed(),
    input: qs_4,
    output: qs_4,
    query: query_4,
  )

  // Can use already encoded value
  let qs_5 = "?a[]=a%7Cb"
  let query_5 = [#("a", Many(["a", "b"]))]
  test_roundtrip(
    config: config_compressed(),
    input: qs_5,
    output: "?a[]=a|b",
    query: query_5,
  )
}

pub fn scheme_joined_values_test() {
  let scheme = qsa.SchemeListAsSingleValue(list_suffix: "[]", separator: "|")

  let config =
    qsa.default_config()
    |> qsa.with_scheme(scheme)

  let qs = "?pets[]=cat|dog"

  let query = [#("pets", Many(["cat", "dog"]))]

  test_roundtrip(config: config, input: qs, output: qs, query: query)
}

pub fn scheme_joined_missing_suffix_test() {
  // Suffix is missing in the given query string
  let scheme = qsa.SchemeListAsSingleValue(list_suffix: "[]", separator: "|")

  let config =
    qsa.default_config()
    |> qsa.with_scheme(scheme)

  let qs = "?pets=cat|dog"
  let output = "?pets=cat%7Cdog"

  let query = [#("pets", One("cat|dog"))]

  test_roundtrip(config: config, input: qs, output: output, query: query)
}

pub fn scheme_joined_no_separator_test() {
  // No separator
  let scheme = qsa.SchemeListAsSingleValue(list_suffix: "[]", separator: "")

  let config =
    qsa.default_config()
    |> qsa.with_scheme(scheme)

  let qs = "?pets[]=cat"

  let query = [#("pets", Many(["c", "a", "t"]))]

  test_roundtrip(config: config, input: qs, output: qs, query: query)
}

/// Utility
pub fn get_as_string_test() {
  []
  |> dict.from_list
  |> qsa.get_as_string("a")
  |> should.equal(Error("Invalid key a"))

  [#("a", One("1"))]
  |> dict.from_list
  |> qsa.get_as_string("a")
  |> should.equal(Ok("1"))

  [#("a", Many([]))]
  |> dict.from_list
  |> qsa.get_as_string("a")
  |> should.equal(Error("a is a list"))
}

pub fn get_as_bool_test() {
  [#("a", One("true"))]
  |> dict.from_list
  |> qsa.get_as_bool("a")
  |> should.equal(Ok(True))
}

pub fn get_as_int_test() {
  [#("a", One("2"))]
  |> dict.from_list
  |> qsa.get_as_int("a")
  |> should.equal(Ok(2))
}

pub fn get_as_float_test() {
  [#("a", One("2.1"))]
  |> dict.from_list
  |> qsa.get_as_float("a")
  |> should.equal(Ok(2.1))
}

pub fn get_as_list_test() {
  [#("a", One("1"))]
  |> dict.from_list
  |> qsa.get_as_list("a")
  |> should.equal(["1"])

  [#("a", Many(["1", "2"]))]
  |> dict.from_list
  |> qsa.get_as_list("a")
  |> should.equal(["1", "2"])
}

pub fn get_as_list_of_bool_test() {
  [#("a", One("true"))]
  |> dict.from_list
  |> qsa.get_as_list_of_bool("a")
  |> should.equal(Ok([True]))
}

pub fn get_as_list_of_int_test() {
  [#("a", One("1"))]
  |> dict.from_list
  |> qsa.get_as_list_of_int("a")
  |> should.equal(Ok([1]))
}

pub fn get_as_list_of_float_test() {
  [#("a", One("1.1"))]
  |> dict.from_list
  |> qsa.get_as_list_of_float("a")
  |> should.equal(Ok([1.1]))
}
// pub fn push_test() {
//   []
//   |> dict.from_list
//   |> qsa.push("a", "1")
//   |> dict.to_list
//   |> should.equal([#("a", Many(["1"]))])

//   [#("a", One("1"))]
//   |> dict.from_list
//   |> qsa.push("a", "2")
//   |> dict.to_list
//   |> should.equal([#("a", Many(["1", "2"]))])

//   [#("a", Many(["1"]))]
//   |> dict.from_list
//   |> qsa.push("a", "2")
//   |> dict.to_list
//   |> should.equal([#("a", Many(["1", "2"]))])
// }
