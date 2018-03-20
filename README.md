# cdp

## What is it?

cdp is a command line tool that helps you quickly move to directories you use
often. cdp is like CDPATH in that you define a list of directories to search
for the directory you type on the command line. Unlike CDPATH it allows you
to move to an arbitrary depth per path and supplements normal cd usage but does
not change it.

## Requirements

  * Bash
  * [fd](https://github.com/sharkdp/fd)


## Installation

Clone this repo somewhere and `source cdp.sh`. Or just

```
curl https://raw.githubusercontent.com/svrana/cdp/master/cdp.sh > cdp.sh
source cdp.sh
```

## Configuration

Set the CDP_DIR_SPEC environment variable. CDP_DIR_SPEC is a list of directories
to search and the maximum depth to search in each directory for a match.

For example, if you define CDP_DIR_SPEC like I do:

```bash
export CDP_DIR_SPEC=~/Projects:2;$GOPATH/src/github.com:3
```

Then if you type `cdp go-immutable` you will find yourself in $GOPATH/src/github.com/hashicorp/go-immutable-radix
assuming such a directory exists on your filesystem. Note that search is fuzzy and the first found match is
returned.
