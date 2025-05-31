import
  std/options,

  nclap,
  testutils


test "example 3":
  var p = newParser("example number 2, commands only")

  p
    .addFlag("-l", "--log-file", "file to log the adds/removes in", holds_value=true, default=some("/dev/null"))
    .addCommand("add", @[
      newFlag("-a", "--alias", "alias of the task", holds_value=true),
      newUnnamedArgument("name", "name of the task to add"),
    ], "adds a task")
    .addCommand("remove", @[
      newFlag("-n", "--no-resolve-alias", "do not resolve the alias"),
      newUnnamedArgument("name", "name of the task to remove"),
    ], "removes a task")
    .addCommand("list", @[
      newCommand("all", @[], "lists all tasks")
    ], "lists tasks, even the hidden ones")

  let args = p.parse(@["--log-file=a_log_file", "remove", "-n", "test_task_name"])

  check !args.log_file == "a_log_file"
  check ?(args@remove)

  check ?((args@remove).no_resolve_alias)

  check !((args@remove).name) == "test_task_name"
