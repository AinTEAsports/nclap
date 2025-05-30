import
  std/[
    options,
    macros
  ],

  nclap,
  testutils


test "initParser macro":
  var parser = newParser("makeParser macro test, todo list app")

  initParser(parser):
    Flag("-h", "--help", "shows help message")

    Command("add", "adds a task"):
      UnnamedArgument("name", "name of task to add")
      Flag("-k", "--alias", "alias of task", holds_value=true, default=some[string](""))
      #Flag("-k", "--alias", "alias of task", false, true)

    Command("remove", "removes a task"):
      UnnamedArgument("name", "name of task to remove")
      Flag("-n", "--no-log", "do not log the removal")
      Flag("-j", "--no-resolve-alias", "do not resolve the alias", false, false)

    Command("list"):
      Command("all", "lists all tasks, even the hidden ones")


  let args = parser.parse(@["add", "task number 1"])

  echo args

  #check ?(args@add)
  #check not ?((args@add).alias)
  #check !((args@add).name) == ""
