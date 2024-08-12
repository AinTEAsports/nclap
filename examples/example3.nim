import nclap/[
  parser,
  cliargs,
  arguments
]

proc outputTo(output: string, content: string) =
  if output == "": echo content
  else: writeFile(output, content)


var p = newParser("example number 2, commands only")

# NOTE: p.addCommand(name, subcommands=@[], desc=name)
p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  .addCommand("remove", @[newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
  .addCommand("list", @[newFlag("-a", "--all", "lists all tasks, even hidden ones")], "listing everything")
  .addFlag("-o", "--output", "outputs the content to a file", true)

let args = p.parse()
let output = (if args["-o"].registered: args["-o"].content else: "")

if args["add"].registered:
  if args["task"].registered:
    outputTo(output, "Adding task" & args["add"]["task"].content)
  else:
    outputTo(output, "Adding project" & args["add"]["project"].content)
elif args["remove"].registered:
  if args["task"].registered:
    outputTo(output, "Removing task" & args["remove"]["task"].content)
  else:
    outputTo(output, "Removing project" & args["remove"]["project"].content)
else:
  if args["task"]["-a"].registered:
    outputTo(output, "Listing everything, even hidden ones")
  else:
    outputTo(output, "Listing almost everything (not hidden ones, they're hidden for a reason)")

