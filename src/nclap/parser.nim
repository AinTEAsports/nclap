import std/[
  os,
  sugar,
  strformat,
  strutils,
  sequtils,
  tables,
  macros,
  options
]

import arguments
import cliargs
import utils

const
  INVALID_ARGUMENT_EXIT_CODE* = 1
  MISSING_COMMAND_EXIT_CODE* = 2
  MISSING_REQUIRED_FLAGS_EXIT_CODE* = 3
  DEFAULT_ENFORCE_SHORT* = false
  NO_COLORS* = false
  EXIT_ON_ERROR* = true


type
  Parser* = object
    arguments: seq[Argument]
    enforce_short: bool
    helpmsg: string
    help_settings: HelpSettings
    no_colors: bool
    exit_on_error: bool


template error_exit(does_exit, error_type, error_message, exit_code, no_colors: typed): untyped =
  if does_exit:
    echo error("ERROR." & $error_type, error_message, no_colors)
    quit exit_code
  else:
    raise newException(error_type, error_message)


func newParser*(
  help_message: string = "",
  settings: HelpSettings = DEFAULT_SHOWHELP_SETTINGS,
  enforce_short: bool = DEFAULT_ENFORCE_SHORT,
  no_colors: bool = NO_COLORS,
  exit_on_error: bool = EXIT_ON_ERROR
): Parser =
  Parser(
    arguments: @[],
    enforce_short: enforce_short,
    helpmsg: help_message,
    help_settings: settings,
    no_colors: no_colors,
    exit_on_error: exit_on_error
  )


proc addArgument*(parser: var Parser, argument: Argument): var Parser {.discardable.} =
  if parser.enforce_short:
    case argument.kind:
      of Flag:
        # NOTE: 1 for the "-" and 1 for the character, 1+1=2 (I'm a genius I know)
        # NOTE: more seriously, this is enforcing one char length short flags
        if len(argument.short) != 2:
          error_exit(
            parser.exit_on_error,
            FieldDefect,
            &"[ERROR.invalid-argument] `parser.enforce_short` is true, but the short flag is more than 1 character: {argument.short}",
            INVALID_ARGUMENT_EXIT_CODE,
            parser.no_colors
          )
        else: parser.arguments.add(argument)
      of Command:
        parser.arguments.add(argument)
      of UnnamedArgument:
        parser.arguments.add(argument)
  else: parser.arguments.add(argument)

  parser


proc addCommand*(
  parser: var Parser,
  name: string,
  subcommands: seq[Argument] = @[],
  description: string = name,
  required: bool = COMMAND_REQUIRED_DEFAULT,
  #has_content: bool = HOLDS_VALUE_DEFAULT,
  default: Option[string] = none[string]()
): var Parser {.discardable.} =
  if name.startsWith('-'):
    error_exit(
      parser.exit_on_error,
      FieldDefect,
      &"A command cannot start with a '-': {name}",
      INVALID_ARGUMENT_EXIT_CODE,
      parser.no_colors
    )

  parser.addArgument(newCommand(name, subcommands, description, required, default))


proc addFlag*(
  parser: var Parser,
  short: string,
  long: string = short,
  description: string = long,
  holds_value: bool = FLAG_HOLDS_VALUE_DEFAULT,
  required: bool = FLAG_REQUIRED_DEFAULT,
  default: Option[string] = none[string]()
): var Parser {.discardable.} =
  # NOTE: this is a design choice, long flags can start with only a dash,
  # since if no long flag is given, the long flag will just be the short flag
  if not (short.startsWith('-') and long.startsWith('-')):
    error_exit(
      parser.exit_on_error,
      FieldDefect,
      &"A flag must start with a '-': {short}|{long}",
      INVALID_ARGUMENT_EXIT_CODE,
      parser.no_colors
    )

  parser.addArgument(newFlag(short, long, description, holds_value, required, default))


proc addUnnamedArgument*(
  parser: var Parser,
  name: string,
  description: string = name,
  default: Option[string] = none[string]()
): var Parser {.discardable.} =
  # NOTE: this is a design choice, long flags can start with only a dash,
  # since if no long flag is given, the long flag will just be the short flag
  parser.addArgument(newUnnamedArgument(name, description, default))


func `$`*(parser: Parser): string =
  &"Parser(arguments: {parser.arguments}, helpmsg: \"{parser.helpmsg}\")"


