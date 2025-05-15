#import
#  std/[
#    unittest,
#    strformat
#  ],
#
#  nclap
#
#import macros
#
## Define the macro
#macro createParserMacro(parserDef: untyped): untyped =
#  # Extract the parser name
#  let parserName = parserDef[0]
#  let parserBody = parserDef[1]
#
#  # Start building the result
#  result = newNimNode(nnkVar)
#  result.addIdent("p")
#  result.add(newNimNode(nnkCall).addIdent("newParser").add(parserName))
#
#  # Process the body of the parser definition
#  for item in parserBody:
#    if item.kind == nnkCall:
#      # Handle flags
#      if item[0].kind == nnkIdent and item[0].ident == "flag":
#        let flagArgs = item[1..^1] # Get the arguments for the flag
#        result.add(newNimNode(nnkCall).addIdent("addFlag").add(flagArgs))
#      # Handle commands
#      elif item[0].kind == nnkIdent and item[0].ident == "command":
#        let commandName = item[1]
#        let commandBody = item[2]
#        let subcommands = newNimNode(nnkArray) # Create an array for subcommands
#
#        for subItem in commandBody:
#          if subItem.kind == nnkCall:
#            if subItem[0].kind == nnkIdent and subItem[0].ident == "command":
#              let subCommandName = subItem[1]
#              let descArg = subItem[2].getDesc() # Get the description
#              subcommands.add(newNimNode(nnkCall).addIdent("newCommand").add(subCommandName).add(descArg))
#            elif subItem[0].kind == nnkIdent and subItem[0].ident == "flag":
#              let flagArgs = subItem[1..^1] # Get the arguments for the flag
#              subcommands.add(newNimNode(nnkCall).addIdent("newFlag").add(flagArgs))
#
#        # Add the command to the parser
#        result.add(newNimNode(nnkCall).addIdent("addCommand").add(commandName).add(newNimNode(nnkKeyValue).addIdent("subcommands").add(subcommands)))
#
#  # Return the constructed parser
#  result
#
## Example usage of the macro
#createParser("small todo app"):
#  flag("-v", "--verbose", desc="shows debug information")
#  flag("-n", "--no-log", desc="does not show log")
#
#  command("add"):
#    command("project", desc="adds project")
#    command("task", desc="adds task")
#    flag("-u", "--update", desc="update the content/name if the task/project already existed")
#
#  command("remove"):
#    command("project", desc="removes project")
#    command("task", desc="removes task")
#    flag("-f", "--force", desc="does not show error if task/project did not existed")
#
#  command("list"):
#    command("all")
#
#
#
#test "new parser macro":
#  #var p = newParser(
#  #  "customizing help message",
#  #  DEFAULT_SHOWHELP_SETTINGS,
#  #  DEFAULT_ENFORCE_SHORT,
#  #  false,
#  #  true
#  #):
#
#  #var p = newParserTemplate(
#  #  "helpful help message",
#  #  DEFAULT_SHOWHELP_SETTINGS,
#  #  DEFAULT_ENFORCE_SHORT,
#  #  false,
#  #  true
#  #):
#  var p = newParserTemplate("helpful help message"):
#    flag("-n", "--no-log")
#
#    command("add"):
#      command("project")
#      command("task")
#
#    command("remove"):
#      flag("-t", "--trash")
#      command("project")
#      command("task")
#
#    command("list"):
#      command("all")
#
#  let args = p.parse(@["--no-log", "remove", "--trash", "task", "task27"])
#  echo args
