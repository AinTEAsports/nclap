import
  nclap,
  testutils


test "example 2":
  var p = newParser("example number 2, commands only")

  # NOTE: p.addCommand(name, subcommands=@[], desc=name, required=true)
  p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
    .addCommand("remove", @[newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
    .addCommand("list", @[newCommand("all", @[], "lists everything", required=false)], "lists almost everything")

  let args = p.parse(@["add", "project"])

  check ?(args@add)
  check ?(args@add@project)

  check not ?(args@add@task)
  check not ?(args@remove)
  check not ?(args@list)