proc showHelp*(
  parser: Parser,
  exit_code: int = 0,
) =
  ##[ Shows an auto-generated help message and exits the program with code `exit_code` if `parser.exit_on_error` is set
  ]##

  echo parser.helpmsg

  for arg in parser.arguments:
    echo helpToString(arg, parser.help_settings)

  if parser.exit_on_error:
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
      of UnnamedArgument:
        if argument.ua_name == argument_name:
          return true

  false


func getArgumentType(arguments: seq[Argument], argument_name: string): Option[ArgumentType] =
  let argname = (if argument_name.contains('='): argument_name.split('=')[0] else: argument_name)

  for argument in arguments:
    case argument.kind:
      of Command:
        if argument.name == argname:
          return some[ArgumentType](Command)
      of Flag:
        if argument.long == argname or argument.short == argname:
          return some[ArgumentType](Flag)
      of UnnamedArgument:
        if argument.ua_name == argument_name:
          return some[ArgumentType](UnnamedArgument)

  none[ArgumentType]()


proc getCommand(arguments: seq[Argument], argument_name: string, parser: Parser): Argument =
  for argument in arguments.getCommands():
    if argument.name == argument_name:
      return argument

  # NOTE: should be impossible since we check before calling this function
  error_exit(
    parser.exit_on_error,
    FieldDefect,
    &"Invalid command: '{argument_name}'",
    INVALID_ARGUMENT_EXIT_CODE,
    parser.no_colors
  )


proc getUnnamedArgument(arguments: seq[Argument], argument_name: string, parser: Parser): Argument =
  for argument in arguments.getUnnamedArguments():
    if argument.ua_name == argument_name:
      return argument

  # NOTE: should be impossible since we check before calling this function
  error_exit(
    parser.exit_on_error,
    FieldDefect,
    &"Invalid flag: '{argument_name}'",
    INVALID_ARGUMENT_EXIT_CODE,
    parser.no_colors
  )


func head[T](s: openArray[T]): Option[T] =
  if s.len == 0:
    return none[T]()

  some[T](s[0])


proc getFirstUnregisteredUnnamedArgument(arguments: seq[Argument], cliargs: CLIArgs, parser: Parser): Option[Argument] =
  let first_name_o = collect(
    for name, cliarg in cliargs:
      if not cliarg.registered and name.startsWith(UNNAMED_ARGUMENT_PREFIX):
        name
  ).head()

  if first_name_o.isNone:
    return none[Argument]()

  let name_with_prefix = first_name_o.get()

  return some[Argument](
    arguments.getUnnamedArgument(
      name_with_prefix[(UNNAMED_ARGUMENT_PREFIX.len)..^1],  # NOTE: we remove the UNNAMED_ARGUMENT_PREFIX
      parser
    )
  )



proc getFlag(arguments: seq[Argument], argument_name: string, parser: Parser): Argument =
  let argname = (if argument_name.contains('='): argument_name.split('=')[0] else: argument_name)

  for argument in arguments.getFlags():
    if argument.short == argname or argument.long == argname:
      return argument

  # NOTE: should be impossible since we check before calling this function
  error_exit(
    parser.exit_on_error,
    FieldDefect,
    &"Invalid flag: '{argument_name}'",
    INVALID_ARGUMENT_EXIT_CODE,
    parser.no_colors
  )


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
      current_flag = valid_arguments.getFlag(current_argv, parser)

    var
      name = current_argv
      content = ""

    if current_flag.holds_value:
      if current_argv.contains('='):
        let splt = current_argv.split('=', maxsplit=1)

        name = splt[0]
        content = (if len(splt) == 2: splt[1] else: "")  # NOTE: in case the user does `./program --output=`
      else:
        depth += 1

        if depth >= len(argv):
          # NOTE: I had a choice: either throw error or quit, I was too lazy to handle the error in `parseArgs` where `parseFlags` is called (but both are equivalent
          # even though handling the error in `parseArgs` is way better since this function should not quit unexpectedly)

          error_exit(
            parser.exit_on_error,
            ValueError,
            &"Expected a value after the flag '{current_argv}'",
            INVALID_ARGUMENT_EXIT_CODE,
            parser.no_colors
          )

        content = argv[depth]

    res[current_flag.short] = CLIArg(
      content: (
        if content == "": none[string]()
        else: some[string](content)
      ),
      registered: true,
      default: current_flag.default,
      subarguments: initOrderedTable[string, CLIArg]()
    )
    res[current_flag.long] = res[current_flag.short]

    depth += 1

  depth


