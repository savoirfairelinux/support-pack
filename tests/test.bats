#!/usr/bin/env bats
#
# Test suite for support-pack.
# Run this test suite in the current directory with:
#
#   $ bats .
#

# Use this to debug from bats.
# Example:
#   echo "Hello" | printer
#
printer()
{
    sed 's/^/# /' >&3
}

# Test setup executed by bats before any test.
#
setup()
{
    rm -rf testdir
    mkdir testdir
    cd testdir
    SUPPORT_PACK="../../support-pack.sh"
    CONFDIR=".."
}

# Test teardown executed by bats after any test.
#
teardown()
{
    cd ..
    rm -rf testdir
}

# Most test in this test suite will run the support-pack command using a
# test-specific conf file in this directory. The run_conf commands does this and
# extract the resulting archive in the current directory for inspection.
#
run_conf()
{
    local conf="${1}"
    local archive="support-pack.tar.gz"
    ${SUPPORT_PACK} ${CONFDIR}/${conf} -o ./$archive 1>stdout.txt 2>stderr.txt

    # Make sure that support-pack exited with a zero return code.
    [ $? -eq 0 ]

    # Make sure that stdout contains only the name of the output archive.
    [ "$(cat stdout.txt)" = "$(pwd)/$archive" ]

    tar -xf $archive

    # Move to the extracted directory.
    cd support-pack-*
}

# Generates an archive with a single support-pack.txt file.
@test "Empty conf" {
    run_conf empty.conf
    [ -f support-pack.txt ]
}

@test "support_info and support_error" {
    run_conf info.conf
    cat  <<EOF | diff - support-pack.txt
[INFO ] An info message
[ERROR] An error message
EOF
}

# Generates an archive with a hello.txt file and check its content.
@test "Hello conf" {
    run_conf hello.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[INFO ] Exec command "echo hello"
[INFO ] Created file "hello.txt"
EOF

    [ -f hello.txt ]
    cat  <<EOF | diff - hello.txt
[SUPPORT-PACK] >>>> echo hello
hello

EOF
}

# Verify that user defined commands are supported in the config file.
@test "User defined command" {
    run_conf user_defined.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[INFO ] Exec command "my_hello"
[INFO ] Created file "hello.txt"
EOF

    [ -f hello.txt ]
    cat  <<EOF | diff - hello.txt
[SUPPORT-PACK] >>>> my_hello
Hello!

EOF
}

# Verify that the "--notgz" option creates a directory and that the path of this
# directory is printed to stdout.
@test "No compression" {
    ${SUPPORT_PACK} ${CONFDIR}/hello.conf --notgz 1>stdout.txt 2>stderr.txt
    [ $? -eq 0 ]
    local dirname="$(cat stdout.txt)"
    dirname="$dirname/${dirname##*/}"
    [ -d "$dirname" ]
    [ -f "$dirname/hello.txt" ]
}

# Test a command that fails and check that support-pack.txt contains traces of
# this.
@test "Failed command conf" {
    run_conf failed_command.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[INFO ] Exec command "command_that_fails"
[ERROR] "command_that_fails" returned a non-zero error code: 1
	-> This is an error
[INFO ] Created file "command_that_fails.txt"
EOF

    [ -f command_that_fails.txt ]
    cat  <<EOF | diff - command_that_fails.txt
[SUPPORT-PACK] >>>> command_that_fails

EOF
}

# Test a command that does not exists.
@test "Unavailable command conf" {
    run_conf unavailable_command.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[ERROR] Command "command_that_doesnt_exists" is not available
[ERROR] "empty.txt" was omitted because it is empty
EOF
    [ ! -f empty.txt ]
}

@test "Copy a file that doesn't exist" {
    run_conf copy_file.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[ERROR] test.txt doesn't exist or is not a regular file.
[ERROR] test.txt doesn't exist or is not a regular file.
EOF
}

@test "Copy a file that exist" {
    echo "Test123" > test.txt
    run_conf copy_file.conf
    [ -f test.txt ]
    [ -f some/directory/file.txt ]
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[INFO ] Copying "test.txt" to "test.txt"
[INFO ] Copying "test.txt" to "some/directory/file.txt"
EOF
}

@test "Copy a file with absolute path" {
    touch /tmp/support_pack_test_file
    run_conf copy_file_abs_path.conf
    [ -f support_pack_test_file ]
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[INFO ] Copying "/tmp/support_pack_test_file" to "support_pack_test_file"
EOF
}

@test "Copy a directory that doesn't exist" {
    run_conf copy_dir.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[ERROR] mydir doesn't exist or is not a directory.
[ERROR] mydir doesn't exist or is not a directory.
EOF
}

@test "Copy a directory that is actually a file" {
    touch mydir
    run_conf copy_dir.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[ERROR] mydir doesn't exist or is not a directory.
[ERROR] mydir doesn't exist or is not a directory.
EOF
}

@test "Copy an empty directory" {
    mkdir mydir
    run_conf copy_dir.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[INFO ] Copying "mydir" to "mydir"
[INFO ] Copying "mydir" to "some/nested/dir/"
EOF
    [ -d mydir ]
    [ ! -d mydir/mydir ]
    [ -d some ]
    [ -d some/nested ]
    [ -d some/nested/dir ]
    [ ! -d some/nested/dir/mydir ]
}

@test "Copy a complex directory structure" {
    mkdir mydir
    touch mydir/a
    touch mydir/b
    mkdir mydir/c
    touch mydir/c/d
    touch mydir/c/e
    ln -sf c/e mydir/link
    run_conf copy_dir.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[INFO ] Copying "mydir" to "mydir"
[INFO ] Copying "mydir" to "some/nested/dir/"
EOF
    [ -d mydir ]
    [ -d mydir/c ]
    [ -d some ]
    [ -d some/nested ]
    [ -d some/nested/dir ]
    [ -d some/nested/dir ]
    [ -d some/nested/dir/c ]
    [ -f mydir/a ]
    [ -f mydir/b ]
    [ -f mydir/c/d ]
    [ -f mydir/c/e ]
    [ -f mydir/link ]
    [ -f some/nested/dir/a ]
    [ -f some/nested/dir/b ]
    [ -f some/nested/dir/c/d ]
    [ -f some/nested/dir/c/e ]
    [ -f some/nested/dir/link ]
}

@test "Copy an absolute path directory" {
    mkdir -p /tmp/support_pack_test_dir
    touch /tmp/support_pack_test_dir/test.txt
    run_conf copy_dir_abs_path.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
[INFO ] Copying "/tmp/support_pack_test_dir" to "support_pack_test_dir"
EOF
    [ -d support_pack_test_dir ]
    [ -f support_pack_test_dir/test.txt ]
}

# If a conf file does not redirect command outputs to log files, the output is
# catched by the support-pack.txt file.
@test "Output to stdout conf" {
    run_conf output_to_stdout.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
echo outside of log file
EOF
}

# If a conf file does not redirect command outputs to log files, stderr output
# is catched by the support-pack.txt file.
@test "Output to stderr conf" {
    run_conf output_to_stderr.conf
    [ -f support-pack.txt ]
    cat  <<EOF | diff - support-pack.txt
echo outside of log file
EOF
}
