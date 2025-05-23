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
  has_content: bool = HOLDS_VALUE_DEFAULT,
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

  let required_subcommands = subcommands.getCommands().filter(cmd => cmd.required)

  if len(required_subcommands) != 0 and has_content:
    error_exit(
      parser.exit_on_error,
      FieldDefect,
      &"A command cannot expect a content and have required subcommands (command: '{name}')",
      INVALID_ARGUMENT_EXIT_CODE,
      parser.no_colors
    )

  parser.addArgument(newCommand(name, subcommands, description, required, has_content, default))


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


#proc getFirstUnregisteredUnnamedArgument(arguments: seq[Argument], cliargs: CLIArgs, parser: Parser): Option[Argument] =
#  #let tmp: seq[string] = collect(
#  #  for name, cliarg in cliargs:
#  #    if not cliarg.registered and name.startsWith(UNNAMED_ARGUMENT_PREFIX):
#  #      name
#  #)
#
#  var tmp: seq[string] = @[]
#
#  for name, cliarg in cliargs:
#    if not cliarg.registered and name.startsWith(UNNAMED_ARGUMENT_PREFIX):
#      tmp.add(name)
#      echo &"[DEBUG] {name}"
#
#  #echo &"[DEBUG] {tmp}"
#
#  let o_first_unregistered_ua_name: Option[string] = tmp.head()
#  echo &"[DEBUG] {o_first_unregistered_ua_name}"
#
#  #echo &"[DEBUG.getFirstUnregisteredUnnamedArgument {o_first_unregistered_ua_name.isSome}]"
#  #echo &"[DEBUG.getFirstUnregisteredUnnamedArgument" & o_first_unregistered_ua_name.get()
#
#  if o_first_unregistered_ua_name.isNone:
#    return none[Argument]()
#
#  let name: string = o_first_unregistered_ua_name.get()
#
#  return some[Argument](
#    arguments.getUnnamedArgument(
#      #o_first_unregistered_ua_name.get()[(UNNAMED_ARGUMENT_PREFIX.len)..^1],  # NOTE: we remove the UNNAMED_ARGUMENT_PREFIX
#      name[(UNNAMED_ARGUMENT_PREFIX.len)..^1],  # NOTE: we remove the UNNAMED_ARGUMENT_PREFIX
#      parser
#    )
#  )


