import std/[
  strformat,
  sugar,
  sequtils,
  strutils
]

import cliargs

const
  FLAG_HOLDS_VALUE_DEFAULT* = false
  FLAG_REQUIRED_DEFAULT* = true
  COMMAND_REQUIRED_DEFAULT* = true

type
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


func newFlag*(
  short: string,
  long: string = short,
  description: string = long,
  holds_value: bool = FLAG_HOLDS_VALUE_DEFAULT,
  required: bool = FLAG_REQUIRED_DEFAULT
): Argument =
  Argument(kind: Flag, short: short, long: long, flag_description: description, holds_value: holds_value, flag_required: required)

func newCommand*(
  name: string,
  subcommands: seq[Argument] = @[],
  description: string = name,
  required: bool = COMMAND_REQUIRED_DEFAULT
): Argument =
  Argument(kind: Command, name: name, subcommands: subcommands, command_description: description, command_required: required)

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


func getFlags*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Flag)

func getCommands*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Command)


func helpToString*(
  argument: Argument,
  depth: int = 0,
  tabstring: string = "  ",
  prefix: string = "",
  surround_left: string = "[",
  surround_right: string = "]",
  separator: string = "|"
): string =
  let tabrepeat = tabstring.repeat(depth)

  case argument.kind:
    of Flag:
      let
        usage = &"{surround_left}{argument.short}{separator}{argument.long}{surround_right}"
        desc = &"{argument.flag_description}"

      &"{prefix}{tabrepeat}{usage}\t\t{desc}"

    of Command:
      var res = ""

      let
        usage = &"{surround_left}{argument.name}{surround_right}"
        desc = &"{argument.command_description}"

      res &= &"{prefix}{tabrepeat}{usage}\t\t{desc}"

      for subargument in argument.subcommands:
        res &= "\n" & subargument.helpToString(depth+1)

      res
