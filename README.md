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
