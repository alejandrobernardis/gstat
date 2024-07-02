% GSTAT(1) gstat user manual
% Written by Alejandro M. BERNARDIS <alejandro.bernardis@gmail.com>
% July 2024

# NAME

**gstat(1)** - Show summary changes for multiple git repositories.

# SYNOPSIS

 **gstat** (*option*) [*PATH*...]

# DESCRIPTION

**gstat(1)** was created to solve the daily dynamics of finding outstanding issues in local repositories, many of the expected statuses will not be resolved (*You can feel free to make any change*).

**The current statuses are:**

- **Push**: if a branch is following a (remote) branch **behind** it.
- **Pull**: if a branch is following a (remote) branch **ahead** it.
- **Upstream**: if a branch does not have a local or remote **upstream** branch configured.
- **Uncommitted**: if there are **uncommitted** changes pending in the local repository.
- **Staged**: if there are **staged** changes in the local repository.
- **Stashes**: if there are **saved** changes in the local repository.
- **Untracked**: if there are **untracked** files that are not ignored in the local repository.
- **Conflicts**: if there are **conflicts** pending in the current branch.

If you run in **check mode** (`-c`) it will show you all repositories that are **Ignored** (`gstat.ignore=true`), **Locked** (`.git/index.lock`) or **Insecure** (`non-owner`).

# OPTIONS

## Common Options:

**-h, --help**
: Print a help message and exit

**-V, --version**
: Display version information and exit

**-x, --debug**
: Run in debug mode

**-c, --check**
: Run in check mode

**-d, --depth** ***\<value\>***
: Descend to N directory levels below the starting points

**-D, --no-depth**
: Do not drill down into directory levels

**-X, --no-cache**
: Do not use existing cached

**-E, --no-environ**
: Do not use existing environment variables

## Git Options:

**-f, --fetch**
: Updates the repository before displaying the status

## Verbose Options:

**-v, --verbose**
: Show all repositories

**-w, --warnings**
: Show the repositories with alerts

**-P, --no-pull**
: Ignore pulls

**-H, --no-push**
: Ignore pushes

**-U, --no-upstream**
: Ignore upstreams

**-M, --no-uncommitted**
: Ignore uncommitted changes

**-G, --no-staged**
: Ignore staged changes

**-S, --no-stashes**
: Ignore stashes changes

**-C, --no-conflicts**
: Ignore conflicts

**-T, --no-untracked**
: Ignore untracked files

# ENVIRONMENT

## Common

**GSTAT_CACHE_PATH**
: Path to persist cache. Allowed values: **string**. Default value: `/tmp`.

**GSTAT_CACHE_PREFIX**
: Cache file name prefix. Allowed values: **string**. Default value: `gstat_cache_`.

**GSTAT_CACHE_TTL**
: Cache lifetime (Time to Live) expressed in seconds. Allowed values: **+0** (*positive integers*).

**GSTAT_DEPTH**
: Descend to N directory levels below the starting points. Allowed values: **+0** (*positive integers*).

**GSTAT_NO_DEPTH**
: Do not drill down into directory levels. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_NO_CACHE**
: Do not use existing cached. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_FETCH**
: Before displaying the status, update repository. Allowed values: **0** (*false*), **1** (*true*).

## Verbose Options

**GSTAT_VERBOSE**
: Show all repositories. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_WARNINGS**
: Show the repositories with alerts. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_NO_PULL**
: Ignore pulls. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_NO_PUSH**
: Ignore pushes. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_NO_UPSTREAM**
: Ignore upstreams. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_NO_UNCOMMITTED**
: Ignore uncommitted changes. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_NO_STAGES**
: Ignore stages changes. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_NO_STASHES**
: Ignore stashes changes. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_NO_CONFLICTS**
: Ignore conflicts. Allowed values: **0** (*false*), **1** (*true*).

**GSTAT_NO_UNTRACKED**
: Ignore untracked files. Allowed values: **0** (*false*), **1** (*true*).

# FILES

**gstat.conf**
: **gstat** configuration file.

**Alternative paths:**

```bash
"${HOME}/.gstat.conf"
"${HOME}/.config/gstat/gstat.conf"
"${HOME}/.local/etc/gstat.conf"
"/usr/local/etc/gstat/gstat.conf"
"/usr/etc/gstat/gstat.conf"
"/etc/gstat/gstat.conf"
```

# SOURCE

Follow the link to get the source code https://github.com/alejandrobernardis/gstat

# BUGS

Report bugs in https://github.com/alejandrobernardis/gstat/issues

# EXAMPLES

To check repositories status [i.e.]:

```bash
gstat
```

To more verbosity use `-v` option [i.e.]:

```bash
gstat -v
```

To check repositories [i.e.]:

```bash
gstat -c
```

To more verbosity, increment the argument option (`-c`) one character (`-cc`) [i.e.]:

```bash
gstat -cc
```

To ignore a repository, add the `gstat.ignore=true` configuration option for each repository [i.e.]:

```bash
git config --local --bool gstat.ignore true
```

To ignore the environment configuration, increment the argument option (`-A`) one character (`-AA`) [i.e.]:

```bash
gstat -MM
```

# LICENSE

**gstat(1)** is made available under the terms of the **MIT** License. See the **LICENSE** <https://raw.githubusercontent.com/alejandrobernardis/gstat/main/LICENSE> file for license details.

# COPYRIGHT

Copyright (c) since 2024 **Alejandro M. BERNARDIS**.

# SEE ALSO

**git(1)**, **git-status(1)**
