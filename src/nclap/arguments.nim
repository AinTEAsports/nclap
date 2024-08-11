import std/[
  strformat,
  sugar,
  sequtils
]

import cliargs

const HOLDS_VALUE_DEFAULT* = false

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

      of Command:
        name*: string
        subcommands*: seq[Argument]
        command_description*: string


func newFlag*(short: string, long: string = short, holds_value: bool = HOLDS_VALUE_DEFAULT, description: string = long): Argument =
  Argument(kind: Flag, short: short, long: long, holds_value: holds_value, flag_description: description)

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

      &"Flag(short: \"{s}\", long: \"{l}\", holds_value: {h}, description: \"{desc}\")"

    of Command:
      let
        n = argument.name
        s = argument.subcommands
        desc = argument.command_description

      &"Command(name: \"{n}\", subcommands: \"{s}\", description: \"{desc}\")"


func getFlags*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Flag)

func getCommands*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Command)
