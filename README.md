# nclap
A simple clap-like command line argument parser written in Nim

---

## Summary
`nclap` is a **small and simple**, [clap](https://github.com/clap-rs/clap)-like (more [argparse](https://docs.python.org/3/library/argparse.html)-like, but `nargparse` sounded less cool)
command line argument parser written in Nim.

It can be used with commands (for example `./program add task "use nim"` or `./program remove project "use python"`),
flags (for example `./program -l --all --output=file`), or both.

---

## Examples

Here are some examples, (or just go see the [examples](https://github.com/AinTEAsports/nclap))

### Example 1 (flags only):
```nim
import nclap/[
  parser,
  cliargs,
  arguments
]

var p = newParser("example number 1, flags only")

# NOTE: p.addFlag(short, long, description=long, holds_value=false, required=false)
p.addFlag("-h", "--help", "shows this help message")
  .addFlag("-vv", "--verbose", "shows additional information")
  .addFlag("-o", "--output", , "outputs to a file", true)

let args = p.parse()

# you can access the flag value with the short or the long version
if ?args.help:
  # NOTE: the `showHelp` message can be tuned,
  # try to tinker with the parameters and see what happens
  p.showHelp(exit_code=1)

if ?args.vv:
  echo "Showing additional information"

echo "Output goes to: " & (args.output !! "/path/to/default_file")
# <=> echo "Output goes to: " & args["--output"].getContent(default="/path/to/default_file")
```
```sh
$ nim c examples/example1.nim
$ ./example1 -vv --output=/path/to/file
Showing additional information
Output goes to: /path/to/file
```


### Example 2 (commands only):
```nim
import nclap/[
  parser,
  cliargs,
  arguments
]

var p = newParser("example number 2, commands only")

# NOTE: p.addCommand(name, subcommands=@[], desc=name, required=true)
p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  .addCommand("remove", @[newCommand("task", @[], "removes a task"), newCommand("project", @[], "removes a project")], "")
  .addCommand("list", @[newCommand("all", @[], "lists everything", required=false)], "lists almost everything")

let args = p.parse()

if ?args@add:
  if ?args@task:
    echo "Adding task", !args@add@task
  else:
    echo "Adding project", !args@add@project
elif ?args@remove:
  if ?args@task:
    echo "Removing task", !args@remove@task
  else:
    echo "Removing project", !args@remove@project
else:
  echo "Listing " & (if ?args@list@all: "" else: "almost ") & "everything"

```
```sh
$ nim c examples/example2.nim
$ ./example2 add project "use python"
Adding project use python
```


### Example 3 (commands and flag):
```nim
import nclap/[
  parser,
  cliargs,
  arguments
]

proc outputTo(out: string, content: string) =
  if out == "": echo content
  else: writeFile(out, content)


var p = newParser("example number 2, commands only")

p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  .addCommand("remove", @[newCommand("task", @[newFlag("-n", "--no-log", "does not log the deletion")], "removes a task"), newCommand("project", @[], "removes a project")], "")
  .addCommand("list", @[newFlag("-a", "--all", "show even hidden tasks/projects")], "listing tasks and projects")
  .addFlag("-o", "--output", "outputs the content to a file", true)

let
  args = p.parse()
  out = !args.output

if ?args@add:
  if ?args@task:
    outputTo(out, "Adding task" & !args@add@task)
  else:
    outputTo(out, "Adding project" & !args@add@project)
elif ?args@remove:
  if not ?args@task["-n"]:
    if ?args@task:
      outputTo(out, "Removing task" & !args@remove@task)
    else:
      outputTo(out, "Removing project" & !args@remove@project)
else:
  outputTo(out, "Listing " & (args@list["-a"] ?? "almost") & " everything")
```
```sh
$ nim c examples/example3.nim
$ ./example3 remove --no-log task "use python"
Removing project use python
```


---

## Tips

#### Customizing the help message
You can customize the parser help message:
```nim
let settings: HelpSettings = (
    tabstring: "│   ",
    prefix_pretab: "-> ",
    prefix_posttab: "├─ ",
    prefix_posttab_last: "└─ ",
    surround_left_required: "{",
    surround_right_required: "}",
    surround_left_optional: "{",
    surround_right_optional: "}",
    separator: ", ",
)
var p = newParser("customizing help message", settings)

p.addCommand("add", @[newCommand("task", @[], "adds a task"), newCommand("project", @[], "adds a project")], "")
  .addCommand("remove", @[newCommand("task", @[newFlag("-n", "--no-log", "does not log the deletion")], "removes a task"), newCommand("project", @[], "removes a project")], "")
  .addCommand("list", @[newFlag("-a", "--all", "show even hidden tasks/projects")], "listing tasks and projects")
  .addFlag("-o", "--output", "outputs the content to a file", true)

let args = p.parse()
```
```sh
$ ./program
customizing help message
-> ├─ {add}
-> │   ├─ {task}                adds a task
-> │   └─ {project}             adds a project
-> ├─ {remove}
-> │   ├─ {task}                removes a task
-> │   │   └─ {-n, --no-log}            does not log the deletion
-> │   └─ {project}             removes a project
-> ├─ {list}            listing tasks and projects
-> │   └─ {-a, --all}           show even hidden tasks/projects
-> └─ {-o, --output}            outputs the content to a file
```
It might not be the most beautiful help message, but at least it covers every option that are availible
for the moment.<br>
Feel free to tinker with these to find the perfect combination


#### Compact short flags
You can use the `enforce_shortflag=true` in `newParser` to enforce flags short version to be at most 1 character long
(for example `-a`, `-o`, but not `-type`)

This will enable compacting short flags when parsing.
For example, `./program -abc` will be expanded as `./program -a -b -c`
`./program -abco=output_file` will be expanded as `./program -a -b -c -o=output_file`

By default this option is off, letting you have short flags as long as you want
(not too long though, for example `-outputtoacertainfileaftercallingandthisflagisbecomingabittoolong` is a tiny bit too long)
but will not enable compacting short flags (for example `./program -abc` will stay `./program -abc`)


---
## Operators
There are operators used in the code, here are their use and equivalent


#### Operators and
- `args.arg` <=> `args["-arg"]` or `args["--arg"]` depending on what exists, I will use `args["--arg"]` from now on for simplification purposes
- `args@arg` <=> `args["arg"]`, gets the `CLIArg` associated with the subcommand `arg`
- `?args.arg` <=> `args["--arg"].registered`, returns `true` if the argument was given and `false` otherwise
- `args.arg ?? some_value`, same as previous, but returns the content of the argument if it was registered, otherwise returns `some_value`
- `!args.arg` <=> `args["--arg"].getContent(error=true)`, returns the value held inside the argument, and errors if none was given
- `args.arg !! some_value`, same as previous, but if no value was held, returns `some_value`

---

## TODO:
Functionalities to be implemented in the future:
<br></br>
    - [ ] Macro to set subcommands and flags such as:
```nim
var p = createParser("small todo app"):
  flag("-v", "--verbose", desc="shows debug information")
  flag("-n", "--no-log", desc="does not show log")

  command("add"):
    command("project", desc="adds project")
    command("task", desc="adds task")
    flag("-u", "--update", desc="update the content/name if the task/project already existed")

  command("remove"):
    command("project", desc="removes project")
    command("task", desc="removes task")
    flag("-f", "--force", desc="does not show error if task/project did not existed")

  command("list"):
    command("all")
```

---

## Bugs and fixes:
If you encounter any bug, issue or suggestion about anything, please open an issue or a PR
