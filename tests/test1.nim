# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import nclap
import nclap/parser
import nclap/arguments
import nclap/cliargs

#test "newArgument":
#  echo "[DEBUG.TEST.newArgument] START"
#  echo newFlag("-o", "--output", true, "output to a file")
#  echo newCommand("add", @[], "adds a task to the todo list")
#  echo newCommand("remove", @[newFlag("-n", "--no-log", false, "Does not log the deletion")], "adds a task to the todo list")
#  echo "[DEBUG.TEST.newArgument] END"
#
#test "newParser":
#  echo "[DEBUG.TEST.newParser] START"
#
#  var parser = newParser("new parser test")
#
#  echo parser
#    .addCommand("add", @[], "add a new command")
#    .addCommand("remove", @[newFlag("-n", "--no-log", false, "Does not log the deletion")], "add a new command")
#
#  echo "[DEBUG.TEST.newParser] END"


test "parser test":
  var parser = newParser("[HELPDESC] parser test for the win")

  discard parser
    .addCommand("add", @[newCommand("task", @[], "adds a new task"), newCommand("project", @[], "adds a new project")], "add a new")
    .addCommand("remove", @[newFlag("-n", "--no-log", false, "Does not log the deletion")], "remove a command")
    .addCommand("list", @[newFlag("-a", "--all", false, "show all tasks")], "list tasks")
    .addFlag("-o", "--output", true, "outputs to a file")

  #echo tostring(parser.parse(@["list", "-a"]))     # Should run
  #echo tostring(parser.parse(@["-o=/tmp/test"]))   # Should not run, saying no command has been registered
  #echo tostring(parser.parse(@["add", "task"]))    # Should run
  #echo tostring(parser.parse(@[]))                 # Should show help message
