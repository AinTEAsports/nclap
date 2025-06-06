import
  std/options,

  nclap,
  testutils


test "missing required":
  const TODO_FILENAME = "/tmp/test.log"

  var parser = newParser("nimtodotui: a simple todo app in the cli")

  initParser(parser):
    Flag("-h", "--help", "shows help")
    Flag("-f", "--task-file", "specify the task file used", default=some(TODO_FILENAME))

    Command("add"):
      UnnamedArgument("name", "name of the task to add")
      UnnamedArgument("task-content", "content of the task to add")
      Flag("-k", "--hidden", "adds task as hidden")

    Command("remove"):
      UnnamedArgument("name", "name of the task to remove")

    Command("list"):
      Command("all", "lists all tasks, even the hidden ones", required=false)


  let args = parser.parse(@["add", "name here", "content here"])

  check ?(args@add)
  check !((args@add).name) == "name here"

  check !((args@add).task_content) == "content here"
