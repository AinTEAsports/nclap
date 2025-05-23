#import
#  std/[
#    macros,
#    options,
#    unittest,
#  ],
#
#  nclap/parser
#
#
#test "newParser macro":
#  #var p = newParser("unnamed arg example"):
#  #  flag("-n", "--no-log", "does not log the removal", required=false, holds_value=false)
#  #
#  #  command("add"):
#  #    command("project"):
#  #      discard
#  #
#  #  command("task"):
#  #    flag("-T", description="priority of task", default=some("medium"))
#  #
#  #  command("remove"):
#  #    flag("-f", description="force delete")
#  #
#  #let args = p.parse(@["add", "task", "-T", "8"])
#  #
#  #echo args
#
#
#
#
#  var p = newParserMacro("unnamed arg example", quote do:
#    flag("-n", "--no-log", "does not log the removal", required=false, holds_value=false)
#
#    command("add"):
#      command("project"):
#        discard
#
#    command("task"):
#      flag("-T", description="priority of task", default=some("medium"))
#
#    command("remove"):
#      flag("-f", description="force delete")
#  )
#
#  echo p
#  #let args = p.parse(@["add", "task", "-T", "8"])
#
#  #echo args
#
#  #dumpTree:
#  #  newParser("unnamed arg example", quote do:
#  #    flag("-n", "--no-log", "does not log the removal", required=false, holds_value=false)
#  #
#  #    command("add"):
#  #      command("project"):
#  #        discard
#  #
#  #    command("task"):
#  #      flag("-T", description="priority of task", default=some("medium"))
#  #
#  #    command("remove"):
#  #      flag("-f", description="force delete")
#  #  )
