import gleam_qs
import gleam/should

pub fn hello_world_test() {
  gleam_qs.hello_world()
  |> should.equal("Hello, from gleam_qs!")
}
