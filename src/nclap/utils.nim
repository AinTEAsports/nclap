import std/[strformat, strutils, sugar]

# NOTE: it should not contain =
func expandCompactArgv(compact_argv: string): seq[string] =
  assert not compact_argv.contains('=')

  let compact =
    (if compact_argv.startsWith('-'): compact_argv[1 ..^ 1]
    else: compact_argv)
  collect(
    for c in compact:
      &"-{c}"
  )

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
          splt = arg.split('=', maxsplit = 1)
          compactflag = splt[0]
          content = (if len(splt) == 2: splt[1] else: "")

        for expanded in expandCompactArgv(compactflag):
          res.add(expanded)

        # NOTE: add what was after the "=" to the last argument
        res[len(res) - 1] &= &"={content}"
      else:
        for expanded in expandCompactArgv(arg):
          res.add(expanded)
    else:
      res.add(arg)

  res
