# support-pack

## Name

support-pack - Generate a tech support package

## Synopsys

```
support-pack [-o output_path] [--notgz] [config_file]
```

## Description

`support-pack` generates a tech support package that contains various
information about the current state of the machine. It is designed with embedded
systems in mind, with the goal that a non-technical user can launch the program
and send the result to a "tech support" team.

`support-pack` needs a configuration file placed in
`/etc/support-pack/support-pack.conf`, unless a config path is passed as a
command line argument. This configuration file is a shell script that must obey
some specific rules and tells `support-pack` which command should be run and
where to store the output.

### Config file syntax

The `/etc/support-pack/support-pack.conf` file is a shell script that should
make use of the following commands:

* **`support_cmd <command>`**: Execute a shell command while adding some
  introduction text before running the command. The output of `support_cmd`
  should be piped into `support_log_file`.
* **`support_log_file <filename>`**: Create `<filename>` into the tech support
  archive and accept any amount of text from stdin to be logged into the file.
* **`support_copy_file <src> [dest]`**: Copy a file from `<src>`, a regular file
  present on the system to `<dst>`, a relative path in the tech support archive.
  If `<dst>` is omitted, the destination is a file of the same name of `<src>`
  stored at the root of the tech support package.
* **`support_copy_dir <src> [dest]`**: Copy a directory structure `<src>` to the
  tech support archive. `<dest>` can be omitted to store the directory `<src>`
  at the root of the support archive. `<dest>` can be used to specify a
  directory in the tech support archive into which the `<src>` directory should
  be stored.
* **`support_info <text>`**: log a string to the `support-pack.txt` file
* **`support_error <text>`**: log an error message to the `support-pack.txt`
  file

Use a shell pipe (`|`) to forward the output of a `support_cmd` to a
`support_log_file`:

```
support_cmd dmesg | support_log_file dmesg.txt
```

Use shell braces (`{}`) to group multiple `support_cmd` into a single subprocess
piped into a `support_log_file`:

```
{
    support_cmd cat /etc/os-release
    support_cmd cat /proc/cmdline
    support_cmd date
    support_cmd uptime
    support_cmd free -m
    support_cmd df -h
    support_cmd mount
    support_cmd ls -la /run
    support_cmd ps
    support_cmd top -b -n 1 -d 1
} | support_log_file "system.txt"
```

### Output

As shown below, support-pack will output various informations about the commands
it executes and the files it creates.

```
[INFO ] Fetching system infos..
[INFO ] Exec command "cat /etc/os-release"
[INFO ] Exec command "cat /proc/cmdline"
[INFO ] Exec command "date"
[INFO ] Exec command "uptime"
[INFO ] Exec command "free -m"
[INFO ] Exec command "df -h"
[INFO ] Exec command "mount"
[INFO ] Exec command "ls -la /run"
[INFO ] Exec command "ps"
[INFO ] Exec command "top -b -n 1 -d 1"
[INFO ] Created file "system.txt"
[INFO ] Fetching kernel dmesg..
[INFO ] Exec command "dmesg"
[INFO ] Created file "dmesg.txt"
[INFO ] Fetching network infos..
[INFO ] Exec command "ifconfig"
[INFO ] Exec command "netstat -ant"
[INFO ] Created file "network.txt"
[INFO ] Archiving files..
[INFO ] Archive "/tmp/support-pack-20221223-141651.tar.gz" (48K) has been created.
/tmp/support-pack-20221223-141651.tar.gz
```

All the information produced by `support-pack` is outputed on stderr. This
information, up to the archiving step, is also available in the support package
itself in a file named `support-pack.txt`.

If `support-pack` exits with a zero return code, the only line produced on
stdout will be the name of the archive that was produced or the name of the
support-pack directory if the archiving step was skipped.
