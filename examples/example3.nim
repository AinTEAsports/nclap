import nclap/[
  parser,
  cliargs,
  arguments
]

proc outputTo(out: string, content: string) =
  if out == "": echo content
  else: writeFile(out, content)


var p = newParser("example number 2, commands only")

# NOTE: p.addCommand(name, subcommands=@[], desc=name)
p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  .addCommand("remove", @[newCommand("task", @[newFlag("-n", "--no-log", "does not log the deletion")], "removes a task"), newCommand("project", @[], "removes a project")], "")
  .addCommand("list", @[], "listing everything")
  .addFlag("-o", "--output", "outputs the content to a file", true)

let args = p.parse()
let out = (if args["-o"].registered: args["-o"].content else: "")

if args["add"].registered:
  if args["task"].registered:
    outputTo(out, "Adding task", args["add"]["task"].content)
  else:
    outputTo(out, "Adding project", args["add"]["project"].content)
elif args["remove"].registered:
  if not args["task"]["-n"]:
    if args["task"].registered:
      outputTo(out, "Removing task", args["remove"]["task"].content)
    else:
      outputTo(out, "Removing project", args["remove"]["project"].content)
else:
  outputTo(out, "Listing everything")
