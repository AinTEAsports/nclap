import
  std/options,

  nclap,
  testutils


test "example 3":
  var p = newParser("example number 2, commands only")

  initParser(p):
    Flag("-l", "--log-file", "file to log the adds/removes in", holds_value=true, default=some("/dev/null"))

    Command("add", "adds a task"):
      Flag("-a", "--alias", "alias of the task", holds_value=true)
      UnnamedArgument("name", "name of the task to add")

    Command("remove", "removes a task"):
      Flag("-n", "--no-resolve-alias", "do not resolve the alias")
      UnnamedArgument("name", "name of the task to remove")

    Command("list", "lists tasks"):
      Command("all", "lists all tasks, even the hidden ones")


  let args = p.parse(@["--log-file=a_log_file", "remove", "-n", "test_task_name"])

  check !args.log_file == "a_log_file"
  check ?(args@remove)

  check ?((args@remove).no_resolve_alias)

  check !((args@remove).name) == "test_task_name"
