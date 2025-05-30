

template test*(name: string, body: untyped): untyped =
  # NOTE: do not remove, makes all variable local and destroyed after test ran
  if true:
    body

template check*(expr: untyped): untyped =
  #check expr
  assert expr