func fillCLIArgs(arguments: seq[Argument], depth: int = 0): CLIArgs =
  var res = initOrderedTable[string, CLIArg]()

  for argument in arguments:
    case argument.kind:
      of Command:
        if not res.hasKey(argument.name):
          res[argument.name] = CLIArg(
            content: none[string](),
            registered: false,
            default: argument.default,
            subarguments: fillCLIArgs(argument.subcommands, depth+1)
          )

      of Flag:
        if not res.hasKey(argument.short) or not res.hasKey(argument.long):
          res[argument.short] = CLIArg(content: none[string](), registered: false, subarguments: initOrderedTable[string, CLIArg](), default: argument.default)
          res[argument.long] = res[argument.short]

      of UnnamedArgument:
        res[UNNAMED_ARGUMENT_PREFIX & argument.ua_name] = CLIArg(content: none[string](), registered: false, subarguments: initOrderedTable[string, CLIArg](), default: argument.default)

  res


proc parseArgs(parser: Parser, argv: seq[string], start: int = 0, valid_arguments: Option[seq[Argument]]): (CLIArgs, seq[string]) =
  if len(argv) == 0 or start >= len(argv):
    return (initOrderedTable[string, CLIArg](), @[])

  var
    valid_arguments = valid_arguments.get(parser.arguments)  # NOTE: get the value, or if there is none, take `parser.arguments` by default
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

  assert current_argv != ""

  # DEBUG: commented this
  # TODO: implement a count of unknown flags and it has to match the number of unnamed arguments otherwise error
  #if not valid_arguments.isValidArgument(current_argv):
  #  error_exit(
  #    parser.exit_on_error,
  #    ValueError,
  #    &"Invalid argument: '{current_argv}'",
  #    INVALID_ARGUMENT_EXIT_CODE,
  #    parser.no_colors
  #  )

  # NOTE: from this point we assert the current argument is valid, it exists
  if current_argv.startsWith('-'):
    let
      #(argv_rest, new_depth) = parser.parseFlags(res, argv, depth, some[seq[Argument]](valid_arguments))
      new_depth = parser.parseFlags(res, argv, depth, some[seq[Argument]](valid_arguments))
      argv_rest = argv[new_depth..^1]
      (next, argv_rest2) = parser.parseArgs(argv, new_depth, some[seq[Argument]](valid_arguments))

    # NOTE: This works, but if bugs (duplicates more precisely) try to put `argv_rest2` instead of `argv_rest`
    return (concatCLIArgs(res, next), argv_rest)
  else:
    if (
      let otype: Option[Argument] = valid_arguments.getFirstUnregisteredUnnamedArgument(res, parser)
      otype.isSome
    ):

      let
        o_current_ua = otype
        current_ua: Argument = (
          if o_current_ua.isNone:  # FIXME: useless since we check it in the if
            error_exit(
              parser.exit_on_error,
              ValueError,
              "Invalid supplementary unnamed argument",
              INVALID_ARGUMENT_EXIT_CODE,
              parser.no_colors
            )
          else: o_current_ua.get()
        )

      res[UNNAMED_ARGUMENT_PREFIX & current_ua.ua_name] = CLIArg(
        content: some[string](current_argv),
        registered: true,
        default: current_ua.default,
        subarguments: initOrderedTable[string, CLIArg]()
      )

      let (rest, argv_rest) = parser.parseArgs(argv[depth+1..^1], valid_arguments=some[seq[Argument]](valid_arguments))

      return (concatCLIArgs(res, rest), argv_rest)

    else:
      let
        current_command = valid_arguments.getCommand(current_argv, parser)
        (rest, argv_rest) = (
          if len(current_command.subcommands) == 0: (initOrderedTable[string, CLIArg](), argv[depth+1..^1])
          elif len(getCommands(current_command.subcommands)) == 0:  # NOTE: maybe `len(getFlags(current_command.subcommands)) > 0` instead if bug ?
            var res_subargs = res[current_command.name].subarguments
            let new_depth = parser.parseFlags(res_subargs, argv, depth+1, some[seq[Argument]](current_command.subcommands))

            res[current_command.name] = CLIArg(
              content: none[string](),
              registered: true,
              default: current_command.default,
              subarguments: res_subargs
            )

            (res_subargs, argv[new_depth..^1])
          else:
            parser.parseArgs(argv, depth+1, some[seq[Argument]](current_command.subcommands))
        )
        #content = (
        #  if len(argv_rest) == 0: none[string]()
        #  else: some[string](argv_rest.join(" "))
        #)
        #content = none[string]()

      #if not current_command.holds_value and content.isSome:
      #  error_exit(
      #    parser.exit_on_error,
      #    ValueError,
      #    &"command '{current_command.name}' should not have any content, yet it got '{content.get()}'",
      #    INVALID_ARGUMENT_EXIT_CODE,
      #    parser.no_colors
      #  )

      #if current_command.holds_value and (content.isNone or (content.isSome and content.get() == "")):
      #  error_exit(
      #    parser.exit_on_error,
      #    ValueError,
      #    &"command '{current_command.name}' should have some content, yet it didn't",
      #    INVALID_ARGUMENT_EXIT_CODE,
      #    parser.no_colors
      #  )

      res[current_command.name] = CLIArg(
        content: none[string](),
        registered: true,
        default: current_command.default,
        subarguments: concatCLIArgs(res[current_command.name].subarguments, rest)
      )

  (res, @[])


