import std/[
  strformat,
  sugar,
  sequtils,
  strutils
]

import cliargs

const
  HOLDS_VALUE_DEFAULT* = false
  REQUIRED_DEFAULT* = true

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
        required*: bool

      of Command:
        name*: string
        subcommands*: seq[Argument]
        command_description*: string


func newFlag*(
  short: string,
  long: string = short,
  description: string = long,
  holds_value: bool = HOLDS_VALUE_DEFAULT,
  required: bool = REQUIRED_DEFAULT
): Argument =
  Argument(kind: Flag, short: short, long: long, flag_description: description, holds_value: holds_value, required: required)

func newCommand*(name: string, subcommands: seq[Argument] = @[], description: string = name): Argument =
  Argument(kind: Command, name: name, subcommands: subcommands, command_description: description)

func `$`*(argument: Argument): string =
  case argument.kind
    of Flag:
      let
        s = argument.short
        l = argument.long
        h = argument.holds_value
        desc = argument.flag_description
        r = argument.required

      &"Flag(short: \"{s}\", long: \"{l}\", holds_value: {h}, description: \"{desc}\", required: {r})"

    of Command:
      let
        n = argument.name
        s = argument.subcommands
        desc = argument.command_description

      &"Command(name: \"{n}\", subcommands: {s}, description: \"{desc}\")"


func getFlags*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Flag)

func getCommands*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Command)


func helpToString*(argument: Argument, depth: int = 0, tab: string = "  "): string =
  let tab_prefix = tab.repeat(depth)

  case argument.kind:
    of Flag: &"{tab_prefix}[{argument.short}|{argument.long}]\t\t{argument.flag_description}"
    of Command:
      var res = ""

      res &= &"{tab_prefix}[{argument.name}]\t\t{argument.command_description}"

      for subargument in argument.subcommands:
        res &= "\n" & subargument.helpToString(depth + 1, tab)

      res
