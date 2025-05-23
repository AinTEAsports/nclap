import std/[
  tables,
  strformat,
  strutils,
  options
]


type
  # NOTE: unnamed arguments will be stored as '$<unnamed_arg>' for simplicity reasons
  # therefore it's not possible to make a flag nor a subcommand that starts with '$'
  CLIArg* = object
    content*: Option[string]
    default*: Option[string]  # NOTE: if is 'none', means no default was given and should error on 'not registered'
    registered*: bool
    subarguments*: OrderedTable[string, CLIArg]  # NOTE: ordered to keep the order of unnamed arguments to get the first non registered

  CLIArgs* = OrderedTable[string, CLIArg]

const
  DEFAULT_CONTENT = ""
  DEFAULT_CLIARG = CLIArg(content: none[string](), default: none[string](), registered: false, subarguments: initOrderedTable[string, CLIArg]())

func `$`*(cliarg: CLIArg): string =
  let
    c = cliarg.content
    d = cliarg.default
    r = cliarg.registered
    s = cliarg.subarguments

  &"CLIArg(content: {c}, default: {d}, registered: {r}, subarguments: {s})"


func `$`*(cliargs: CLIArgs): string =
  result &= "{\n"

  for name, cliarg in cliargs:
    result &= &"\t\"{name}\": {cliarg},\n"

  result &= "}"


func tostring*(cliarg: CLIArg): string =
  $cliarg


func tostring*(cliargs: CLIArgs): string =
  $cliargs

func get[A, B](table: OrderedTable[A, B], x: A): B =
  if not table.hasKey(x):
    raise newException(KeyError, &"Key \"{x}\" not found")

  table.getOrDefault(x, B())


func `[]`*(cliarg: CLIArg, subargument_name: string): CLIArg =
  cliarg.subarguments.get(subargument_name)


func `[]`*(cliargs: CLIArgs, cliarg_name: string): CLIArg =
  if cliargs.hasKey(cliarg_name): cliargs.get(cliarg_name)
  else: raise newException(KeyError, &"Key \"{cliarg_name}\" not found in CLIArgs")


func getCLIArg*(cliargs: CLIArgs, cliarg_name: string): CLIArg =
  cliargs[cliarg_name]


func concatCLIArgs*(a, b: CLIArgs): CLIArgs =
  var res = a

  for key, value in b:
    if not res.hasKey(key) or value.registered:
      res[key] = value

  res


func getContent*(cliarg: CLIArg, default: string = DEFAULT_CONTENT, error: bool = false): string =
  ##[ Gets the content of a CLIArg, if no value was found, returns the default
      value (or throw an error if `error` is set to `true`)
  ]##

  if cliarg.content.isSome: cliarg.content.get
  else:
    if error: raise newException(ValueError, "No content in CLIArg")
    else: default


template `!!`*(cliarg: CLIArg, default: string): string =
  cliarg.getContent(default, error=false)

template `!`*(cliarg: CLIArg): string =
  if cliarg.default.isSome: cliarg !! cliarg.default.get()
  else: cliarg.getContent(error=true)


template `?`*(cliarg: CLIArg): bool =
  cliarg.registered

template `??`*(cliarg: CLIArg, s: string): string =
  (if cliarg.registered: s else: "")



template `@`*(cliarg: CLIArg, name: untyped): CLIArg =
  cliarg.subarguments[astToStr(name)]

template `@`*(cliargs: CLIArgs, name: untyped): CLIArg =
  cliargs[astToStr(name)]


template `.`*(cliarg: CLIArg, name: untyped): untyped =
  let name_str = astToStr(name).replace('_', '-')

  if cliarg.subarguments.hasKey("-" & name_str): cliarg.subarguments["-" & name_str]
  elif cliarg.subarguments.hasKey("--" & name_str): cliarg.subarguments["--" & name_str]
  elif cliarg.subarguments.hasKey(UNNAMED_ARGUMENT_PREFIX & name_str): cliarg.subarguments[UNNAMED_ARGUMENT_PREFIX & name_str]
  else: raise newException(KeyError, "Key \"" & name_str & "\" not found in CLIArgs")

template `.`*(cliargs: CLIArgs, name: untyped): untyped =
  let name_str = astToStr(name).replace('_', '-')

  if cliargs.hasKey("-" & name_str): cliargs["-" & name_str]
  elif cliargs.hasKey("--" & name_str): cliargs["--" & name_str]
  elif cliargs.hasKey(UNNAMED_ARGUMENT_PREFIX & name_str): cliargs[UNNAMED_ARGUMENT_PREFIX & name_str]
  else: raise newException(KeyError, "Key \"" & name_str & "\" not found in CLIArgs")
