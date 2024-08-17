import std/[tables, strformat, options]

type
  CLIArg* = object
    content*: Option[string]
    registered*: bool = false
    subarguments*: Table[string, CLIArg]

  CLIArgs* = Table[string, CLIArg]

func `$`*(cliarg: CLIArg): string =
  let
    c = cliarg.content
    r = cliarg.registered
    s = cliarg.subarguments

  &"CLIArg(content: {c}, registered: {r}, subarguments: {s})"

func `$`*(cliargs: CLIArgs): string =
  result &= "{\n"

  for name, cliarg in cliargs:
    result &= &"\t\"{name}\": {cliarg},\n"

  result &= "}"

func toString*(cliarg: CLIArg): string {.inline.} =
  $cliarg

func toString*(cliargs: CLIArgs): string {.inline.} =
  $cliargs

func `[]`*(cliarg: CLIArg, subargument_name: string): CLIArg =
  cliarg.subarguments[subargument_name]

func `[]`*(cliargs: CLIArgs, cliarg_name: string): CLIArg =
  if not cliargs.hasKey(cliarg_name):
    raise newException(KeyError, &"Key \"{cliarg_name}\" not found")
  else:
    cliargs.getOrDefault(cliarg_name, CLIArg())

func getCLIArg*(cliargs: CLIArgs, cliarg_name: string): CLIArg {.inline.} =
  cliargs[cliarg_name]

func concatCLIArgs*(a, b: CLIArgs): CLIArgs =
  var res = a

  for key, value in b:
    if not res.hasKey(key) or value.registered:
      res[key] = value

  res

func getContent*(cliarg: CLIArg, default: string | void): string {.inline.} =
  ## Gets the content of a CLIArg. If no value was found, raises an error.
  if cliarg.content.isSome:
    return cliarg.content.get()

  when default is void:
    raise newException(ValueError, "No content stored in CLIArg")
  else:
    return default
