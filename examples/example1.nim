import nclap/[
  parser,
  cliargs,
  arguments
]

var p = newParser("example number 1, flags only")

# NOTE: p.addFlag(short, long, description=long, holds_value=false, required=false)
p.addFlag("-h", "--help", "shows this help message", false)
  .addFlag("-vv", "--verbose", "shows additional informations", false)
  .addFlag("-o", "--output", "outputs to a file", true, true)

let args = p.parse()

# you can access the flag value with the short or the long version
if args["--help"].registered:
  p.showHelp(exit_code=1)

if args["-vv"].registered:
  echo "Showing additional information"

echo "Output goes to: " & args["--output"].getContent(error=true)
