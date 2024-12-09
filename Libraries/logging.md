# Logging
```bash
#log a message
log $LOG_LVL_INFO "some msg"
#log a message to ~/somefile
log $LOG_LVL_INFO "some msg" "~/somefile"

#setting log level
set_log_lvl "debug"
#or
CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG

#setting another color for a log level
LOG_CLR_CRITICAL=$Cyan
```

Log levels are:

```bash
LOG_LVL_DEBUG=0
LOG_LVL_INFO=10
LOG_LVL_WARNING=20
LOG_LVL_ERROR=30
LOG_LVL_CRITICAL=40
```
You should not pass a number directly to `log`.


