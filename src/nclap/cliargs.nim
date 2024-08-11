import std/[
  tables,
  strformat
]

type
  CLIArg* = object
    content*: string
    registered*: bool
    subarguments*: Table[string, CLIArg]

  CLIArgs* = Table[string, CLIArg]


func `$`*(cliarg: CLIArg): string =
  let
    c = cliarg.content
    r = cliarg.registered
    s = cliarg.subarguments

  &"CLIArg(content: \"{c}\", registered: {r}, subarguments: {s})"


func `$`*(cliargs: CLIArgs): string =
  result &= "{\n"

  for name, cliarg in cliargs:
    result &= &"\t\"{name}\": {cliarg},\n"

  result &= "}"


func tostring*(cliarg: CLIArg): string =
  $cliarg


func tostring*(cliargs: CLIArgs): string =
  $cliargs
