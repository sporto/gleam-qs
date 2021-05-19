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