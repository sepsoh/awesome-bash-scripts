# Global Variables    
- `DEP_ATTR_DELIM`: The default delimiter for dependency attributes (default: `","`).  
- `DEP_NAME_POS`: The position of the dependency name in the attribute string (default: `1`).  
- `DEP_CMD_POS`: The position of the dependency command in the attribute string (default: `2`).  
  
---  
  
# Functions  
  
## depcheck_cmd  
  
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
# dns-utils,dig  
# git,git  
# nodejs,node
#   |      |
#   |      |----> command to check if this package is present
#   |-----------> name of the package (may be used to install the package if missing)
depcheck_cmd "deps.txt"  
```  
  
---  

## depcheck_cmd_fromstr   
  
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
nodejs,node
unzip,unzip"

if ! depcheck_cmd_fromstr "$dependancies"; then
		exit $? #if dependancies are not met, exit
fi  
```  
  
---  
  
## depcheck_lib (TODO)  
  
**Purpose**:  
Placeholder for a function to check library dependencies. Currently not implemented.  
  
**Behavior**:  
Logs a message indicating that the function is not implemented and exits with an error status.  
  
**Example**:  
```bash  
depcheck_lib  # Outputs: "not implemented yet"  
```  
  
---  
  
## \_dep_attr_extract  
  
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
name=$(_dep_attr_extract "nodejs,node" $DEP_CMD_POS)  
echo $name  # Outputs: node  
```  


