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
