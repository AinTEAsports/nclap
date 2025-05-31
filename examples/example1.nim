import nclap

var p = newParser("example number 1, flags only")

# NOTE: p.addFlag(short, long, description=long, holds_value=false, required=false, default=none[string]())
p
  .addFlag("-h", "--help", "shows this help message", false)
  .addFlag("-vv", "--verbose", "shows additional informations", false)
  .addFlag("-o", "--output", "outputs to a file", true, true)
  .addFlag("-a", "--alias", "gives an alias ? I ran out of inspiration for this example", holds_value=true)

let args = p.parse()

# `?args.help` <=> `args.help.registered`
# `args.help` <=> `?args.h`
if ?args.help:  
  p.showHelp(exit_code=1)

if ?args.verbose:
  echo "Showing additional information"

# `!args.output` <=> `args.output.getContent()` <=> `args.output.getContent(error=true)`
echo "Output goes to: " & !args.output

# `args.alias !! "default value here"` <=> `args.alias.getContent(default="default value here")`
echo "Alias: " & (args.alias !! "default value here")
