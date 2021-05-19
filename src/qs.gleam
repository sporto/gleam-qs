import gleam/string
import gleam/result

pub type OneOrMany {
	One(String)
	Many(List(String))
}

pub fn parse_key_value(segment: String) -> Result(#(String, String), String) {
	string.split_once(segment, on: "=")
	|> result.replace_error("Unable to parse " |> string.append(segment))
}
