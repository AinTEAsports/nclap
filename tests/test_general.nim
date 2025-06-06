# This is just an example to get you started. You may wish to put all of your tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import
  std/options,

  fusion/matching,

  nclap,
  testutils

#test "newArgument":
#  echo "[DEBUG.TEST.newArgument] START"
#  echo newFlag("-o", "--output", "output to a file", true)
#  echo newCommand("add", @[], "adds a task to the todo list")
#  echo newCommand("remove", @[newFlag("-n", "--no-log", "Does not log the deletion")], "adds a task to the todo list")
#  echo "[DEBUG.TEST.newArgument] END"
#
#test "newParser":
#  echo "[DEBUG.TEST.newParser] START"
#
#  var parser = newParser("new parser test")
#
#  echo parser
#    .addCommand("add", @[], "add a new command")
#    .addCommand("remove", @[newFlag("-n", "--no-log", "Does not log the deletion")], "add a new command")
#
#  echo "[DEBUG.TEST.newParser] END"


#test "command parser test":
#  var parser = newParser("[HELPDESC] parser test for the win")
#
#  discard parser
#    .addCommand("add", @[newCommand("task", @[], "adds a new task"), newCommand("project", @[], "adds a new project")], "add a new")
#    .addCommand("remove", @[newFlag("-n", "--no-log", "Does not log the deletion", false)], "remove a command")
#    .addCommand("list", @[newFlag("-a", "--all", "show all tasks", false)], "list tasks")
#    .addFlag("-o", "--output", "outputs to a file", true)
#
#  #echo tostring(parser.parse(@["list", "-a"]))     # Should run
#  #echo tostring(parser.parse(@["-o=/tmp/test"]))   # Should not run, saying no command has been registered
#  #echo tostring(parser.parse(@["add", "task"]))    # Should run
#  #echo tostring(parser.parse(@[]))                 # Should show help message
#
#  let args = parser.parse(@["add", "task", "pokemon", "-o", "test"])
#  echo &"[DEBUG.command test parser] args: {args}"
#  echo &"[DEBUG.command test parser] args[\"add\"][\"task\"]: " & $args["add"]["task"]


#test "flag parser test":
#  var p = newParser("Example number one")
#
#  discard p
#    .addFlag("-h", "--help", "shows this help message")
#    .addFlag("-a", "--all", "shows all files")
#    .addFlag("-l", "--long", "shows additional information")
#    .addFlag("-o", "--output", "output to a file", true, true)
#
#  # By default, will take `argv`
#  let args = p.parse(@["-a", "--long", "--output=test"])
#  echo args
#
#  # NOTE: you can use either the short or long flag to access the value
#  if args["--help"].registered:
#      p.showHelp()
#
#  if args["-a"].registered:
#      echo "Showing all files"
#
#  if args["-l"].registered:
#      echo "Showing additional information"
#
#  if args["--output"].registered:
#      echo "Redirecting content to " & args["--output"].getContent(default="")


#test "example1":
#  var p = newParser("example number 1, flags only")
#
#  # NOTE: p.addFlag(short, long, description=long, holds_value=false, required=false)
#  p.addFlag("-h", "--help", "shows this help message", false)
#    .addFlag("-vv", "--verbose", "shows additional informations", false)
#    .addFlag("-o", "--output", "outputs to a file", true, true)
#
#  let args = p.parse(@["-o=test"])
#
#  # you can access the flag value with the short or the long version
#  if args["--help"].registered:
#    p.showHelp(exit_code=0)
#
#  if args["-vv"].registered:
#    echo "Showing additional information"
#
#  echo "Output goes to: " & args["--output"].getContent(error=true)


#test "example2":
#  var p = newParser("example number 2, commands only")
#
#  # NOTE: p.addCommand(name, subcommands=@[], desc=name)
#  p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
#    .addCommand("remove", @[newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
#    .addCommand("list", @[], "lists everything")
#
#  let args = p.parse()
#
#  if args["add"].registered:
#    if args["task"].registered:
#      echo "Adding task", args["add"]["task"].getContent()
#    else:
#      echo "Adding project", args["add"]["project"].getContent()
#  elif args["remove"].registered:
#    if args["task"].registered:
#      echo "Removing task", args["remove"]["task"].getContent()
#    else:
#      echo "Removing project", args["remove"]["project"].getContent()
#  else:
#    echo "Listing everything"


