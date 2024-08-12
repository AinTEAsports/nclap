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

const DEFAULT_CLIARG = CLIArg(content: "", registered: false, subarguments: initTable[string, CLIArg]())


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


func `[]`*(cliarg: CLIArg, subargument_name: string): CLIArg =
  cliarg.subarguments[subargument_name]

func `[]`*(cliargs: CLIArgs, cliarg_name: string): CLIArg =
  if not cliargs.hasKey(cliarg_name): raise newException(KeyError, &"Key \"{cliarg_name}\" not found in CLIArgs")
  else: cliargs.getOrDefault(cliarg_name, DEFAULT_CLIARG)

func getCLIArg*(cliargs: CLIArgs, cliarg_name: string): CLIArg =
  cliargs[cliarg_name]
