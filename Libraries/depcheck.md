# Dependency Check Script  
  
This script provides functions for verifying system dependencies, particularly for Bash-based environments. It supports checking for both commands and library dependencies (library checking is not yet implemented).  
  
---  
  
## Features  
  
1. **Command Dependency Verification**:  
   - Checks if required commands are available in the system.  
   - Reads dependencies from a file and tests their presence using the `type` command.  
  
2. **Flexible Dependency Format**:  
   - Supports custom delimiters for specifying dependency attributes.  
  
3. **Logging Integration**:  
   - Logs messages at various levels (e.g., ERROR, DEBUG) using the integrated logging library (`abs.lib.logging`).  
  
---  
  
## Prerequisites  
  
- Bash shell environment.  
- The `abs.lib.logging` library for logging functionality.  
  
---  
  
## Usage  
  
### Global Variables  
  
#### Dependency Format Settings:  
- `DEP_ATTR_DELIM`: The default delimiter for dependency attributes (default: `","`).  
- `DEP_NAME_POS`: The position of the dependency name in the attribute string (default: `1`).  
- `DEP_CMD_POS`: The position of the dependency command in the attribute string (default: `2`).  
  
---  
  
### Functions  
  
#### 1. `depcheck_cmd(filename, dep_attr_delim=",")`  
  
**Purpose**:  
Reads dependencies from a file and checks if each dependency’s command is available in the system.  
  
**Parameters**:  
1. `filename`: The file containing dependencies (each line formatted as `"name,cmd"`).  
2. `dep_attr_delim` (Optional): The delimiter for separating dependency attributes (default: `","`).  
  
**Behavior**:  
- Reads the file line by line.  
- Extracts the command using `_dep_attr_extract`.  
- Checks if the command is available using `type`.  
- Logs errors for missing dependencies.  
  
**Example**:  
```bash  
# Contents of deps.txt:  
# curl,curl  
# git,git  
  
depcheck_cmd "deps.txt"  
```  
  
---  

#### 2. `depcheck_cmd_fromstr(str, dep_attr_delim=",")`  
  
**Purpose**:  
Reads dependencies from a file and checks if each dependency’s command is available in the system.  
  
**Parameters**:  
1. `str`: The string containing dependencies (each line formatted as `"name,cmd"`).  
2. `dep_attr_delim` (Optional): The delimiter for separating dependency attributes (default: `","`).  
  
**Behavior**:  
similar to depcheck_cmd()

**Example**:  
```bash  
dependancies="\
curl,curl
unzip,unzip"

if ! depcheck_cmd_fromstr "$dependancies"; then
		exit $? #if dependancies are not met, exit
fi  
```  
  
---  
  
#### 2. `depcheck_lib()` (TODO)  
  
**Purpose**:  
Placeholder for a function to check library dependencies. Currently not implemented.  
  
**Behavior**:  
Logs a message indicating that the function is not implemented and exits with an error status.  
  
**Example**:  
```bash  
depcheck_lib  # Outputs: "not implemented yet"  
```  
  
---  
  
#### 3. `_dep_attr_extract(dep, pos, delim=",")`  
  
**Purpose**:  
Extracts a specific attribute from a dependency string based on its position and delimiter.  
  
**Parameters**:  
1. `dep`: The dependency string (e.g., `"name,cmd"`).  
2. `pos`: The position of the attribute to extract (e.g., `1` for name, `2` for command).  
3. `delim` (Optional): The delimiter separating attributes (default: `","`).  
  
**Returns**:  
The extracted attribute as a string.  
  
**Example**:  
```bash  
name=$(_dep_attr_extract "nodejs,node" $DEP_NAME_POS)  
echo $name  # Outputs: node  
```  
  
---  
  
## Dependency File Format  
  
The dependency file should contain one dependency per line, formatted as:  
```  
name,cmd  
```  
Where:  
- `name` is the dependency’s human-readable name.  
- `cmd` is the command used to verify the dependency’s presence.  
  
**Example File (deps.txt)**:  
```  
dns-utils,dig  
git,git  
nodejs,node  
```  
  
---  
  
## Notes  
  
1. **Custom Delimiters**:  
   - If your dependency attributes use a different delimiter (e.g., `":"`), specify it when calling `depcheck_cmd`.  
  
2. **Error Handling**:  
   - The script logs missing dependencies and returns an error status if any are not found.  
  
3. **Library Dependency Checking**:  
   - The `depcheck_lib` function is a placeholder and needs implementation.  
  
  
  