func first[T](s: seq[T]): Option[T] =
  if len(s) == 0: none[T]()
  else: some[T](s[0])


func checkForMissingCommand(
  valid_arguments: seq[Argument],
  cliargs: CLIArgs,
  prev_command: Argument
): (seq[Argument], Option[Argument]) =
  let
    commands = valid_arguments.getCommands()
    required_and_registered = commands
      .filter(cmd => cmd.required and cliargs[cmd.name].registered)

  # NOTE: either no command registered or one since at most one command
  # can be registered per level
  assert len(required_and_registered) <= 1

  if len(required_and_registered) == 1:
    let cmd = required_and_registered[0]

    checkForMissingCommand(
      cmd.subcommands,
      cliargs[cmd.name].subarguments,
      cmd
    )
  else:
    (
      commands
        .filter(cmd => cmd.required and not cliargs[cmd.name].registered)
        .filter(cmd => cmd.required and not cliargs[cmd.name].default.isSome),
      some[Argument](prev_command)
    )

  

func checkForMissingFlags(
  valid_arguments: seq[Argument],
  cliargs: CLIArgs,
  prev_flag: Argument
): (seq[Argument], Option[Argument]) =
  if len(cliargs) == 0:
    return (@[], none[Argument]())

  let required_but_unregistered_flags = valid_arguments
    .getFlags()
    .filter(arg => (
        let
          is_required = arg.required
          is_registered = cliargs[arg.long].registered
          has_fallback_value = cliargs[arg.long].default.isSome

        is_required and not is_registered and not has_fallback_value
      )
    )

  if len(required_but_unregistered_flags) > 0: (required_but_unregistered_flags, some[Argument](prev_flag))
  else:
    # NOTE: there should be (normally) only one at once, and it should exist
    # since we check for missing required commands before checking for missing
    # required flags
    let registered_command = valid_arguments
      .getCommands()
      .filter(arg => arg.required and cliargs[arg.name].registered)
      .first()

    if registered_command.isNone: (@[], none[Argument]())
    else:
      checkForMissingFlags(
        registered_command.get().subcommands,
        cliargs[registered_command.get().name].subarguments,
        registered_command.get()
      )
      


proc parse*(parser: Parser, argv: seq[string]): CLIArgs =
  if len(argv) == 0:
    parser.showHelp()

  let
    argv = (if parser.enforce_short: expandArgvShortFlags(argv) else: argv)
    (res, _) = parser.parseArgs(argv, 0, none[seq[Argument]]())


  # NOTE: this is for partial help message
  let (missing_commands, parent_command) = checkForMissingCommand(parser.arguments, res, newCommand(""))

  # NOTE: which means a command or subcommand is missing (one of the commands/subcommands had subcommands and none of them were registered)
  if len(missing_commands) > 0:
    # NOTE: which means no commands were registered at all
    if parent_command.get().name == "":
      parser.showHelp(exit_code=MISSING_COMMAND_EXIT_CODE)
    else:
      if parser.exit_on_error:
        echo parser.helpmsg
        echo parent_command.get().helpToString(settings=parser.help_settings)
        quit(MISSING_COMMAND_EXIT_CODE)
      else: raise newException(ValueError, "Missing a command to continue parsing")


  # NOTE: this is to check if every required flags has been registered
  let (missing_required_flags, _) = checkForMissingFlags(parser.arguments, res, newCommand(""))

  if len(missing_required_flags) > 0:
    if parser.exit_on_error:
      echo error(
        "ERROR.parse",
        "Missing one of: " & join(missing_required_flags.map(arg => &"\"{arg.long}\""), " | "),
        no_colors=parser.no_colors
      )
      quit(MISSING_REQUIRED_FLAGS_EXIT_CODE)
    else: raise newException(ValueError, "Missing required flags")

  res


proc parse*(parser: Parser): CLIArgs =
  parser.parse collect(for i in 1..paramCount(): paramStr(i))
