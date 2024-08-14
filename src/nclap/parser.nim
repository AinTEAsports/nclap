import std/[
  os,
  sugar,
  strformat,
  strutils,
  sequtils,
  tables,
  options
]

import arguments
import cliargs

const
  INVALID_ARGUMENT_EXIT_CODE = 1
  MISSING_COMMAND_EXIT_CODE = 2
  MISSING_REQUIRED_FLAGS_EXIT_CODE = 3

type
  Parser* = object
    arguments: seq[Argument]
    helpmsg: string


proc newParser*(help_message: string = ""): Parser =
  Parser(
    arguments: @[],
    helpmsg: help_message
  )


func addArgument*(parser: var Parser, argument: Argument): var Parser {.discardable.} =
  (parser.arguments.add(argument); parser)


func addCommand*(
  parser: var Parser,
  name: string,
  subcommands: seq[Argument] = @[],
  description: string = name
): var Parser {.discardable.} = parser.addArgument(newCommand(name, subcommands, description))


func addFlag*(
  parser: var Parser,
  short: string,
  long: string = short,
  description: string = long,
  holds_value: bool = HOLDS_VALUE_DEFAULT,
  required: bool = REQUIRED_DEFAULT
): var Parser {.discardable.} = parser.addArgument(newFlag(short, long, description, holds_value, required))


func `$`*(parser: Parser): string =
  &"Parser(arguments: {parser.arguments}, helpmsg: \"{parser.helpmsg}\")"


proc showHelp*(parser: Parser, exit_code: int = 0) =
  echo parser.helpmsg

  for arg in parser.arguments:
    echo helpToString(arg)

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



# NOTE: argv_rest = parser.parseFlags(res, argv, depth, valid_arguments)
proc parseFlags(
  parser: Parser,
  res: var CLIArgs,
  argv: seq[string],
  depth: int,
  valid_arguments: Option[seq[Argument]]
): int =
  # NOTE: parses every flags, updates `res` in consequence and returns the index at which the flag parsing
  # ended, basically indicating where the command is

  let valid_arguments = valid_arguments.get(parser.arguments)
  var depth = depth

  while depth < len(argv) and argv[depth].startsWith('-'):
    let
      current_argv = argv[depth]
      current_flag = valid_arguments.getFlag(current_argv)

    var
      name = current_argv
      content = ""

    if current_flag.holds_value:
      if current_argv.contains('='):
        let splt = current_argv.split('=', maxsplit=1)

        name = splt[0]
        content = splt[1]
      else:
        depth += 1
        content = argv[depth]

    res[current_flag.short] = CLIArg(
      content: (
        if content == "": none[string]()
        else: some[string](content)
      ),
      registered: true,
      subarguments: initTable[string, CLIArg]()
    )
    res[current_flag.long] = res[current_flag.short]

    depth += 1

  depth


# NOTE: when debug finished, put this as func and not proc
func fillCLIArgs(arguments: seq[Argument], depth: int = 0): CLIArgs =
  var res = initTable[string, CLIArg]()

  for argument in arguments:
    case argument.kind:
      of Command:
        if not res.hasKey(argument.name):
          res[argument.name] = CLIArg(
            content: none[string](),
            registered: false,
            subarguments: fillCLIArgs(argument.subcommands, depth+1)
          )

      of Flag:
        if not res.hasKey(argument.short) or not res.hasKey(argument.long):
          res[argument.short] = CLIArg(content: none[string](), registered: false, subarguments: initTable[string, CLIArg]())
          res[argument.long] = res[argument.short]

  res


proc parseArgs(parser: Parser, argv: seq[string], start: int = 0, valid_arguments: Option[seq[Argument]]): (CLIArgs, seq[string]) =
  if len(argv) == 0 or start >= len(argv):
    return (initTable[string, CLIArg](), @[])

  var
    valid_arguments = valid_arguments.get(parser.arguments)  # NOTE: get the value, or if there is none, take `parser.arguments` by default
    res: CLIArgs = fillCLIArgs(valid_arguments)
    depth = start

  # NOTE: fill in all the arguments, with `registered: false` by default
  #for argument in valid_arguments:
  #  fillCLIArgs(argument)


  # NOTE: when valid_arguments is empty we are done
  var current_argv = argv[depth]
  assert current_argv != ""

  if not valid_arguments.isValidArgument(current_argv):
    echo &"[ERROR.parse] Invalid argument: '{current_argv}'"
    quit INVALID_ARGUMENT_EXIT_CODE

  # NOTE: from this point we assert the current argument is valid, it exists
  if current_argv.startsWith('-'):
    let
      #(argv_rest, new_depth) = parser.parseFlags(res, argv, depth, some[seq[Argument]](valid_arguments))
      new_depth = parser.parseFlags(res, argv, depth, some[seq[Argument]](valid_arguments))
      argv_rest = argv[new_depth..^1]
      (next, argv_rest2) = parser.parseArgs(argv, new_depth, some[seq[Argument]](valid_arguments))

    return (concatCLIArgs(res, next), argv_rest)
  else:
    let
      current_command = valid_arguments.getCommand(current_argv)
      (rest, argv_rest) = (
        if len(current_command.subcommands) == 0: (initTable[string, CLIArg](), argv[depth+1..^1])
        elif len(getCommands(current_command.subcommands)) == 0:  # NOTE: maybe `len(getFlags(current_command.subcommands)) > 0` instead if bug ?
          let new_depth = parser.parseFlags(res, argv, depth+1, some[seq[Argument]](current_command.subcommands))
          (res, argv[new_depth..^1])
        else:
          parser.parseArgs(argv, depth+1, some[seq[Argument]](current_command.subcommands))
      )

    res[current_command.name] = CLIArg(
      content: (
        if len(argv_rest) == 0: none[string]()
        else: some[string](argv_rest.join(" "))
      ),
      registered: true,
      subarguments: concatCLIArgs(res[current_command.name].subarguments, rest)
    )

  (res, @[])



proc parse*(parser: Parser, argv: seq[string]): CLIArgs =
  if len(argv) == 0:
    parser.showHelp()

  let (res, _) = parser.parseArgs(argv, 0, none[seq[Argument]]())

  # NOTE: check if at least one principal command has been regsitered, if not then error
  let
    registered_commands = collect(
      for name, cliarg in res:
        if name.startsWith('-'): (false, false)  # NOTE: the second one doesn't matter since we check the second one only if the first one is true
        else: (true, cliarg.registered)
    ).filter(pair => pair[0])

    required_flags = collect(
      for name, cliarg in res:
        if not name.startsWith('-'): (false, false)  # NOTE: same as above
        else: (true, parser.arguments.getFlag(name).required)
    ).filter(pair => pair[0])

  if len(registered_commands) > 0 and registered_commands.all(pair => not pair[1]):
    echo &"[ERROR.parse] No command has been registered"
    parser.showHelp(MISSING_COMMAND_EXIT_CODE)

  if len(required_flags) > 0 and required_flags.all(pair => not pair[1]):
    # TODO: show which flags haven't been registered
    echo &"[ERROR.parse] some flags haven't been registered even though required"
    parser.showHelp(MISSING_REQUIRED_FLAGS_EXIT_CODE)

  res

proc parse*(parser: Parser): CLIArgs =
  parser.parse collect(for i in 1..paramCount(): paramStr(i))
