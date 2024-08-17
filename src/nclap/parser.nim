import std/[os, sugar, strformat, strutils, sequtils, tables, options]
import nclap/[arguments, cliargs, utils]

const
  INVALID_ARGUMENT_EXIT_CODE* = 1
  MISSING_COMMAND_EXIT_CODE* = 2
  MISSING_REQUIRED_FLAGS_EXIT_CODE* = 3
  DEFAULT_ENFORCE_SHORT* = false

type
  ParseError* = object of CatchableError
    ## An error from which all errors that occur during parsing stem from

  InvalidArgument* = object of ParseError
  InvalidCommand* = object of ParseError
  InvalidFlag* = object of ParseError

  Parser* = object
    arguments: seq[Argument]
    enforce_short: bool
    helpmsg: string
    help_settings: HelpSettings

func newParser*(
    help_message: string = newString(0),
    settings: HelpSettings = HelpSettings(),
    enforce_short: bool = false,
): Parser {.inline.} =
  Parser(
    arguments: @[],
    enforce_short: enforce_short,
    helpmsg: help_message,
    help_settings: settings,
  )

func addArgument*(parser: var Parser, argument: Argument): var Parser {.discardable.} =
  if parser.enforce_short:
    case argument.kind
    of Flag:
      # NOTE: 1 for the "-" and 1 for the character, 1+1=2 (I'm a genius I know)
      if len(argument.short) != 2:
        raise newException(
          InvalidArgument,
          &"`parser.enforce_short` is true, but the short flag is more than 1 character: {argument.short}",
        )
      else:
        parser.arguments.add(argument)
    of Command:
      parser.arguments.add(argument)
  else:
    parser.arguments.add(argument)

  parser

func addCommand*(
    parser: var Parser,
    name: string,
    subcommands: seq[Argument] = @[],
    description: string = name,
    required: bool = true,
): var Parser {.discardable, inline.} =
  if name.startsWith('-'):
    raise newException(InvalidArgument, &"A command cannot start with a '-': {name}")

  parser.addArgument(newCommand(name, subcommands, description, required))

func addFlag*(
    parser: var Parser,
    short: string,
    long: string = short,
    description: string = long,
    holds_value: bool = false,
    required: bool = false,
): var Parser {.discardable.} =
  # NOTE: this is a design choice, long flags can start with only a dash,
  # since if no long flag is given, the long flag will just be the short flag
  if not (short.startsWith('-') and long.startsWith('-')):
    raise newException(InvalidArgument, &"A flag must start with a '-': {short}|{long}")

  parser.addArgument(newFlag(short, long, description, holds_value, required))

func `$`*(parser: Parser): string {.inline.} =
  &"Parser(arguments: {parser.arguments}, helpmsg: \"{parser.helpmsg}\")"

proc showHelp*(parser: Parser, exit_code: int = 0) {.inline.} =
  echo parser.helpmsg

  for arg in parser.arguments:
    echo helpToString(arg, parser.help_settings)

  quit(exit_code)

func getCommands(parser: Parser): seq[Argument] {.inline.} =
  parser.arguments.filter(arg => arg.kind == Command)

func getFlags(parser: Parser): seq[Argument] {.inline.} =
  parser.arguments.filter(arg => arg.kind == Flag)

func getCommand(arguments: seq[Argument], argument_name: string): Argument =
  for argument in arguments.getCommands():
    if argument.name == argument_name:
      return argument

  # NOTE: should be impossible since we check before calling this function
  raise newException(InvalidCommand, &"Invalid command: {argument_name}")

func getFlag(arguments: seq[Argument], argument_name: string): Argument =
  let argname =
    (if argument_name.contains('='): argument_name.split('=')[0]
    else: argument_name)

  for argument in arguments.getFlags():
    if argument.short == argname or argument.long == argname:
      return argument

  # NOTE: should be impossible since we check before calling this function
  raise newException(InvalidFlag, &"Invalid flag: {argument_name}")

func isValidArgument(arguments: seq[Argument], argument_name: string): bool =
  let argname =
    if argument_name.contains('='):
      argument_name.split('=')[0]
    else:
      argument_name

  for argument in arguments:
    case argument.kind
    of Command:
      return argument.name == argname
    of Flag:
      return argument.long == argname or argument.short == argname

  false