#test "example3":
#  proc outputTo(output: string, content: string) =
#    if output == "": echo content
#    else: writeFile(output, content)
#
#
#  var p = newParser("example number 2, commands only")
#
#  # NOTE: p.addCommand(name, subcommands=@[], desc=name)
#  p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
#    .addCommand("remove", @[newFlag("-n", "--no-log", "does not log the deletion"), newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
#    .addCommand("list", @[], "listing everything")
#    .addFlag("-o", "--output", "outputs the content to a file", true)
#
#  let args = p.parse()
#  let output = (if args["-o"].registered: args["-o"].getContent(error=true) else: "")
#
#  if args["add"].registered:
#    if args["task"].registered:
#      outputTo(output, "Adding task" & args["add"]["task"].getContent())
#    else:
#      outputTo(output, "Adding project" & args["add"]["project"].getContent())
#  elif args["remove"].registered:
#    if not args["remove"]["-n"].registered:
#      if args["task"].registered:
#        outputTo(output, "Removing task" & args["remove"]["task"].getContent())
#      else:
#        outputTo(output, "Removing project" & args["remove"]["project"].getContent())
#  else:
#    outputTo(output, "Listing everything")



#test "new parser version":
#  var p = newParser("new parser test")
#
#  p.addCommand("add",
#    @[
#      newFlag("-a", "--all", "adds all"),
#      newFlag("-n", "--no-log", "no log"),
#      newCommand(
#        "task",
#        @[newFlag("-a", "--all", "adds all tasks")],
#        "adds a task"
#      )
#    ],
#    "adds something"
#  )
#
#  echo p.parse(@["add", "-n", "task", "--all"])


#test "last arg content":
#  var p = newParser("simple todo app")
#
#  p.addCommand("add", @[newFlag("-n", "--no-log", "does not log the addition"), newFlag("-c", "--hidden", "adds the command as hidden")], "adds a task")
#    .addCommand("list", @[newCommand("all", @[], "lists all tasks, even hidden ones")], "lists tasks")
#    .addCommand("remove", @[newFlag("-n", "--no-log", "does not log the deletion")], "removes a task")
#
#
#  let args = p.parse(@["add", "-n", "-c", "yeah", "babe"])
#
#  echo args


#test "generated help message":
#  var p = newParser("simple todo app")
#
#  p.addCommand("add", @[newFlag("-n", "--no-log", "does not log the addition"), newFlag("-c", "--hidden", "adds the command as hidden")], "adds a task")
#    .addCommand("list", @[newCommand("all", @[], "lists all tasks, even hidden ones")], "lists tasks")
#    .addCommand("remove", @[newFlag("-n", "--no-log", "does not log the deletion")], "removes a task")
#
#
#  let args = p.parse()
#
#  echo args


#test "another":
#  var p = newParser("simple todo app")
#
#  p.addCommand("add", @[
#      newFlag("-n", "--no-log", "does not log the addition"),
#      newFlag("-c", "--hidden", "adds the command as hidden"),
#      newCommand("task", @[newFlag("-t", "--temp", "temporary add")], "adds a task"),
#      newCommand("project", @[newFlag("-t", "--temp", "temporary add")], "adds a project"),
#    ],
#    "adds something"
#  )
#    .addCommand("list", @[newCommand("all", @[], "lists all tasks, even hidden ones")], "lists tasks")
#    .addCommand("remove", @[newFlag("-n", "--no-log", "does not log the deletion")], "removes a task")
#
#
#  let args = p.parse(@["add", "-n", "task", "-t", "kaboom ?", "-t"])
#
#  echo args


#test "last":
#  var p = newParser("simple todo app")
#
#  p.addCommand("add", @[
#      newFlag("-n", "--no-log", "does not log the addition"),
#      newFlag("-c", "--hidden", "adds the command as hidden"),
#      newCommand("task", @[], "adds a task"),
#      newCommand("project", @[newFlag("-t", "--temp", "temporary add")], "adds a project")
#    ],
#    "adds something"
#  )
#    .addCommand("list", @[newCommand("all", @[], "lists all tasks, even hidden ones", required=false)], "lists tasks")
#    .addCommand("remove", @[newFlag("-n", "--no-log", "does not log the deletion")], "removes a task")
#    .addFlag("-o", "--output", "outputs to a file", true, true)
#
#
#  #let args = p.parse(@["add", "-c", "task", "task1"])
#  #let args = p.parse(@["add", "-c", "project", "project1", "-t"])
#  #let args = p.parse(@["list"])
#  #let args = p.parse(@["list", "all"])
#  #let args = p.parse(@["remove", "-n", "test"])
#  #let args = p.parse(@["--output=yeah", "list"])
#  let args = p.parse(@["-o=yeah", "add", "task"])
#  echo args
#
#  echo "Output goes to: " & args["-o"].getContent(error=true)
#  if args["list"].registered:
#    echo "Listing ", (if args["list"]["all"].registered: "" else: "almost "), "everything"
#
#  if args["add"].registered:
#    # NOTE: if `-n` given, then no log
#    if not args["add"]["-n"].registered:
#      if args["add"]["task"].registered: echo "Adding task ", args["add"]["task"].getContent(), (if args["add"]["-c"].registered: " as hidden" else: "")
#      else: echo "Adding project ", args["add"]["project"].getContent(), (if args["add"]["-c"].registered: " as hidden" else: "")
#
#  if args["remove"].registered:
#    if not args["remove"]["-n"].registered: echo "Removing ", args["remove"].getContent()


