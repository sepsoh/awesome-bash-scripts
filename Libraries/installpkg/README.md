# abs.lib.installpkg

This script tries to provide cross platform installation of packages and updating the package manager's database.

## Currently supported package managers
- apt  
- apt-get  
- pacman  

## Limitations
This script works only if the provided packages names are available on the machine it is being executed, and it won't try to convert package names that are different in multiple linux distributions.

## Quick start

```bash
source abs.lib.installpkg
installpkg iproute2 python3 # install iproute2 and python3
```
