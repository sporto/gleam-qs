import gleam/dict
import gleeunit/should
import qs_adv.{Many, One}

// pub fn parse_key_value_test() {
//   let segment = "a=x"

//   qs_adv.parse_key_value(segment)
//   |> should.equal(Ok(#("a", "x", False)))

//   let segment2 = "a[]=x"

//   qs_adv.parse_key_value(segment2)
//   |> should.equal(Ok(#("a", "x", True)))
// }

fn test_default_parse_ok(input: String, expected) {
  input
  |> qs_adv.default_parse
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

fn test_serialize(input, expected) {
  input
  |> dict.from_list
  |> qs_adv.serialize
  |> should.equal(expected)
}

pub fn serialize_test() {
  test_serialize([#("a", One("1"))], "?a=1")

  test_serialize([#("a", One("1")), #("b", One("2"))], "?a=1&b=2")

  test_serialize(
    [#("a", One("1")), #("b", Many(["2", "3"]))],
    "?a=1&b[]=2&b[]=3",
  )
}

pub fn encode_when_serializing_test() {
  test_serialize([#("a", One("100% great"))], "?a=100%25%20great")
}

pub fn get_as_string_test() {
  []
  |> dict.from_list
  |> qs_adv.get_as_string("a")
  |> should.equal(Error("Invalid key a"))

  [#("a", One("1"))]
  |> dict.from_list
  |> qs_adv.get_as_string("a")
  |> should.equal(Ok("1"))

  [#("a", Many([]))]
  |> dict.from_list
  |> qs_adv.get_as_string("a")
  |> should.equal(Error("a is a list"))
}

pub fn get_as_bool_test() {
  [#("a", One("true"))]
  |> dict.from_list
  |> qs_adv.get_as_bool("a")
  |> should.equal(Ok(True))
}

pub fn get_as_int_test() {
  [#("a", One("2"))]
  |> dict.from_list
  |> qs_adv.get_as_int("a")
  |> should.equal(Ok(2))
}

pub fn get_as_float_test() {
  [#("a", One("2.1"))]
  |> dict.from_list
  |> qs_adv.get_as_float("a")
  |> should.equal(Ok(2.1))
}

pub fn get_as_list_test() {
  [#("a", One("1"))]
  |> dict.from_list
  |> qs_adv.get_as_list("a")
  |> should.equal(["1"])

  [#("a", Many(["1", "2"]))]
  |> dict.from_list
  |> qs_adv.get_as_list("a")
  |> should.equal(["1", "2"])
}

pub fn get_as_list_of_bool_test() {
  [#("a", One("true"))]
  |> dict.from_list
  |> qs_adv.get_as_list_of_bool("a")
  |> should.equal(Ok([True]))
}

pub fn get_as_list_of_int_test() {
  [#("a", One("1"))]
  |> dict.from_list
  |> qs_adv.get_as_list_of_int("a")
  |> should.equal(Ok([1]))
}

pub fn get_as_list_of_float_test() {
  [#("a", One("1.1"))]
  |> dict.from_list
  |> qs_adv.get_as_list_of_float("a")
  |> should.equal(Ok([1.1]))
}
// pub fn push_test() {
//   []
//   |> dict.from_list
//   |> qs_adv.push("a", "1")
//   |> dict.to_list
//   |> should.equal([#("a", Many(["1"]))])

//   [#("a", One("1"))]
//   |> dict.from_list
//   |> qs_adv.push("a", "2")
//   |> dict.to_list
//   |> should.equal([#("a", Many(["1", "2"]))])

//   [#("a", Many(["1"]))]
//   |> dict.from_list
//   |> qs_adv.push("a", "2")
//   |> dict.to_list
//   |> should.equal([#("a", Many(["1", "2"]))])
// }
