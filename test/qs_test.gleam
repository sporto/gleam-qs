import qs.{One,Many}
import gleam/should
import gleam/map

pub fn parse_key_value_test() {
	let segment = "a=x"

	qs.parse_key_value(segment)
	|> should.equal(Ok(#("a", "x", False)))

	let segment2 = "a[]=x"

	qs.parse_key_value(segment2)
	|> should.equal(Ok(#("a", "x", True)))
}

fn test_parse_ok(input: String, expected) {
	input
	|> qs.parse
	|> should.equal(Ok(
		expected |> map.from_list
	))
}

pub fn parse_test() {
	test_parse_ok(
		"?a=1",
		[ #("a", One("1")) ]
	)

	// It can parse two values
	test_parse_ok(
		"?a=1&b=2",
		[ #("a", One("1")), #("b", One("2")) ]
	)

	// It can parse a list
	// And the list is in the given order
	test_parse_ok(
		"?a[]=1&a[]=2",
		[ #("a", Many(["1", "2"])) ]
	)

	// A single value gets replaced with a list value
	test_parse_ok(
		"?a=1&a[]=2",
		[ #("a", Many(["2"])) ]
	)

	// A list value gets replaced with a single value
	test_parse_ok(
		"?a[]=1&a=2",
		[ #("a", One("2")) ]
	)
}

pub fn decode_when_parsing_test() {
	test_parse_ok(
		"?a=100%25+great",
		[ #("a", One("100% great")) ]
	)
}

fn test_serialize(input, expected) {
	input
	|> map.from_list
	|> qs.serialize
	|> should.equal(expected)
}

pub fn serialize_test() {
	test_serialize(
		[ #("a", One("1")) ],
		"?a=1"
	)

	test_serialize(
		[
			#("a", One("1")),
			#("b", One("2"))
		],
		"?a=1&b=2"
	)

	test_serialize(
		[
			#("a", One("1")),
			#("b", Many(["2", "3"]))
		],
		"?a=1&b[]=2&b[]=3"
	)
}

pub fn encode_when_serializing_test() {
	test_serialize(
		[
			#("a", One("100% great")),
		],
		"?a=100%25+great"
	)
}

pub fn get_as_string_test() {
	[  ]
	|> map.from_list
	|> qs.get_as_string("a")
	|> should.equal(Error("Invalid key a"))

	[ #("a", One("1")) ]
	|> map.from_list
	|> qs.get_as_string("a")
	|> should.equal(Ok("1"))

	[ #("a", Many([])) ]
	|> map.from_list
	|> qs.get_as_string("a")
	|> should.equal(Error("a is a list"))
}

pub fn get_as_bool_test() {
	[ #("a", One("true")) ]
	|> map.from_list
	|> qs.get_as_bool("a")
	|> should.equal(Ok(True))
}

pub fn get_as_list_test() {
	[ #("a", One("1")) ]
	|> map.from_list
	|> qs.get_as_list("a")
	|> should.equal(["1"])

	[ #("a", Many(["1", "2"])) ]
	|> map.from_list
	|> qs.get_as_list("a")
	|> should.equal(["1", "2"])
}

pub fn push_test() {
	[ ]
	|> map.from_list
	|> qs.push("a", "1")
	|> map.to_list
	|> should.equal([ #("a", Many(["1"])) ])

	[ #("a", One("1")) ]
	|> map.from_list
	|> qs.push("a", "2")
	|> map.to_list
	|> should.equal([ #("a", Many(["1", "2"])) ])

	[ #("a", Many(["1"])) ]
	|> map.from_list
	|> qs.push("a", "2")
	|> map.to_list
	|> should.equal([ #("a", Many(["1", "2"])) ])
}