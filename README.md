<p align="center">
    <img src="logo.png" height="200"/>
</p>

# `geraup`

## Unix-like

**To install Gera on a UNIX-like system, the following is required:**
- `curl` is present.
- The JVM (version 17+) is present (`java` or the `GERA_JAVA` variable).
- A C compiler is present (`clang`, `gcc`, `cc` or the `GERA_CC` variable).
- Git is present (`git` or the `GERA_GIT` variable).
- `~/.gera` does not exist (this is where it will be installed to).

To then install Gera, simply run the following command:
```
curl https://raw.githubusercontent.com/geralang/geraup/main/install.sh | sh
```

## Windows

### Installation

**To install Gera on Windows, the following is required:**
- `curl` is present.
- `C:\Program Files\Gera` does not exist (this is where it will be installed to).

To then install Gera, do the following:
1. Download `geraup-win.exe` from the latest release.
2. Run the downloaded executable as an administrator.

### Further setup

**To be able to build / run any Gera code, the following is also required:**
- The JVM (version 17+) is present.
- A C compiler is present (if you want to build Gera code with the C target).
- Git is present.

By default, `gerap` will assume that the JVM is available as `java`, the C compiler is available as `cc` and Git is available as `git`. All of these assumptions can be overwritten:
- Specify the path to the JVM using the `GERAP_JAVA_PATH` environment variable
- Specify the path to the C compiler using the `GERAP_CC_PATH` environment variable
- Specify the path to Git using the `GERAP_GIT_PATH` environment variable.