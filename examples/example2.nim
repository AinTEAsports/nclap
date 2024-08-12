import nclap/[
  parser,
  cliargs,
  arguments
]

var p = newParser("example number 2, commands only")

# NOTE: p.addCommand(name, subcommands=@[], desc=name)
p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  .addCommand("remove", @[newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
  .addCommand("list", @[], "lists everything")

let args = p.parse()

if args["add"].registered:
  if args["task"].registered:
    echo "Adding task", args["add"]["task"].content
  else:
    echo "Adding project", args["add"]["project"].content
elif args["remove"].registered:
  if args["task"].registered:
    echo "Removing task", args["remove"]["task"].content
  else:
    echo "Removing project", args["remove"]["project"].content
else:
  echo "Listing everything"

