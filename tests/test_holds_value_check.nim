import
  std/options,

  nclap,
  testutils

test "customizing help message":
  var p = newParser("customizing help message")

  initParser(p):
    Flag("-c", "--check", default=some("default_check"))

  let args = p.parse(@[])

  check !args.c == "default_check"
