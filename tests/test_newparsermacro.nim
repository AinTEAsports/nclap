import
  std/options,

  nclap,
  testutils


test "initParser macro":
  var parser = newParser("makeParser macro test, todo list app")

  initParser(parser):
    Flag("-h", "--help", "shows help message")

    Command("add", "adds a task"):
      UnnamedArgument("name", "name of task to add")
      Flag("-k", "--alias", "alias of task", holds_value=true, default=some("default_alias"))

    Command("remove", "removes a task"):
      UnnamedArgument("name", "name of task to remove")
      Flag("-n", "--no-log", "do not log the removal")
      Flag("-j", "--no-resolve-alias", "do not resolve the alias", false, false)

    Command("list"):
      Command("all", "lists all tasks, even the hidden ones")

  #parser
  #  .addFlag("-h", "--help", "shows help message")
  #  .addCommand("add", @[
  #    newUnnamedArgument("name", "name of the task to add"),
  #    newFlag("-k", "--alias", "alias of task", holds_value=true, default=some("default_alias"))
  #  ], "adds a task")
  #  .addCommand("remove", @[
  #    newUnnamedArgument("name", "name of the task to remove"),
  #    newFlag("-n", "--no-log", "do not log the removal"),
  #    newFlag("-j", "--no-resolve-alias", "do not resolve the alias", false, false)
  #  ], "removes a task")
  #  .addCommand("list", @[
  #    newCommand("all", @[], "lists all tasks, even the hidden ones")
  #  ], "lists tasks")

  let args = parser.parse(@["add", "task 1 ig"])

  check ?(args@add)
  check not ?((args@add).alias)
  check !((args@add).name) == "task 1 ig"