test "compact shortflags":
#task "test", "compact shortflags":
  var p = newParser("compact shortflags test", enforce_short=true)

  p.addFlag("-a", "--all", "all ?")
    .addFlag("-b", "--boolean", "show boolean format ? what are those flags dude")
    .addFlag("-c", "--check", "check what bro ? your capacity to write tests ?")
    .addFlag("-o", "--output", "finally a normal flag", holds_value=true, required=true)

  let args = p.parse(@["-abco=yeah"])

  check ?args.all
  check ?args.boolean
  check ?args.c
  check !args.output == "yeah"


#test "subcommands content":
#  var p = newParser("customizing help message", DEFAULT_SHOWHELP_SETTINGS, DEFAULT_ENFORCE_SHORT, false, true)
#
#  p.addCommand("add", @[newCommand("task", @[], "adds a task", true, true), newCommand("project", @[], "adds a project", true, true)], "")
#    .addCommand("remove", @[newCommand("task", @[newFlag("-n", "--no-log", "does not log the deletion")], "removes a task", true, true), newCommand("project", @[], "removes a project", true, true)], "")
#    .addCommand("list", @[newFlag("-a", "--all", "show even hidden tasks/projects")], "listing tasks and projects", true, false)
#    .addFlag("-o", "--output", "outputs the content to a file", true)
#    .addFlag("-d", "-d", "directory in which to do stuff")
#
#  let args = p.parse(@["remove", "task", "--no-log", "yes"])
#
#  echo args
#  #echo args.add
#  #echo args.remove
#  #echo args?output
#  #echo "\n\n\n---\n\n\n"
#  #echo args.remove.task->n
#
#  let output: string = (args.output !! "default output btw")
#  echo "output=" & output


test "default param":
  let default_target = "127.0.0.1"

  var p = newParser("default param", DEFAULT_SHOWHELP_SETTINGS, DEFAULT_ENFORCE_SHORT, false, true)

  p
    .addFlag("-t", "--target", "target ip address", true, true, default=some(default_target))
    .addFlag("-p", "--ports", "ports to scan", true, true, default=some("that"))
    .addFlag("-n", "--no-log", "does not log anything", false, false)
    .addFlag("-o", "--output", "outputs the content to a file", true)

  let args = p.parse(@["-p", "1-10", "-n", "-t=127.0.0.1"])

  check !args.target == default_target


test "dot flag access":
  var p = newParser("dot flag access", DEFAULT_SHOWHELP_SETTINGS, DEFAULT_ENFORCE_SHORT, false, true)

  p
    .addFlag("-t", "--target", "directory in which to do stuff", true, true, default=some("127.0.0.1"))
    .addFlag("-p", "--ports", "ports to scan", true, true, default=some("that"))
    .addFlag("-n", "--no-log", "does not log anything", false, false)
    .addFlag("-o", "--output", "outputs the content to a file", true)

  let args = p.parse(@["-p", "1-10", "-n", "-t", "localhost"])

  check ?args.no_log


test "unnamed arguments":
  var p = newParser("unnamed arguments", DEFAULT_SHOWHELP_SETTINGS, DEFAULT_ENFORCE_SHORT, false, true)

  p
    .addUnnamedArgument("target", default=some("127.0.0.1"))
    .addFlag("-p", "--ports", "ports to scan", true, true, default=some("that"))
    .addFlag("-n", "--no-log", "does not log anything", false, false)
    .addFlag("-o", "--output", "outputs the content to a file", true)

  let args = p.parse(@["-n", "localhost"])

  check !args.target == "localhost"
  check ?args.no_log


test "total":
  let default_target = "127.0.0.1"
  var p = newParser("total", DEFAULT_SHOWHELP_SETTINGS, DEFAULT_ENFORCE_SHORT, false, true)

  p
    .addUnnamedArgument("target", default=some(default_target))
    .addFlag("-p", "--ports", "ports to scan", true, true, default=some("1-65535"))
    .addFlag("-n", "--no-log", "does not log anything", false, false)
    .addFlag("-o", "--output", "outputs the content to a file", true)
    .addFlag("-T", "--aggressivity", "outputs the content to a file", true, true)

  let args = p.parse(@["-n", "-T=5"])

  check not ?args.target
  check !args.target == default_target

  check ?args.no_log
  check ?args.aggressivity

test "example2":

  var p = newParser("example number 2, commands only")

  # NOTE: p.addCommand(name, subcommands=@[], desc=name, required=true)
  p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
    .addCommand("remove", @[newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
    .addCommand("list", @[newCommand("all", @[], "lists everything", required=false)], "lists almost everything")

  let args = p.parse(@["add", "task"])

  let choice = commandMatch:
  of args@add: 1
  of args@remove: 2
  of args@list: 3
  #else: 4

  check choice == 1
