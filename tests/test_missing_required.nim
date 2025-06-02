import
  nclap,
  testutils


test "missing required":
  var parser = newParser("nimtodotui: a simple todo app in the cli")

  initParser(parser):
    #Flag("-r", "--required", "is required", required=true)
    #UnnamedArgument("name", "name of the task to add")

    Flag("-h", "--help", "shows help")

    Command("add"):
      Flag("-k", "--hidden", "adds task as hidden")
      UnnamedArgument("name", "name of the task to add")

    Command("remove"):
      UnnamedArgument("name", "name of the task to remove")

    Command("list"):
      Command("all", "lists all tasks, even the hidden ones", required=false)

  let args = parser.parse(@["add", "name here"])

  check ?(args@add)
  check !((args@add).name) == "name here"
