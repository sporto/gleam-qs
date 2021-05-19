import qs
import gleam/should

pub fn parse_key_value_test() {
	let segment = "a=x"

	qs.parse_key_value(segment)
	|> should.equal(Ok(#("a", "x")))

	let segment2 = "a[]=x"

	qs.parse_key_value(segment2)
	|> should.equal(Ok(#("a[]", "x")))
}