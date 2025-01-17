# Functions

## Package manager functions
Function names consist of two parts, one that refers to the package manager that is being operated on, and the second refers the specific operation to be done on that package manager.  

The part that refers two the package manager always start with an underscore (`_`) and then the exact command of the package manager is placed after.

For the second part, `_install` and `_update` are currently implemented.
**Parameters**
The parameteres passed to package manager functions depends solely on the operation of the function.

`_update` functions don't take any parameters  
`_install` functions take package names to be installed, as seperate arguments.

**Example**
`_pacman_install iproute2 python3` installs python3 and iproute2 using pacman
`_apt-get_update` updates the database of apt-get  


## \_package_manager_func_to_use()
**Purpose**  
Echos the function prefix that works with current machines package manager.  

**Bhavior**
Checks for existance of package managers, and echos the function to use the one with the highest priority.

Current priority of package managers:
1. apt
2. apt-get
3. dpkg (not implemented)
4. pacman
5. rpm (not implemented)
6. dnf (not implemented)

## installpkg()
**Purpose**
Install a package using the provided function by `_package_manager_func_to_use`.  

**Parameters**
Package names to be installed, as seperate arguments.  


**Example**
```bash
installpkg iproute2 python3 #install iproute2 and python3
```
