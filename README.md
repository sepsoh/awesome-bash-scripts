# Awesome Bash Scripts

A very lightweight package of bash scripts.

## Install All Scripts

```
chmod +x install.sh
```

```
./install.sh
```

You can also use each script individually.

### After installing you can use this commands for each script :

| Command                                                             | Description                                                              |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| [abs.eye-protector](<Scripts/Eye Protector>)                        | Eye Protector with 20 20 20 algorithm                                    |
| [abs.beautify-ifconfig](<Scripts/Beautify Ifconfig>)                | Display available network interfaces beautifully                         |
| [abs.dns-switcher](<Scripts/DNS Switcher>)                          | Switch DNS providers like a VPN with our interactive DNS Switcher Script |
| [abs.move-and-link](<Scripts/Move And Link>)                        | Move files and link to new path (old path also work)                     |
| [abs.share-file](<Scripts/Share File>)                              | Upload Files on the http://0x0.st and get download link                  |
| [abs.package-files](<Scripts/Package Files>)                        | Get the files of a package and their size                                |
| [abs.abs-update](<Scripts/ABS Update>)                              | Update me to latest version                                              |
| [abs.abs-uninstall](<Scripts/ABS Uninstall>)                        | Uninstall me and delete all sctipts                                      |
| [abs.internet-problem-fixer](<Scripts/Internet Problem Fixer>)      | Detect and fix common internet problems                                  |
| [abs.internet-status.checker.sh](<Scripts/Internet Status Checker>) | Check internet connectivity status                                       |
### Provided Libraries :
| Library                                        | Description                                     |
| ---------------------------------------------- | ----------------------------------------------- |
| [abs.lib.colors](<Libraries/colors>)           | ANSI color codes to style terminal output       |
| [abs.lib.depcheck](<Libraries/depcheck>)       | Functions for verifying system dependencies     |
| [abs.lib.logging](<Libraries/logging>)         | Simple and customizable logging system          |
| [abs.lib.list](<Libraries/list>)               | Functions for manipulating and processing lists |
| [abs.lib.installpkg]((<Libraries/installpkg>)) | Cross platform installation of packages         |
#### Importing Libraries

To use a library in your script, simply source it as shown below:
```bash
# shellcheck source=/usr/bin/abs.lib.somelib
source abs.lib.somelib
```
#### ShellCheck Integration

If you're using ShellCheck for autocompletion/analyse your scripts, specify the library's path to ensure accurate checks(default installation path of ABS is /usr/bin/):
```bash
# shellcheck source=/usr/bin/abs.lib.somelib
source abs.lib.somelib
```

