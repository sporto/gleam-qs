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

///Parse a query string
///
/// ## Example
///
/// ```
/// "?color=red&tags[]=large&tags[]=wool"
/// |> qs.parse
///
/// > Ok([ #("color", qs.One("red")), #("tags", qs.Many(["large", "wool"])) ] |> map.from_list)
/// ```
///
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

fn reverse_many(_k: String, v: OneOrMany) -> OneOrMany {
	case v {
		Many(values) ->
			Many(list.reverse(values))

		_ ->
			v
	}

}

/// Serialize a query
///
/// ## Example
///
/// ```
/// [ #("color", qs.One("red")), #("tags", qs.Many(["large", "wool"])) ] |> qs.serialize
/// > "?color=red&tags[]=large&tags[]=wool"
/// ```
pub fn serialize(query: Query) -> String {
	query
	|> map.to_list
	|> list.map(serialize_key)
	|> list.flatten
	|> string.join("&")
	|> add_question_mark
}

fn serialize_key(
		input: #(String, OneOrMany)
	) -> List(String) {

	let #(key, one_or_many) = input

	case one_or_many {
		One(value) ->
			[ join_key_value(key, value, "=") ]

		Many(values) -> {
			values
			|> list.map(join_key_value(key, _, "[]="))
		}
	}
}

fn join_key_value(key: String, value: String, join: String) -> String {
	key
	|> uri.percent_encode
	|> string.append(join)
	|> string.append(value |> uri.percent_encode)
}

fn add_question_mark(query: String) -> String {
	"?" |> string.append(query)
}

/// Make an empty Query
pub fn empty() -> Query {
	map.new()
}

/// Get values from the query
pub fn get(
		query: Query,
		key: String
	) -> Result(OneOrMany, String) {

	let error = "Invalid key " |> string.append(key)

	map.get(query, key)
	|> result.replace_error(error)
}

/// Attempt to get one value as a string
/// If the value is a list this will fail
pub fn get_as_string(
		query: Query,
		key: String
	) -> Result(String, String) {

	try one_or_many = get(query, key)

	case one_or_many {
		One(value) ->
			Ok(value)
		Many(_) ->
			Error(key |> string.append(" is a list"))
	}
}

/// Get values from the query as a list of strings (regardless if one or many).
/// If keys are not present this defaults to an empty list
pub fn get_as_list(
		query: Query, key: String
	) -> List(String) {

	maybe_get_as_list(query, key)
	|> result.unwrap([])
}

// Get values from the query as a list of strings. If key is not present this returns an Error.
pub fn maybe_get_as_list(
		query: Query, key: String
	) -> Result(List(String), String) {

	get(query, key)
	|> result.map(to_list)
}

/// Tell if the query has the given key
pub fn has_key(query: Query, key: String) -> Bool {
	map.has_key(query, key)
}

/// Insert a value in the query
pub fn insert(query: Query, key: String, value: OneOrMany) {
	map.insert(query, key, value)
}

/// Set a unique value in the query
pub fn insert_one(query: Query, key: String, value: String) {
	insert(query, key, One(value))
}

/// Set a list of values in the query
pub fn insert_list(query: Query, key: String, values: List(String)) {
	insert(query, key, Many(values))
}

/// Adds one value to a list
/// If the key is not a list then it will be promoted to a list
/// If the key doesn't exist then it will be added as a list of one item
pub fn push(query: Query, key: String, value: String) {
	map.update(
		in: query,
		update: key,
		with: fn(res) {
			case res {
				Ok(current) ->
					case current {
						One(one) ->
							Many([one, value])

						Many(many) ->
							Many(list.append(many, [value]))
					}

				Error(_) ->
					Many([value])
			}
		}
	)
}

/// Merge two Querys.
/// If there are entries with the same keys in both maps the entry from the second query takes precedence.
pub fn merge(a: Query, b: Query) {
	map.merge(a, b)
}

/// Delete a key from the query
pub fn delete(query: Query, key: String) {
	map.delete(query, key)
}

fn to_list(one_or_many: OneOrMany) -> List(String) {
	case one_or_many {
		One(value) ->
			[ value ]
		Many(values) ->
			values
	}
}