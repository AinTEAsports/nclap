# Package

version       = "0.1.20"
author        = "aintea"
description   = "A simple clap-like command line argument parser written in Nim"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.4"

taskRequires "fmt", "nph >= 0.6.0"

task fmt, "Run a formatter on the code":
  exec "nph src/"
  exec "nph tests/"
