import std/[
  strformat,
  strutils,
  sugar,
  macros,
]

const
  DEFAULT_NO_COLORS* = false
  COLORS* = (
    reset: "\e[0m",
    bold_black: "\e[1;30m",
    red: "\e[0;91m",
  )


# NOTE: it should not contain =
func expandCompactArgv(compact_argv: string): seq[string] =
  assert not compact_argv.contains('=')

  let compact = (if compact_argv.startsWith('-'): compact_argv[1..^1] else: compact_argv)
  collect(for c in compact: &"-{c}")


func expandArgvShortFlags*(argv: seq[string]): seq[string] =
  ##[ This function expands all compact short flags into multiple short flags
    If this is unclear, compact short flags are things like `-abc` (which will
    expand into `-a -b -c`) or `-abco=/tmp/output.txt` (which will expand into
    `-a -b -c -o=/tmp/output.txt` or `-a -b -c -o /tmp/output.txt` depending on
    how lazy I am)

  Examples:
  ```nim
  assert expandArgvShortFlags(@["-abc"]) == @["-a", "-b", "-c"]
  assert expandArgvShortFlags(@["-abc", "-def"]) == @["-a", "-b", "-c", "-d", "-e", "-f"]
  assert expandArgvShortFlags(@["-abco=/tmp/output.txt"]) == @["-a", "-b", "-c", "-o=/tmp/output.txt"]
  ```
  ]##

  var res: seq[string] = @[]

  for arg in argv:
    # NOTE: then it is a compact flag
    if arg.startsWith('-') and not arg.startsWith("--"):
      if arg.contains('='):
        let
          splt = arg.split('=', maxsplit=1)
          compactflag = splt[0]
          content = (if len(splt) == 2: splt[1] else: "")

        for expanded in expandCompactArgv(compactflag): 
          res.add(expanded)

        # NOTE: add what was after the "=" to the last argument
        res[len(res)-1] &= &"={content}"
      else:
        for expanded in expandCompactArgv(arg):
          res.add(expanded)
    else: res.add(arg)

  res


func error*(error_header, error_message: string, no_colors: bool = DEFAULT_NO_COLORS): string =
  (
    if no_colors: &"[{error_header}]"
    else:
      &"{COLORS.bold_black}[{COLORS.reset}" &
      &"{COLORS.red}{error_header}{COLORS.reset}" &
      &"{COLORS.bold_black}]{COLORS.reset}"
  ) & " " & error_message



macro commandMatch*(of_branches: varargs[untyped]): untyped =
  if of_branches.len == 0:
    error("expected at least one branch", of_branches)

  var
    res = nnkIfStmt.newTree()
    else_branch = false
    last_body = newEmptyNode()

  for branch in of_branches:
    # NOTE: `false or B` <=> `B`
    var condition = newLit(false)

    case branch.kind:
      of nnkOfBranch:
        # NOTE: => false or (a or (b or (c)))

        let
          of_keys = branch[0..^2]
          of_body = branch[^1]

        # NOTE: last branch is the body
        for of_key in of_keys:
          condition = newCall(
            "or",

            # NOTE: both are valid since '?`branch[0]`' <=> '`branch[0]`.registered'
            # but I prefer `.registered` since this most likely won't change
            #newCall("?", newPar(branch[0])),
            newDotExpr(newPar(branch[0]), newIdentNode("registered")),

            condition,
          )


        res.add nnkElifBranch.newTree(
          condition,
          of_body
        )

        last_body = of_body

      of nnkElse:
        # NOTE: `else:` <=> `elif true:`
        else_branch = true

        res.add nnkElse.newTree(
          branch[0]
        )

        last_body = branch[0]

      else:
        error("should be 'of' or 'else' branch", branch)

  if not else_branch:
    res.add nnkElse.newTree(
      quote do:
        assert false, "no value matched"
        `last_body`  # NOTE: this is added for expression value return
                     # but it will never reach because of the assert
    )

  res
