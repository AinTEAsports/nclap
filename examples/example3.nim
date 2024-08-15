import nclap/[
  parser,
  cliargs,
  arguments
]

proc outputTo(output: string, content: string) =
  if output == "": echo content
  else: writeFile(output, content)


var p = newParser("example number 2, commands only")

p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  .addCommand("remove", @[newFlag("-n", "--no-log", "does not log the deletion"), newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
  .addCommand("list", @[], "listing everything")
  .addFlag("-o", "--output", "outputs the content to a file", true)

let args = p.parse()
let output = (if args["-o"].registered: args["-o"].getContent(error=true) else: "")

if args["add"].registered:
  if args["task"].registered:
    outputTo(output, "Adding task" & args["add"]["task"].getContent())
  else:
    outputTo(output, "Adding project" & args["add"]["project"].getContent())
elif args["remove"].registered:
  if not args["remove"]["-n"].registered:
    if args["task"].registered:
      outputTo(output, "Removing task" & args["remove"]["task"].getContent())
    else:
      outputTo(output, "Removing project" & args["remove"]["project"].getContent())
else:
  outputTo(output, "Listing everything")
