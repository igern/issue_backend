import issue_backend
import radiate

pub fn main() {
  let _ = radiate.new() |> radiate.add_dir("src") |> radiate.start()

  issue_backend.main()
}
