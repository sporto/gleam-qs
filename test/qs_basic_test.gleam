import gleam/dict
import gleeunit/should
import qs

pub fn parse_key_value_test() {
  qs.parse_key_value("a=x")
  |> should.equal(Ok(#("a", "x")))
}

fn test_default_parse_ok(input: String, expected) {
  input
  |> qs.default_parse
  |> should.equal(Ok(
    expected
    |> dict.from_list,
  ))
}

pub fn default_parse_test() {
  test_default_parse_ok("?a=1", [#("a", ["1"])])

  // It can default_parse two values
  test_default_parse_ok("?a=1&b=2", [#("a", ["1"]), #("b", ["2"])])

  // It can default_parse duplicates
  // And the list is in the given order
  test_default_parse_ok("?a=1&a=2", [#("a", ["1", "2"])])

  // default_parses duplicates with symbols
  test_default_parse_ok("?a[]=1&a[]=2", [#("a[]", ["1", "2"])])

  // No value
  test_default_parse_ok("?a&a=2", [#("a", ["2"])])
}

pub fn decode_when_parsing_test() {
  test_default_parse_ok("?a=100%25%20great", [#("a", ["100% great"])])
}

pub fn no_value_fails_test() {
  let config = qs.Config(..qs.default_config(), fail_on_invalid: True)

  qs.parse("?a&a=2", config)
  |> should.equal(Error("Unable to parse a"))

  qs.parse("?a=&a=2", config)
  |> should.equal(Error("Unable to parse a="))
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
  test_serialize([#("a", ["1", "2"])], "?a=1&a=2")
  test_serialize([#("b[", ["2", "3"])], "?b%5B=2&b%5B=3")
  test_serialize([#("b", ["2|3"])], "?b=2%7C3")
}

pub fn encode_when_serializing_test() {
  test_serialize([#("a", ["100% great"])], "?a=100%25%20great")
}
