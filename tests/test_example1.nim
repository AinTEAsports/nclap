import
  nclap,
  testutils

test "example 1":
  var p = newParser("example number 1, flags only")

  # NOTE: p.addFlag(short, long, description=long, holds_value=false, required=false, default=none[string]())
  p
    .addFlag("-h", "--help", "shows this help message", false)
    .addFlag("-vv", "--verbose", "shows additional informations", false)
    .addFlag("-o", "--output", "outputs to a file", true, true)
    .addFlag("-a", "--alias", "gives an alias ? I ran out of inspiration for this example", holds_value=true)

  let args = p.parse(@["-vv", "-o=output_file"])

  check ?args.verbose
  check !args.output == "output_file"