# NOTE: argv_rest = parser.parseFlags(res, argv, depth, valid_arguments)
proc parseFlags(
    parser: Parser,
    res: var CLIArgs,
    argv: seq[string],
    depth: int,
    valid_arguments: Option[seq[Argument]],
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
      content: string

    if current_flag.holds_value:
      if current_argv.contains('='):
        let splt = current_argv.split('=', maxsplit = 1)

        name = splt[0]
        content = (if len(splt) == 2: splt[1] else: "")
          # NOTE: in case the user does `./program --output=`
      else:
        depth += 1

        if depth >= len(argv):
          # NOTE: I had a choice: either throw error or quit, I was too lazy to handle the error in `parseArgs` where `parseFlags` is called (but both are equivalent
          # even though handling the error in `parseArgs` is way better since this function should not quit unexpectedly)
          raise
            newException(ParseError, &"Expected a value after the flag: {current_argv}")

        content = argv[depth]

    res[current_flag.short] = CLIArg(
      content: (
        if content.len < 1:
          none[string]()
        else:
          some[string](content)
      ),
      registered: true,
      subarguments: initTable[string, CLIArg](),
    )
    res[current_flag.long] = res[current_flag.short]

    depth += 1

  depth

func fillCLIArgs(arguments: seq[Argument], depth: int = 0): CLIArgs =
  var res = initTable[string, CLIArg]()

  for argument in arguments:
    case argument.kind
    of Command:
      if not res.hasKey(argument.name):
        res[argument.name] = CLIArg(
          content: none[string](),
          registered: false,
          subarguments: fillCLIArgs(argument.subcommands, depth + 1),
        )
    of Flag:
      if not res.hasKey(argument.short) or not res.hasKey(argument.long):
        res[argument.short] = CLIArg(
          content: none[string](),
          registered: false,
          subarguments: initTable[string, CLIArg](),
        )
        res[argument.long] = res[argument.short]

  res

proc parseArgs(
    parser: Parser,
    argv: seq[string],
    start: int = 0,
    valid_arguments: Option[seq[Argument]],
): (CLIArgs, seq[string]) =
  if len(argv) == 0 or start >= len(argv):
    return (initTable[string, CLIArg](), @[])

  var
    valid_arguments = valid_arguments.get(parser.arguments)
      # NOTE: get the value, or if there is none, take `parser.arguments` by default
    res: CLIArgs = fillCLIArgs(valid_arguments)
    depth = start

  # NOTE: fill in all the arguments, with `registered: false` by default
  #for argument in valid_arguments:
  #  fillCLIArgs(argument)

  # NOTE: when valid_arguments is empty we are done
  var current_argv = argv[depth]

  # NOTE: skip while current argv is empty string
  while depth < len(argv) and current_argv == "":
    current_argv = argv[depth]
    depth += 1

  # NOTE: then no more arguments, everything was empty
  if current_argv == "":
    return (res, @[])

  assert current_argv.len > 0

  if not valid_arguments.isValidArgument(current_argv):
    raise newException(ParseError, &"Invalid argument: {current_argv}")

  # NOTE: from this point we assert the current argument is valid, it exists
  if current_argv.startsWith('-'):
    let
      #(argv_rest, new_depth) = parser.parseFlags(res, argv, depth, some[seq[Argument]](valid_arguments))
      new_depth =
        parser.parseFlags(res, argv, depth, some[seq[Argument]](valid_arguments))
      argv_rest = argv[new_depth ..^ 1]
      (next, argv_rest2) =
        parser.parseArgs(argv, new_depth, some[seq[Argument]](valid_arguments))

    # NOTE: This works, but if bugs (duplicates more precisely) try to put `argv_rest2` instead of `argv_rest`
    return (concatCLIArgs(res, next), argv_rest)
  else:
    let
      current_command = valid_arguments.getCommand(current_argv)
      (rest, argv_rest) = (
        if len(current_command.subcommands) == 0:
        (initTable[string, CLIArg](), argv[depth + 1 ..^ 1])
        elif len(getCommands(current_command.subcommands)) == 0:
          # NOTE: maybe `len(getFlags(current_command.subcommands)) > 0` instead if bug ?
          var res_subargs = res[current_command.name].subarguments
          let new_depth = parser.parseFlags(
            res_subargs,
            argv,
            depth + 1,
            some[seq[Argument]](current_command.subcommands),
          )

          res[current_command.name] =
            CLIArg(content: none[string](), registered: true, subarguments: res_subargs)

          (res_subargs, argv[new_depth ..^ 1])
        else:
          parser.parseArgs(
            argv, depth + 1, some[seq[Argument]](current_command.subcommands)
          )
      )

    res[current_command.name] = CLIArg(
      content: (
        if len(argv_rest) == 0:
          none[string]()
        else:
          some[string](argv_rest.join(" "))
      ),
      registered: true,
      subarguments: concatCLIArgs(res[current_command.name].subarguments, rest),
    )

  (res, @[])

func first[T](s: seq[T]): Option[T] =
  if len(s) == 0:
    none[T]()
  else:
    some[T](s[0])

func checkForMissingCommand(
    valid_arguments: seq[Argument], cliargs: CLIArgs, prev_command: Argument
): (seq[Argument], Option[Argument]) =
  let
    commands = valid_arguments.getCommands()
    required_and_registered =
      commands.filter(cmd => cmd.command_required and cliargs[cmd.name].registered)

  # NOTE: either no command registered or one since at most one command
  # can be registered per level
  assert len(required_and_registered) <= 1

  if len(required_and_registered) == 1:
    let cmd = required_and_registered[0]

    checkForMissingCommand(cmd.subcommands, cliargs[cmd.name].subarguments, cmd)
  else:
    (
      commands.filter(cmd => cmd.command_required and not cliargs[cmd.name].registered),
      some[Argument](prev_command),
    )

func checkForMissingFlags(
    valid_arguments: seq[Argument], cliargs: CLIArgs, prev_flag: Argument
): (seq[Argument], Option[Argument]) =
  if len(cliargs) == 0:
    return (@[], none[Argument]())

  let required_but_unregistered_flags = valid_arguments.getFlags().filter(
      arg => arg.flag_required and not cliargs[arg.long].registered
    )

  if len(required_but_unregistered_flags) > 0:
    (required_but_unregistered_flags, some[Argument](prev_flag))
  else:
    # NOTE: there should be (normally) only one at once, and it should exist
    # since we check for missing required commands before checking for missing
    # required flags
    let registered_command = valid_arguments
      .getCommands()
      .filter(arg => arg.command_required and cliargs[arg.name].registered)
      .first()

    if registered_command.isNone:
      (@[], none[Argument]())
    else:
      checkForMissingFlags(
        registered_command.get().subcommands,
        cliargs[registered_command.get().name].subarguments,
        registered_command.get(),
      )

proc parse*(parser: Parser, argv: seq[string]): CLIArgs =
  if len(argv) == 0:
    parser.showHelp()

  let
    argv = (if parser.enforce_short: expandArgvShortFlags(argv)
    else: argv)
    (res, _) = parser.parseArgs(argv, 0, none[seq[Argument]]())

  # NOTE: this is for partial help message
  let (missing_commands, parent_command) =
    checkForMissingCommand(parser.arguments, res, newCommand(""))

  # NOTE: which means a command or subcommand is missing (one of the commands/subcommands had subcommands and none of them were registered)
  if len(missing_commands) > 0:
    # NOTE: which means no commands were registered at all
    if parent_command.get().name == "":
      parser.showHelp(exit_code = MISSING_COMMAND_EXIT_CODE)
    else:
      echo parser.helpmsg
      echo parent_command.get().helpToString(settings = parser.help_settings)
      quit(MISSING_COMMAND_EXIT_CODE)

  # NOTE: this is to check if every required flags has been registered
  let (missing_required_flags, _) =
    checkForMissingFlags(parser.arguments, res, newCommand(""))

  if len(missing_required_flags) > 0:
    echo &"[ERROR.parse] Missing one of: " &
      join(missing_required_flags.map(arg => &"\"{arg.long}\""), " | ")
    quit(MISSING_REQUIRED_FLAGS_EXIT_CODE)

  res

proc parse*(parser: Parser): CLIArgs =
  parser.parse collect(
    for i in 1 .. paramCount():
      paramStr(i)
  )
