# nclap
A simple clap-like command line argument parser written in Nim

---

## Summary
`nclap` is a **small and simple**, [clap](https://github.com/clap-rs/clap)-like (more [argparse](https://docs.python.org/3/library/argparse.html)-like, but `nargparse` sounded less cool)
command line argument parser written in Nim.

It can be used with commands (for example `./program add task "use nim"` or `./program remove project "use python"`),
flags (for example `./program -l --all --output=file`), or both.

To add it to your project just do:
```sh
$ nimble add nclap
```

---

## Examples

Here is a basic examples, for more examples please see [examples](https://github.com/AinTEAsports/nclap/tree/main/examples)

```nim
import
  std/options,
  nclap

var p = newParser("example number 2, commands only")

initParser(p):
  Flag("-l", "--log-file", "file to log the adds/removes in", holds_value=true, default=some("/dev/null"))

  Command("add", "adds a task"):
    Flag("-a", "--alias", "alias of the task", holds_value=true)
    UnnamedArgument("name", "name of the task to add")

  Command("remove", "removes a task"):
    Flag("-n", "--no-resolve-alias", "do not resolve the alias")
    UnnamedArgument("name", "name of the task to remove")

  Command("list", "lists tasks"):
    Command("all", "lists all tasks, even the hidden ones")

let args = p.parse()

echo "Logfile: " & !args.log_file

commandMatch:
of args@add:
  echo "Adding task " & !((args@add).name)

  if ?((args@add).alias):
    echo "It has the associated alias " & !((args@add).alias)

of args@remove:
  echo "Removing task" & !((args@remove).name)

  if ?((args@add).no_resolve_alias):
    echo "Not resolving any alias it could have"

of args@list@all:
  echo "Listing all commands, even the hidden ones"

of args@list:
  echo "Listing all commands that are not hidden"
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


#### Use the parser outside of the CLI
This parser's `.parse` functin can also take in a `seq[string]` to parse anything you throw at it, for example in the previous example we could have done
```nim
let args = parser.parse(@["add", "--alias=an_alias", "task_name"])
```

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

## Bugs and fixes:
If you encounter any bug, issue or suggestion about anything, please open an issue or a PR
