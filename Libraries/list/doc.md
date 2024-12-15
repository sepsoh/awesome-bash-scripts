# Functions
## remove_list_from_list
  
### Description:  
Removes all occurrences of elements in a `remove_list` from a `list`. Both lists are provided as single strings with delimiters.  
  
### Parameters:  
1. `list` The main list as a single string.  
2. `list_delimiter`: The delimiter separating elements in the main list.  
3. `remove_list`: A list of elements to remove, provided as a single string.  
4. `remove_list_delimiter`: The delimiter separating elements in the `remove_list`.  
  
### Returns:  
- The updated list with elements from `remove_list` removed.  
  
### Example:  
```bash  
list="apple,banana,orange,grape"  
remove_list="banana,grape"  
updated_list=$(remove_list_from_list "$list" "," "$remove_list" ",")  
echo "$updated_list"  # Outputs: apple,orange,  
```  
  
---  
  
## scape_sed_special_chars  
### Description  
Escapes special characters in a string so that it can be safely used in `sed` commands.  
  
### Parameters:  
`string_to_scape`: The string to process.  
  
### Returns:  
The input string with `sed` special characters escaped.  
  
### Example:  
```bash  
escaped_string=$(scape_sed_special_chars "example/string.*to^escape")  
echo "$escaped_string"  # Outputs: example\/string\.\*to\^escape  
```  
  
---  
  
# Notes  
- Both functions automatically escape special characters in input strings and delimiters to prevent errors.  
- The script does not handle cases where the delimiters themselves appear as list elements.  
  
