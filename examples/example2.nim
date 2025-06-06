import nclap

var p = newParser("example number 2, commands only")

# NOTE: p.addCommand(name, subcommands=@[], desc=name, required=true)
p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  .addCommand("remove", @[newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
  .addCommand("list", @[newCommand("all", @[], "lists everything", required=false)], "lists almost everything")

let args = p.parse()

if ?(args@add):
  echo "Adding " & (if ?(args@add@task): "task" else: "project")
elif ?(args@remove):
  echo "Removing" & (if ?(args@add@task): "task" else: "project")
elif ?(args@list):
  echo "Listing " & (if not ?(args@list@all): "almost " else: "") & "everything"
else:
  assert false, "this should never reach since all are required"
