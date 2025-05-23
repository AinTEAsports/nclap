import std/[
  strformat,
  sugar,
  options,
  sequtils,
  strutils
]

const
  FLAG_HOLDS_VALUE_DEFAULT* = false
  FLAG_REQUIRED_DEFAULT* = false
  COMMAND_REQUIRED_DEFAULT* = true
  UNNAMED_ARGUMENT_PREFIX* = "$"
  HOLDS_VALUE_DEFAULT* = false
  DEFAULT_SHOWHELP_SETTINGS* = (
    tabstring: "  ",
    prefix_pretab: "",
    prefix_posttab: "",
    prefix_posttab_last: "",
    surround_left_required: "(",
    surround_right_required: ")",
    surround_left_optional: "[",
    surround_right_optional: "]",
    separator: "|"
  )

type
  HelpSettings* = tuple[
    tabstring: string,
    prefix_pretab: string,
    prefix_posttab: string,
    prefix_posttab_last: string,
    surround_left_required: string,
    surround_right_required: string,
    surround_left_optional: string,
    surround_right_optional: string,
    separator: string
  ]

  ArgumentType* = enum
    Command
    Flag
    UnnamedArgument

  Argument* = ref object
    description*: string
    required*: bool
    holds_value*: bool
    default*: Option[string]

    case kind*: ArgumentType
      of Flag:
        short*: string
        long*: string

      of Command:
        name*: string
        subcommands*: seq[Argument]

      of UnnamedArgument:
        ua_name*: string


func newFlag*(
  short: string,
  long: string = short,
  description: string = long,
  holds_value: bool = FLAG_HOLDS_VALUE_DEFAULT,
  required: bool = FLAG_REQUIRED_DEFAULT,
  default: Option[string] = none[string]()
): Argument =
  Argument(
    kind: Flag,
    short: short,
    long: long,
    description: description,
    holds_value: holds_value,
    required: required,
    default: default
  )

func newCommand*(
  name: string,
  subcommands: seq[Argument] = @[],
  description: string = name,
  required: bool = COMMAND_REQUIRED_DEFAULT,
  holds_value: bool = HOLDS_VALUE_DEFAULT,
  default: Option[string] = none[string]()
): Argument =
  Argument(
    kind: Command,
    name: name,
    subcommands: subcommands,
    description: description,
    required: required,
    holds_value: holds_value,
    default: default
  )


func newUnnamedArgument*(
  name: string,
  description: string = name,
  default: Option[string] = none[string]()
): Argument =
  Argument(
    kind: UnnamedArgument,
    ua_name: name,
    holds_value: true,
    description: description,
    required: true,
    default: default
  )


func `$`*(argument: Argument): string =
  case argument.kind
    of Flag:
      let
        s = argument.short
        l = argument.long
        h = argument.holds_value
        desc = argument.description
        def = argument.default
        r = argument.required

      &"Flag(short: \"{s}\", long: \"{l}\", holds_value: {h}, description: \"{desc}\", required: {r}, default: {def})"

    of Command:
      let
        n = argument.name
        s = argument.subcommands
        desc = argument.description
        def = argument.default
        r = argument.required
        h = argument.holds_value

      &"Command(name: \"{n}\", subcommands: {s}, description: \"{desc}\", required: {r}, has_content: {h}, default: {def})"

    of UnnamedArgument:
      &"[WARNING]: not implemented yet"


func getFlags*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Flag)

func getCommands*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Command)

func getUnnamedArguments*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == UnnamedArgument)


func helpToStringAux(
  argument: Argument,
  settings: HelpSettings = DEFAULT_SHOWHELP_SETTINGS,
  depth: int = 0,
  is_first: bool = true,
  is_last: bool = false
): string =
  let
    (
      tabstring,
      prefix_pretab,
      prefix_posttab,
      prefix_posttab_last,
      surround_left_required,
      surround_right_required,
      surround_left_optional,
      surround_right_optional,
      separator
    ) = settings
    tabrepeat = tabstring.repeat(depth)
    posttab = (
      if is_last or argument.kind == Flag: prefix_posttab_last
      else: prefix_posttab
    )

  let
    surround_left = (if argument.required: surround_left_required else: surround_left_optional)
    surround_right = (if argument.required: surround_right_required else: surround_right_optional)

  case argument.kind:
    of Flag:
      let
        usage = (
          if argument.short == argument.long: &"{surround_left}{argument.short}{surround_right}"
          else: &"{surround_left}{argument.short}{separator}{argument.long}{surround_right}"
        )
        desc = &"{argument.description}"

      # NOTE: no subcommands to a flag, it is the first but more importantly the last
      &"{prefix_pretab}{tabrepeat}{posttab}{usage}\t\t{desc}"

    of Command:
      var res = ""

      let
        usage = &"{surround_left}{argument.name}{surround_right}"
        desc = &"{argument.description}"

      res &= &"{prefix_pretab}{tabrepeat}{posttab}{usage}\t\t{desc}"

      for i in 0..<len(argument.subcommands):
        let
          subargument = argument.subcommands[i]
          is_last_argument = (i == len(argument.subcommands)-1)

        res &= "\n" & subargument.helpToStringAux(settings=settings, depth=depth+1, is_last=is_last_argument)

      res

    of UnnamedArgument:
      &"[WARNING]: still not implemented"


func helpToString*(
  argument: Argument,
  settings: HelpSettings = DEFAULT_SHOWHELP_SETTINGS,
): string =
  helpToStringAux(argument, settings, 0, true, false)