proc getFirstUnregisteredUnnamedArgument(arguments: seq[Argument], cliargs: CLIArgs, parser: Parser): Option[Argument] =
  var tmp: seq[string] = @[]

  #for name, cliarg in cliargs:
  for name in cliargs.keys():
    let arg = cliargs[name]

    if not arg.registered and name.startsWith(UNNAMED_ARGUMENT_PREFIX):
      tmp.add(name)
      echo "[DEBUG.for.tmp.add] name=" & name

  echo "[DEBUG] END OF FOR LOOP=" & $tmp.len
  echo "[DEBUG] END OF FOR LOOP=" & tmp[0]
  echo "[DEBUG] END OF FOR LOOP=" & $tmp[0].len

  #let name: string = (
  #  if tmp.len == 0: return none[Argument]()
  #  else: tmp[0]
  #)

  if tmp.len == 0:
    return none[Argument]()

  #echo "[DEBUG] name_NOPREF=" & name[(UNNAMED_ARGUMENT_PREFIX.len)..^1]
  var name_without_prefix = ""
  for i in (UNNAMED_ARGUMENT_PREFIX.len) ..< tmp[0].len:
  #for i in 1 ..< name.len:
    echo name_without_prefix
    #echo name[i]
    name_without_prefix &= tmp[0][i]

  return some[Argument](
    arguments.getUnnamedArgument(
      #name[(UNNAMED_ARGUMENT_PREFIX.len)..^1],  # NOTE: we remove the UNNAMED_ARGUMENT_PREFIX
      name_without_prefix,
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
          let content = (
            if argument.holds_value: some[string]("")
            else: none[string]()
          )

          res[argument.name] = CLIArg(
            content: content,
            registered: false,
            #default: none[string](),
            default: argument.default,
            subarguments: fillCLIArgs(argument.subcommands, depth+1)
          )

      of Flag:
        if not res.hasKey(argument.short) or not res.hasKey(argument.long):
          #res[argument.short] = CLIArg(content: none[string](), registered: false, default: none[string](), subarguments: initOrderedTable[string, CLIArg]())
          res[argument.short] = CLIArg(content: none[string](), registered: false, subarguments: initOrderedTable[string, CLIArg](), default: argument.default)
          res[argument.long] = res[argument.short]

      of UnnamedArgument:
        res[UNNAMED_ARGUMENT_PREFIX & argument.ua_name] = CLIArg(content: none[string](), registered: false, subarguments: initOrderedTable[string, CLIArg](), default: argument.default)
        #raise Defect.newException("not implemented")

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
    # TODO: insert here, check if is unnamed arg + DON'T FORGET RECURSION
    #if (let otype = valid_arguments.getArgumentType(current_argv); otype.isSome and otype.get() == UnnamedArgument):
    if (
      let otype: Option[Argument] = valid_arguments.getFirstUnregisteredUnnamedArgument(res, parser)
      otype.isSome
    ):

      let
        #o_current_ua: Option[Argument] = valid_arguments.getFirstUnregisteredUnnamedArgument(res, parser)
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

      #echo current_ua.ua_name

      res[UNNAMED_ARGUMENT_PREFIX & current_ua.ua_name] = CLIArg(
        content: some[string](current_argv),
        registered: true,
        default: current_ua.default,
        subarguments: initOrderedTable[string, CLIArg]()
      )

      #return (
      #  res,
      #  argv[depth+1..^1]
      #)

      #let (rest, argv_rest) = (
        #let new_depth = parser.parseFlags(res_subargs, argv, depth+1, some[seq[Argument]](current_command.subcommands))
        #parser.parseArgs(argv[depth+1..^1], valid_arguments )
      #  proc parseArgs(parser: Parser, argv: seq[string], start: int = 0, valid_arguments: Option[seq[Argument]]): (CLIArgs, seq[string]) =
      #)


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
        content = (
          if len(argv_rest) == 0: none[string]()
          else: some[string](argv_rest.join(" "))
        )

      if not current_command.holds_value and content.isSome:
        error_exit(
          parser.exit_on_error,
          ValueError,
          &"command '{current_command.name}' should not have any content, yet it got '{content.get()}'",
          INVALID_ARGUMENT_EXIT_CODE,
          parser.no_colors
        )

      if current_command.holds_value and (content.isNone or (content.isSome and content.get() == "")):
        error_exit(
          parser.exit_on_error,
          ValueError,
          &"command '{current_command.name}' should have some content, yet it didn't",
          INVALID_ARGUMENT_EXIT_CODE,
          parser.no_colors
        )

      res[current_command.name] = CLIArg(
        content: content,
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


## NOTE:
#  # take in a call statement and return a Argument
#  # or take in a list of call statements and return a seq[Argument]
#  # then specify which is the current arg if needed, otherwise create a new one
#macro newParserMacro(parser: var Parser, body: untyped): seq[Argument] =
#  body.expectKind nnkStmtList
#
#  # NOTE: only use this if weird problems
#  #body.expectMinLen 1
#  #body[0].expectKind nnkCall
#
#  for ind in body:
#    ind.expectKind nnkCall
#
#    let indent_name = ind[0].strVal
#
#    case indent_name:
#      of "command":
#        discard
#
#        #let
#        #  name = ind[1].strVal
#        #  description = (if ind.len >= 2: ind[1].strVal else: name)
#        #  required = (if ind.len >= 3: ind[2].boolVal else: COMMAND_REQUIRED_DEFAULT)
#        #  has_content = (if ind.len >= 4: ind[3].boolVal else: HAS_CONTENT_DEFAULT)
#        #
#        #
#        #echo &"{name}, {description}, {required}, {has_content}"
#
#        # NOTE: get the recursive case
#        #if ind[^1].kind == nnkStmtList:
#
#
#      of "flag":
#        discard
#
#        #let
#        #  short = ind[1].strVal
#        #  long = (if ind.len >= 2: ind[1].strVal else: short)
#        #  description = (if ind.len >= 3: ind[2].strVal else: long)
#        #  holds_value = (if ind.len >= 4: ind[3].boolVal else: FLAG_HOLDS_VALUE_DEFAULT)
#        #  required = (if ind.len >= 5: ind[4].boolVal else: FLAG_REQUIRED_DEFAULT)
#
#        #parser_res.addFlag(short, long, description, holds_value, required)
#
#
#      else:
#        raise newException(Defect, &"wrong kind of callIndent: '{indent_name}'")
#
#
#
#  # DEBUG
#  echo body.treeRepr
#
#  #echo body
#
#  parser
#
#
#
#template newParserTemplate*(
#  help_message: string = "",
#  settings: HelpSettings = DEFAULT_SHOWHELP_SETTINGS,
#  enforce_short: bool = DEFAULT_ENFORCE_SHORT,
#  no_colors: bool = NO_COLORS,
#  exit_on_error: bool = EXIT_ON_ERROR,
#  body: untyped
#): Parser =
#  #newParser()
#
#  var res = newParser(
#    help_message,
#    settings,
#    enforce_short,
#    no_colors,
#    exit_on_error
#  )
#
#  res




#macro newParser*(app_description: string, body: untyped): untyped =
#  proc parseBody(body: NimNode): NimNode =
#    result = newStmtList()
#
#    for stmt in body:
#      case stmt.kind:
#        of nnkCall:
#          let head = $stmt[0]
#          case head
#          of "flag":
#            let
#              shortFlag = stmt[1]
#              longFlag = stmt[2]
#
#            var
#              desc = newLit("")
#              required = newLit(false)
#              holds_value = newLit(false)
#              defaultVal: NimNode = nil
#
#            for i in 3 ..< stmt.len:
#              if stmt[i].kind == nnkExprEqExpr:
#                let key = $stmt[i][0]
#                let val = stmt[i][1]
#                case key:
#                  of "description": desc = val
#                  of "required": required = val
#                  of "holds_value": holds_value = val
#                  of "default": defaultVal = val
#                  else: raise Defect.newException(&"unsupported field name: {key}")
#
#            var call = quote do:
#              p.addFlag(`shortFlag`, `longFlag`, `desc`, `required`, `holds_value`)
#            if defaultVal != nil:
#              call = quote do:
#                `call`.setDefault(`defaultVal`)
#            result.add call
#
#          of "unnamed_argument":
#            let name = stmt[1]
#            var desc = newLit("")
#
#            for i in 2 ..< stmt.len:
#              if stmt[i].kind == nnkExprEqExpr and $stmt[i][0] == "description":
#                desc = stmt[i][1]
#
#            result.add quote do:
#              commandArgs.add(newUnnamedArgument(`name`, `desc`))
#
#          of "command":
#            let name = stmt[1]
#            let innerBody = stmt[2]
#            let nested = parseBody(innerBody)
#            result.add quote do:
#              p.addCommand(`name`, block:
#                var commandArgs: seq[Argument] = @[]
#                `nested`
#                commandArgs
#              )
#
#        of nnkStmtList:
#          result.add parseBody(stmt)
#
#        of nnkEmpty, nnkCommentStmt:
#          discard
#
#        else:
#          raise Defect.newException(&"unsupported node kind: {stmt.kind} {stmt=}")
#          #assert false
#          #echo stmt.kind
#
#    return result
#
#  let parsedBody = parseBody(body)
#  result = quote do:
#    var p = newParser(`app_description`)
#    `parsedBody`
#    p


#macro newParser*(appName: string, code_block: untyped): untyped =
#  let parserSym = genSym(nskVar, "parser")
#  result = newStmtList()
#
#  result.add quote do:
#    var `parserSym` = newParser(`appName`)
#
#  proc processBlock(target: NimNode, body: NimNode): seq[NimNode] =
#    var res: seq[NimNode] = @[]
#
#    for stmt in body:
#      case stmt.kind
#      of nnkCall:
#        let head = $stmt[0]
#        case head
#        of "flag":
#          res.add quote do:
#            `target`.addFlag(
#              name = stmt[1],
#              longName = stmt[2],
#              description = stmt[3],
#              required = stmt.getOrDefault(4, quote do: true),
#              holds_value = stmt.getOrDefault(5, quote do: true),
#              default = none(string)
#            )
#
#        of "command":
#          let cmdName = stmt[1]
#          let subBody = if stmt.len >= 3: stmt[2] else: newStmtList()
#          let cmdSym = genSym(nskVar, "cmd")
#
#          res.add quote do:
#            var `cmdSym` = newCommand(`cmdName`)
#
#          let nested = processBlock(cmdSym, subBody)
#          res.add nested
#
#          res.add quote do:
#            `target`.addCommand(`cmdSym`)
#
#        of "unnamed_argument":
#          res.add quote do:
#            `target`.addArgument(
#              newUnnamedArgument(stmt[1], description=stmt.getOrDefault(2, quote do: ""))
#            )
#
#        else:
#          echo "Skipping unknown call: ", head
#
#      of nnkStmtList, nnkDo:
#        res.add processBlock(target, stmt)
#
#      else:
#        echo "Unhandled stmt: ", stmt.kind
#
#    return res
#
#  let generatedStmts = processBlock(parserSym, code_block)
#  for stmt in generatedStmts:
#    result.add stmt
#
#  result.add quote do:
#    `parserSym`




















# Extract string literal from various node types
proc getStringValue(node: NimNode): string =
  case node.kind:
  of nnkStrLit: node.strVal
  of nnkRStrLit: node.strVal
  of nnkTripleStrLit: node.strVal
  else: 
    error("Expected string literal", node)

# Process flag arguments and create the appropriate call
proc processFlagArgs(args: seq[NimNode]): (string, string, string, bool, bool) =
  var short = ""
  var long = ""
  var desc = ""
  var holdsValue = false
  var required = false
  
  # Process positional arguments first
  var argIndex = 0
  for arg in args:
    if arg.kind in {nnkStrLit, nnkRStrLit, nnkTripleStrLit}:
      case argIndex:
      of 0: short = getStringValue(arg)
      of 1: long = getStringValue(arg)
      of 2: desc = getStringValue(arg)
      else: discard
      inc argIndex
    elif arg.kind == nnkExprEqExpr:
      # Named arguments like required=false, holds_value=true
      let name = $arg[0]
      case name:
      of "required":
        if arg[1].kind == nnkIdent:
          required = $arg[1] == "true"
      of "holds_value":
        if arg[1].kind == nnkIdent:
          holdsValue = $arg[1] == "true"
      of "description":
        if arg[1].kind in {nnkStrLit, nnkRStrLit, nnkTripleStrLit}:
          desc = getStringValue(arg[1])
  
  return (short, long, desc, holdsValue, required)

# Process a single statement in the DSL
proc processStatement(stmt: NimNode): seq[NimNode] =
  result = @[]
  
  case stmt.kind:
  of nnkCommand:
    let funcName = $stmt[0]
    
    case funcName:
    of "flag":
      # Extract arguments
      var args: seq[NimNode] = @[]
      for i in 1..<stmt.len:
        args.add(stmt[i])
      
      let (short, long, desc, holdsValue, required) = processFlagArgs(args)
      
      # Build: parser.addFlag(short, long, description=desc, holds_value=holdsValue, required=required)
      var flagCall = newCall(newDotExpr(ident("parser"), ident("addFlag")))
      
      if short != "": flagCall.add(newStrLitNode(short))
      if long != "": flagCall.add(newStrLitNode(long))
      if desc != "": 
        flagCall.add(newColonExpr(ident("description"), newStrLitNode(desc)))
      if holdsValue:
        flagCall.add(newColonExpr(ident("holds_value"), ident("true")))
      if required:
        flagCall.add(newColonExpr(ident("required"), ident("true")))
      
      result.add(flagCall)
    
    of "command":
      # Handle: command("name"): body
      let cmdName = stmt[1]
      let cmdBody = stmt[^1]
      
      # Process command body to extract subcommands and flags
      var subCommands: seq[NimNode] = @[]
      var subFlags: seq[NimNode] = @[]
      
      if cmdBody.kind == nnkStmtList:
        for subStmt in cmdBody:
          let subResults = processStatement(subStmt)
          
          # Distinguish between subcommands and flags
          for subResult in subResults:
            if subResult.kind == nnkCall:
              let callExpr = subResult[0]
              if callExpr.kind == nnkDotExpr:
                let methodName = $callExpr[1]
                if methodName == "addCommand":
                  # Convert parser.addCommand to newCommand for subcommands
                  var newCmdCall = newCall(ident("newCommand"))
                  # Copy arguments except the parser part
                  for i in 1..<subResult.len:
                    newCmdCall.add(subResult[i])
                  subCommands.add(newCmdCall)
                elif methodName == "addFlag":
                  # Convert parser.addFlag to newFlag for sub-flags
                  var newFlagCall = newCall(ident("newFlag"))
                  for i in 1..<subResult.len:
                    newFlagCall.add(subResult[i])
                  subFlags.add(newFlagCall)
      
      # Handle unnamed_argument calls in command body
      if cmdBody.kind == nnkStmtList:
        for subStmt in cmdBody:
          if subStmt.kind == nnkCall and $subStmt[0] == "unnamed_argument":
            var unnamedCall = newCall(ident("newUnnamedArgument"))
            for i in 1..<subStmt.len:
              unnamedCall.add(subStmt[i])
            subFlags.add(unnamedCall)
      
      # Combine subcommands and flags
      var allSubElements = subCommands & subFlags
      
      # Build: parser.addCommand(name, @[subElements], description)
      var cmdCall = newCall(newDotExpr(ident("parser"), ident("addCommand")))
      cmdCall.add(cmdName)
      
      if allSubElements.len > 0:
        # Create @[...] array
        var arrayLit = newNimNode(nnkPrefix)
        arrayLit.add(ident("@"))
        var bracket = newNimNode(nnkBracket)
        for elem in allSubElements:
          bracket.add(elem)
        arrayLit.add(bracket)
        cmdCall.add(arrayLit)
      else:
        # Empty array
        var emptyArray = newNimNode(nnkPrefix)
        emptyArray.add(ident("@"))
        emptyArray.add(newNimNode(nnkBracket))
        cmdCall.add(emptyArray)
      
      # Add empty description as default
      cmdCall.add(newStrLitNode(""))
      
      result.add(cmdCall)
  
  of nnkCall:
    let funcName = $stmt[0]
    case funcName:
    of "unnamed_argument":
      # This would be handled in command context
      # For top-level, we might need addUnnamedArgument
      var unnamedCall = newCall(newDotExpr(ident("parser"), ident("addUnnamedArgument")))
      for i in 1..<stmt.len:
        unnamedCall.add(stmt[i])
      result.add(unnamedCall)
  
  else:
    #error("Unsupported statement kind: " & $stmt.kind, stmt)
    discard

macro newParserMacro*(name: string, body: untyped): untyped =
  # Create: var parser = newParser(name)
  var parserDecl = newNimNode(nnkVarSection)
  var identDef = newNimNode(nnkIdentDefs)
  identDef.add(ident("parser"))
  identDef.add(newEmptyNode())
  identDef.add(newCall(ident("newParser"), name))
  parserDecl.add(identDef)
  
  # Process all statements in the body and collect method calls
  var allCalls: seq[NimNode] = @[]
  
  for stmt in body:
    let calls = processStatement(stmt)
    allCalls = allCalls & calls
  
  # Build method chaining: parser.addFlag(...).addCommand(...)
  var res = newStmtList()
  res.add(parserDecl)
  
  if allCalls.len > 0:
    var chainExpr = ident("parser")
    for call in allCalls:
      chainExpr = call
      # Replace the first argument (which should be parser) with the chain
      if call.len > 0 and call[0].kind == nnkDotExpr:
        call[0][0] = chainExpr
    
    # Add the final chained expression as a statement
    res.add(chainExpr)
  
  res
