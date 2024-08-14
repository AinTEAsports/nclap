import std/[
  tables,
  strformat,
  options
]


type
  CLIArg* = object
    content*: Option[string]
    registered*: bool
    subarguments*: Table[string, CLIArg]

  CLIArgs* = Table[string, CLIArg]

const
  DEFAULT_CONTENT = ""
  DEFAULT_CLIARG = CLIArg(content: none[string](), registered: false, subarguments: initTable[string, CLIArg]())


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


func concatCLIArgs*(a, b: CLIArgs): CLIArgs =
  var res = a

  for key, value in b:
    if not res.hasKey(key) or value.registered:
      res[key] = value

  res


func getContent*(cliarg: CLIArg, default: string = DEFAULT_CONTENT, error: bool = false): string =
  ##[ Gets the content of a CLIArg, if no value was found, returns the default value (or throw an error if `error` is set to `true`)
  ]##

  if cliarg.content.isSome: cliarg.content.get
  else:
    if error: raise newException(ValueError, "No content in CLIArg")
    else: default
