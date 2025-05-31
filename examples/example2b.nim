import nclap

var p = newParser("example number 2, commands only")

# NOTE: p.addCommand(name, subcommands=@[], desc=name, required=true)
p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  .addCommand("remove", @[newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
  .addCommand("list", @[newCommand("all", @[], "lists everything", required=false)], "lists almost everything")

let args = p.parse()

commandMatch:
of args@add@project, args@remove@project:
  echo "doing something with a project, either add or remove idk"
of args@list@all:
  echo "listing stuff, everything"
of args@list:
  echo "listing stuff, maybe all"
else:
  echo "this should never happened but this is still valid syntax"
