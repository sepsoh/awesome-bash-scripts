# Functions  
## depcheck_cmd  
### Description  
Reads dependencies from a file and checks if each dependency is available in the system using `type`.  
Each line should include both the package name of the dependancy and the command to test for availablility  
Each entry should be in the format of (name${delim}cmd), so with the default delim ----> (name,cmd)  
Use this function if the dependancy provides a command, if not, use depcheck_lib()  
### Parameters:  
- $1 - Filename containing dependencies.  
- $2 - Dependency attribute delimiter (default: ,).  
### Examples of Dependency file  
```  
zsh,zsh  
netcat,nc  
joplin,joplin-desktop  
cronie,crontab  
dns-utils,dig  
```  
  
## depcheck_lib  
TODO  
  

