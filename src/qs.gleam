import gleam/list
import gleam/map.{Map}
import gleam/result
import gleam/string
import gleam/uri

pub type OneOrMany {
	One(String)
	Many(List(String))
}

pub type Query =
	Map(String, OneOrMany)

pub fn parse_key_value(segment: String) -> Result(#(String, String, Bool), String) {
	segment
	|> uri.percent_decode
	|> result.unwrap(segment)
	|> string.split_once(on: "=")
	|> result.map(fn(pair) {
		let #(k, v) = pair
		case string.ends_with(k, "[]") {
			True ->
				#(string.replace(k, "[]", ""), v, True)

			False ->
				#(k, v, False)
		}
	})
	|> result.replace_error("Unable to parse " |> string.append(segment))
}

pub fn parse(qs: String) -> Result(Query, String) {
	try segments = qs
	|> string.replace("?", "")
	|> string.split(on: "&")
	|> list.map(parse_key_value)
	|> result.all

	list.fold(
		over: segments,
		from: empty(),
		with: add_segment
	)
	|> map.map_values(reverse_many)
	|> Ok
}

fn add_segment(segment: #(String, String, Bool), query: Query) -> Query {
	let #(key, value, is_list) = segment

	let updater = fn(res) {
		case res {
			Ok(existing) ->
				// If OneOrMany doesn't match, we replace
				case is_list {
					True ->
						case existing {
							One(_) ->
								Many([value])

							Many(existing_list) ->
								Many([value, ..existing_list])
						}

					False ->
						One(value)
				}

			Error(_) ->
				case is_list {
					True ->
						Many([value])

					False ->
						One(value)
				}
		}
	}

	map.update(
		in: query,
		update: key,
		with: updater
	)
}

fn reverse_many(k: String, v: OneOrMany) -> OneOrMany {
	case v {
		Many(values) ->
			Many(list.reverse(values))

		_ ->
			v
	}

}

pub fn empty() -> Query {
	map.new()
}