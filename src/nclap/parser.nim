import std/[
  os,
  sugar,
  strformat,
  strutils,
  sequtils,
  tables,
  sugar,
  options
]

import arguments
import cliargs

const
  INVALID_ARGUMENT_EXIT_CODE = 1
  MISSING_COMMAND_EXIT_CODE = 2

type
  Parser* = object
    arguments: seq[Argument]
    helpmsg: string


proc newParser*(help_message: string = ""): Parser =
  Parser(
    arguments: @[],
    helpmsg: help_message
  )


func addArgument*(parser: var Parser, argument: Argument): var Parser =
  (parser.arguments.add(argument); parser)


func addCommand*(
  parser: var Parser,
  name: string,
  subcommands: seq[Argument] = @[],
  description: string = name
): var Parser = parser.addArgument(newCommand(name, subcommands, description))


func addFlag*(
  parser: var Parser,
  short: string,
  long: string = short,
  holds_value: bool = HOLDS_VALUE_DEFAULT,
  description: string = long
): var Parser = parser.addArgument(newFlag(short, long, holds_value, description))


func `$`*(parser: Parser): string =
  &"Parser(arguments: {parser.arguments}, helpmsg: \"{parser.helpmsg}\")"


proc showHelp*(parser: Parser, exit_code: int = 0) =
  echo "\n" & parser.helpmsg
  quit(exit_code)


func getCommands(parser: Parser): seq[Argument] =
  parser.arguments.filter(arg => arg.kind == Command)


func getFlags(parser: Parser): seq[Argument] =
  parser.arguments.filter(arg => arg.kind == Flag)


func isValidArgument(arguments: seq[Argument], argument_name: string): bool =
  let argname = (if argument_name.contains('='): argument_name.split('=')[0] else: argument_name)

  for argument in arguments:
    case argument.kind:
      of Command:
        if argument.name == argname:
          return true
      of Flag:
        if argument.long == argname or argument.short == argname:
          return true

  false


func getCommand(arguments: seq[Argument], argument_name: string): Argument =
  for argument in arguments.getCommands():
    if argument.name == argument_name:
      return argument

  # NOTE: should be impossible since we check before calling this function
  raise newException(ValueError, &"Invalid command: {argument_name}")


func getFlag(arguments: seq[Argument], argument_name: string): Argument =
  let argname = (if argument_name.contains('='): argument_name.split('=')[0] else: argument_name)

  for argument in arguments.getFlags():
    if argument.short == argname or argument.long == argname:
      return argument

  # NOTE: should be impossible since we check before calling this function
  raise newException(ValueError, &"Invalid flag: {argument_name}")


proc parseArgs(parser: Parser, argv: seq[string], start: int = 0, valid_arguments: Option[seq[Argument]]): CLIArgs =
  if len(argv) == 0 or start >= len(argv):
    return initTable[string, CLIArg]()

  var
    res: CLIArgs = initTable[string, CLIArg]()
    valid_arguments = valid_arguments.get(parser.arguments)  # NOTE: get the value, or if there is none, take `parser.arguments` by default
    depth = start

  # NOTE: fill in all the arguments, with `registered: false` by default
  for argument in valid_arguments:
    let name = (case argument.kind:
      of Command: argument.name
      of Flag: argument.long
    )

    res[name] = CLIArg(content: "", registered: false, subarguments: initTable[string, CLIArg]())


  # NOTE: when valid_arguments is empty we are done
  let current_argv = argv[depth]
  assert current_argv != ""

  if not valid_arguments.isValidArgument(current_argv):
    echo &"[ERROR.parse] Invalid argument: '{current_argv}'"
    quit INVALID_ARGUMENT_EXIT_CODE

  # NOTE: from this point we assert the current argument is valid, it exists

  # NOTE: then it is a flag
  if current_argv.startsWith('-'):
    let current_flag = valid_arguments.getFlag(current_argv)

    if current_flag.holds_value:
      # TODO: make the parsing
      var
        content = ""
        name = current_argv

      if current_argv.contains('='):
        let splt = current_argv.split('=', maxsplit=1)

        name = splt[0]
        content = splt[1]
      else:
        depth += 1
        content = argv[depth]

      res[current_flag.long] = CLIArg(content: content, registered: true, subarguments: initTable[string, CLIArg]())
      # WARNING: I ADDED THIS
      depth += 1
      

    else: res[current_flag.long] = CLIArg(content: "", registered: true, subarguments: initTable[string, CLIArg]())  # NOTE: no subarguments because it is a flag
  # NOTE: then it is a command
  else:
    let
      current_command = valid_arguments.getCommand(current_argv)
      rest = parser.parseArgs(argv, depth+1, some[seq[Argument]](current_command.subcommands))

    res[current_command.name] = CLIArg(content: "", registered: true, subarguments: rest)

  res



proc parse*(parser: Parser, argv: seq[string]): CLIArgs =
  if len(argv) == 0:
    parser.showHelp()

  let res = parser.parseArgs(argv, 0, none[seq[Argument]]())

  # NOTE: check if at least one principal command has been regsitered, if not then error
  if collect(for name, cliarg in res:
    if name.startsWith('-'): (false, false)  # NOTE: the second one doesn't matter since we check the second one only if the first one is true
    else: (true, cliarg.registered))
  .filter(pair => pair[0])
  .all(pair => not pair[1]):
    echo &"[ERROR.parse] No command has been registered"
    parser.showHelp(MISSING_COMMAND_EXIT_CODE)

  res

proc parse*(parser: Parser): CLIArgs =
  parser.parse collect(for i in 1..<paramCount(): paramStr(i))