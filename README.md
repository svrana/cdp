# cdp

## What is it?

cdp is a command line tool that helps you quickly move to directories you use
often. cdp is like CDPATH in that you define a list of directories to search
for the directory you type on the command line. Unlike CDPATH it allows you
to move to an arbitrary depth per path and supplements normal cd usage.


## My configuration

I'm constantly moving into source code that I keep under ~/Projects. I also work
with Go, which wants its code stored in $GOPATH.

```bash
export CDP_DIR_SPEC=~/Projects:2;$GOPATH/src/github.com:3
```

With this configuration cdp will search 2 directories under ~/Projects and 3
directories under $GOPATH/src/github.com for the directory specified on the
command line.

The search for the directory is 'fuzzy', so you need not specify the entire
directory.

### Installation

Define $CDP_DIR_SPEC and source cdp.sh
