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

  &"CLIArg(content: {c}, registered: {r}, subarguments: {s})"


func `$`*(cliargs: CLIArgs): string =
  result &= "{\n"

  for name, cliarg in cliargs:
    result &= &"\t\"{name}\": {cliarg},\n"

  result &= "}"


func tostring*(cliarg: CLIArg): string =
  $cliarg


func tostring*(cliargs: CLIArgs): string =
  $cliargs

func get[A, B](table: Table[A, B], x: A): B =
  if not table.hasKey(x):
    raise newException(KeyError, &"Key \"{x}\" not found")

  table.getOrDefault(x, B())


func `[]`*(cliarg: CLIArg, subargument_name: string): CLIArg =
  #if cliarg.subarguments.hasKey(subargument_name): cliarg.subarguments.get(subargument_name)
  #elif cliarg.subarguments.hasKey(&"-{subargument_name}"): cliarg.subarguments.get(&"-{subargument_name}")
  #elif cliarg.subarguments.hasKey(&"--{subargument_name}"): cliarg.subarguments.get(&"--{subargument_name}")
  #else: cliarg.subarguments[subargument_name]

  cliarg.subarguments.get(subargument_name)


func `[]`*(cliargs: CLIArgs, cliarg_name: string): CLIArg =
  if cliargs.hasKey(cliarg_name): cliargs.get(cliarg_name)
  #elif cliargs.hasKey(&"-{cliarg_name}"): cliargs.get(&"-{cliarg_name}")
  #elif cliargs.hasKey(&"--{cliarg_name}"): cliargs.get(&"--{cliarg_name}")
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
  cliarg.getContent(default, false)

template `!`*(cliarg: CLIArg): string =
  cliarg.getContent(error=true)


template `?`*(cliarg: CLIArg): bool =
  cliarg.registered

template `??`*(cliarg: CLIArg, s: string): string =
  (if cliarg.registered: s else: "")



template `@`*(cliarg: CLIArg, name: untyped): CLIArg =
  cliarg.subarguments[astToStr(name)]

template `@`*(cliargs: CLIArgs, name: untyped): CLIArg =
  cliargs[astToStr(name)]


template `.`*(cliarg: CLIArg, name: untyped): untyped =
  (
    let name_str = astToStr(name)

    if cliarg.subarguments.hasKey("-" & name_str): cliarg.subarguments["-" & name_str]
    elif cliarg.subarguments.hasKey("--" & name_str): cliarg.subarguments["--" & name_str]
    else: raise newException(KeyError, "Key \"" & name_str & "\" not found in CLIArgs")
  )

template `.`*(cliargs: CLIArgs, name: untyped): untyped =
  (
    let name_str = astToStr(name)

    if cliargs.hasKey("-" & name_str): cliargs["-" & name_str]
    elif cliargs.hasKey("--" & name_str): cliargs["--" & name_str]
    else: raise newException(KeyError, "Key \"" & name_str & "\" not found in CLIArgs")
  )
