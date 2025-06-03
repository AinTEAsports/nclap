import
  nclap,
  testutils

test "customizing help message":
  let settings: HelpSettings = (
    tabstring: "│   ",
    prefix_pretab: "-> ",
    prefix_posttab_first: "├─ ",
    prefix_posttab: "├─ ",
    prefix_posttab_last: "├─ ",
    surround_left_required: "{",
    surround_right_required: "}",
    surround_left_optional: "{",
    surround_right_optional: "}",
    separator: ", ",
  )
  var p = newParser("customizing help message", settings)

  initParser(p):
    Flag("-h", "--help", "shows this message")

    Command("add"):
      Command("task", "adds a task")
      Command("project", "adds a project")

    Command("remove"):
      Command("project", "removes a project")
      Command("task", "removes a project"):
        Flag("-n", "--no-log", "does not log the deletion")

    Command("list"):
      Flag("-a", "--all", "lists all tasks, even the hidden ones")

    Flag("-o", "--output", "outputs the content to a file", holds_value=true)
    Flag("-d", description="directory in which to do stuff")

  #p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  #  .addCommand("remove", @[newCommand("task", @[newFlag("-n", "--no-log", "does not log the deletion")], "removes a task"), newCommand("project", @[], "removes a project")], "")
  #  .addCommand("list", @[newFlag("-a", "--all", "show even hidden tasks/projects")], "listing tasks and projects")
  #  .addFlag("-o", "--output", "outputs the content to a file", true)
  #  .addFlag("-d", "-d", "directory in which to do stuff")

  p.showHelp()

  #let args = p.parse()
  #echo args
