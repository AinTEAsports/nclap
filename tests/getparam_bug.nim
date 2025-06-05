import
  nclap,
  testutils

test "example 1":
  var parser = newParser("nimtodotui: a simple todo app in the cli") # showhelp_settings)

  initParser(parser):
    Flag("-h", "--help", "shows help")

    Command("add"):
      Flag("-k", "--hidden", "adds task as hidden")
      UnnamedArgument("name", "name of the task to add")

    Command("remove"):
      UnnamedArgument("name", "name of the task to remove")

    Command("list"):
      Command("all", "lists all tasks, even the hidden ones", required=false)

  let args = parser.parse(@["add", "task name"])


  check not ?(args.help)
  check not ?(args@remove)
  check not ?(args@list)

  check !(args@add).name == "task name"
