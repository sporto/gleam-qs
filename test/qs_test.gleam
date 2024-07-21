import gleam/dict
import gleeunit/should
import qs

pub fn parse_key_value_test() {
  qs.parse_key_value("a=x")
  |> should.equal(Ok(#("a", "x")))
}

fn test_parse_ok(input: String, expected) {
  input
  |> qs.parse
  |> should.equal(Ok(
    expected
    |> dict.from_list,
  ))
}

pub fn parse_test() {
  test_parse_ok("?a=1", [#("a", ["1"])])

  // It can parse two values
  test_parse_ok("?a=1&b=2", [#("a", ["1"]), #("b", ["2"])])

  // It can parse duplicates
  // And the list is in the given order
  test_parse_ok("?a=1&a=2", [#("a", ["1", "2"])])

  // parses duplicates with symbols
  test_parse_ok("?a[]=1&a[]=2", [#("a[]", ["1", "2"])])
  // No value
}

pub fn decode_when_parsing_test() {
  test_parse_ok("?a=100%25%20great", [#("a", ["100% great"])])
}

fn test_serialize(input, expected) {
  input
  |> dict.from_list
  |> qs.serialize
  |> should.equal(expected)
}

pub fn serialize_test() {
  test_serialize([#("a", ["1"])], "?a=1")
  test_serialize([#("a", ["1"]), #("b", ["2"])], "?a=1&b=2")
  test_serialize([#("b[", ["2", "3"])], "?b%5B=2&b%5B=3")
  test_serialize([#("b", ["2|3"])], "?b=2%7C3")
}

pub fn encode_when_serializing_test() {
  test_serialize([#("a", ["100% great"])], "?a=100%25%20great")
}
