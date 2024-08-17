import std/[strformat, sugar, sequtils, strutils]

import nclap/cliargs

type
  HelpSettings* = object
    tabstring*: string = "  "
    prefix_pretab*: string
    prefix_posttab*: string
    prefix_posttab_last*: string
    surround_left*: string = "["
    surround_right*: string = "]"
    separator*: string = "|"

  ArgumentType* = enum
    Command
    Flag

  Argument* = ref object
    case kind*: ArgumentType
    of Flag:
      short*: string
      long*: string
      holds_value*: bool
      flag_description*: string
      flag_required*: bool
    of Command:
      name*: string
      subcommands*: seq[Argument]
      command_description*: string
      command_required*: bool

{.push inline, checks: off.}
func newFlag*(
    short: string,
    long: string = short,
    description: string = long,
    holds_value: bool = false,
    required: bool = false,
): Argument =
  Argument(
    kind: Flag,
    short: short,
    long: long,
    flag_description: description,
    holds_value: holds_value,
    flag_required: required,
  )

func newCommand*(
    name: string,
    subcommands: seq[Argument] = @[],
    description: string = name,
    required: bool = true,
): Argument =
  Argument(
    kind: Command,
    name: name,
    subcommands: subcommands,
    command_description: description,
    command_required: required,
  )
{.pop.}

func `$`*(argument: Argument): string =
  case argument.kind
  of Flag:
    let
      s = argument.short
      l = argument.long
      h = argument.holds_value
      desc = argument.flag_description
      r = argument.flag_required

    &"Flag(short: \"{s}\", long: \"{l}\", holds_value: {h}, description: \"{desc}\", required: {r})"
  of Command:
    let
      n = argument.name
      s = argument.subcommands
      desc = argument.command_description
      r = argument.command_required

    &"Command(name: \"{n}\", subcommands: {s}, description: \"{desc}\", required: {r})"

func getFlags*(arguments: seq[Argument]): seq[Argument] {.inline.} =
  arguments.filter(arg => arg.kind == Flag)

func getCommands*(arguments: seq[Argument]): seq[Argument] {.inline.} =
  arguments.filter(arg => arg.kind == Command)

proc helpToStringAux(
    argument: Argument,
    settings: HelpSettings = HelpSettings(),
    depth: int = 0,
    is_first: bool = true,
    is_last: bool = false,
): string =
  let
    tabrepeat = settings.tabstring.repeat(depth)
    posttab =
      if is_last or argument.kind == Flag:
        settings.prefix_posttab_last
      else:
        settings.prefix_posttab

  case argument.kind
  of Flag:
    let
      usage =
        &"{settings.surround_left}{argument.short}{settings.separator}{argument.long}{settings.surround_right}"
      desc = &"{argument.flag_description}"

    # NOTE: no subcommands to a flag, it is the first but more importantly the last
    &"{settings.prefix_pretab}{tabrepeat}{posttab}{usage}\t\t{desc}"
  of Command:
    var res: string

    let
      usage = &"{settings.surround_left}{argument.name}{settings.surround_right}"
      desc = &"{argument.command_description}"

    res &= &"{settings.prefix_pretab}{tabrepeat}{posttab}{usage}\t\t{desc}"

    for i in 0 ..< len(argument.subcommands):
      let
        subargument = argument.subcommands[i]
        is_last_argument = i == len(argument.subcommands) - 1

      res &=
        '\n' &
        subargument.helpToStringAux(
          settings = settings, depth = depth + 1, is_last = is_last_argument
        )

    res

proc helpToString*(
    argument: Argument, settings: HelpSettings = HelpSettings()
): string {.inline.} =
  helpToStringAux(argument, settings, 0, true, false)
