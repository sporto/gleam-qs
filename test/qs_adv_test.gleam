import gleam/dict
import gleeunit/should
import qs_adv.{Many, One} as qsa

fn test_default_parse_ok(input: String, expected) {
  input
  |> qsa.default_parse
  |> should.equal(Ok(
    expected
    |> dict.from_list,
  ))
}

pub fn default_parse_test() {
  test_default_parse_ok("?a=1", [#("a", One("1"))])

  // It can parse two values
  test_default_parse_ok("?a=1&b=2", [#("a", One("1")), #("b", One("2"))])

  // It can parse a list
  // And the list is in the given order
  test_default_parse_ok("?a[]=1&a[]=2", [#("a", Many(["1", "2"]))])

  // A single value gets replaced with a list value
  test_default_parse_ok("?a=1&a[]=2", [#("a", Many(["2"]))])

  // A list value gets replaced with a single value
  test_default_parse_ok("?a[]=1&a=2", [#("a", One("2"))])
  // Empty value
  test_default_parse_ok("?a[]", [])
}

pub fn decode_when_parsing_test() {
  test_default_parse_ok("?a=100%25%20great", [#("a", One("100% great"))])
}

fn test_schema_parse_ok(
  input: String,
  scheme: qsa.Scheme,
  expected: List(#(String, qsa.OneOrMany)),
) {
  let config =
    qsa.default_config()
    |> qsa.with_scheme(scheme)

  input
  |> qsa.parse(config)
  |> should.equal(Ok(
    expected
    |> dict.from_list,
  ))
}

pub fn parse_scheme_joined_test() {
  test_schema_parse_ok(
    "?pets[]=cat|dog",
    qsa.SchemeListAsSingleValue(list_suffix: "[]", separator: "|"),
    [#("pets", Many(["cat", "dog"]))],
  )

  // Suffix is missing
  test_schema_parse_ok(
    "?pets=cat|dog",
    qsa.SchemeListAsSingleValue(list_suffix: "[]", separator: "|"),
    [#("pets", One("cat|dog"))],
  )

  // No suffix, everything is a list
  test_schema_parse_ok(
    "?pets=cat|dog",
    qsa.SchemeListAsSingleValue(list_suffix: "", separator: "|"),
    [#("pets", Many(["cat", "dog"]))],
  )

  // No separator
  test_schema_parse_ok(
    "?pets[]=cat",
    qsa.SchemeListAsSingleValue(list_suffix: "[]", separator: ""),
    [#("pets", Many(["c", "a", "t"]))],
  )
}

fn test_default_serialize(input, expected) {
  input
  |> dict.from_list
  |> qsa.default_serialize
  |> should.equal(expected)
}

pub fn default_serialize_test() {
  test_default_serialize([#("a", One("1"))], "?a=1")

  test_default_serialize([#("a", One("1")), #("b", One("2"))], "?a=1&b=2")

  test_default_serialize(
    [#("a", One("1")), #("b", Many(["2", "3"]))],
    "?a=1&b[]=2&b[]=3",
  )
}

pub fn encode_when_serializing_test() {
  test_default_serialize([#("a", One("100% great"))], "?a=100%25%20great")
}

pub fn serialize_with_scheme_test() {
  let config =
    qsa.default_config()
    |> qsa.with_scheme(qsa.SchemeListAsSingleValue(
      list_suffix: "[]",
      separator: "|",
    ))

  [#("pets", Many(["cat", "dog"]))]
  |> dict.from_list
  |> qsa.serialize(config)
  |> should.equal("?pets[]=cat|dog")
}

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
