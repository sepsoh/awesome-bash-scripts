# abs.lib.logging  
  
This script provides a simple and customizable logging system for Bash scripts. It allows for log level control, color-coded messages, and destination management.  
  
---  
  
## Features  
  
1. **Log Level Control**:  
   - Supports five log levels: `DEBUG`, `INFO`, `WARNING`, `ERROR`, and `CRITICAL`.  
   - The current log level can be dynamically updated.  
  
2. **Color-Coded Messages**:  
   - Each log level is associated with a distinct color for better visibility.  
  
3. **Customizable Output**:  
   - Messages can be sent to a specified file descriptor.  
  
4. **Timestamps**:  
   - Logs include timestamps for traceability.  
  
---  
  
## Prerequisites  
  
- Bash shell environment.  
- The `abs.lib.colors` library for color definitions.  
  
---  
  
## Usage  
  
### Global Variables  
  
#### Log Levels:  
- `LOG_LVL_DEBUG` = 0  
- `LOG_LVL_INFO` = 10  
- `LOG_LVL_WARNING` = 20  
- `LOG_LVL_ERROR` = 30  
- `LOG_LVL_CRITICAL` = 40  
  
#### Log Colors:  
- `LOG_CLR_DEBUG` = Cyan  
- `LOG_CLR_INFO` = White  
- `LOG_CLR_WARNING` = Yellow  
- `LOG_CLR_ERROR` = Red  
- `LOG_CLR_CRITICAL` = Bright Red  
  
#### Default Settings:  
- `CURRENT_LOG_LVL` = `LOG_LVL_INFO`  
- `DEFAULT_LOG_DST` = `1` (stdout)  
- `DATE_FMT` = `"%Y-%m-%d %H:%M:%S"`  
  
---  
  
### Functions  
  
#### 1. `log(lvl, msg, dst=&1)`  
  
**Purpose**:  
Logs a message if the current logging level is less than or equal to the provided log level.  
  
**Parameters**:  
1. `lvl`: The numeric log level of the message (`LOG_LVL_DEBUG`, `LOG_LVL_INFO`, etc.).  
2. `msg`: The message to log.  
3. `dst` (Optional): The file descriptor to log to (default: stdout).  
  
**Behavior**:  
- Logs the message to the specified destination if `CURRENT_LOG_LVL <= lvl`.  
- The log message is color-coded and includes a timestamp.  
  
**Example**:  
```bash  
log $LOG_LVL_WARNING "This is a warning!"  
log $LOG_LVL_DEBUG "This is debug information" 2  # Logs to stderr  
```  
  
---  
  
#### 2. `set_log_lvl(string_lvl)`  
  
**Purpose**:  
Sets the current logging level based on a string input.  
  
**Parameters**:  
- `string_lvl`: The log level to set. Must be one of the following:  
  - `"debug"`  
  - `"info"`  
  - `"warning"`  
  - `"error"`  
  - `"critical"`  
  
**Behavior**:  
- Updates the `CURRENT_LOG_LVL` variable to match the corresponding numeric log level.  
- If an invalid level is passed, no changes are made, and the function exits silently.  
  
**Example**:  
```bash  
set_log_lvl "debug"  
```  
  
---  
  
#### 3. `log_lvl_to_color(log_lvl)`  
  
**Purpose**:  
Converts a numeric log level to its corresponding color code.  
  
**Parameters**:  
- `log_lvl`: The numeric log level.  
  
**Returns**:  
- The color code associated with the provided log level.  
  
**Behavior**:  
- Prints the appropriate color code for the given log level to stdout.  
  
**Example**:  
```bash  
color=$(log_lvl_to_color $LOG_LVL_WARNING)  
echo "$color"  # Outputs: Yellow  
```  
  
---  
  
## Notes  
  
1. **Custom Timestamps**:  
   - Modify the `DATE_FMT` variable to customize the timestamp format.  
   - Set `DATE_FMT=""` to remove timestamps from log messages.  
  
2. **Error Handling**:  
   - Ensure all numeric log levels and color codes are correctly defined.  
  
3. **Default Destination**:  
   - If `dst` is not specified, logs are sent to `stdout` by default.  
  
  

