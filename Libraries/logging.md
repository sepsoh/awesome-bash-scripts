# Logging
## log(lvl,msg,dst=&1)
logs the message if CURRENT_LOG_LVL <= lvl

```bash
#log a message
log $LOG_LVL_INFO "[$0]: some msg" #better to have $0 in your logs
#log a message to ~/somefile
log $LOG_LVL_INFO "[$0]: some msg" "~/somefile"
```

## Log levels
Log levels are:
```bash
LOG_LVL_DEBUG=0
LOG_LVL_INFO=10
LOG_LVL_WARNING=20
LOG_LVL_ERROR=30
LOG_LVL_CRITICAL=40
```
You should not pass a number directly to `log`.



## set_log_lvl(string_lvl)
string_lvl: either of "debug", "info", "warning", "error", "critical"
```bash
#setting log level
set_log_lvl "debug"
#or simply
CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
```

## Removing times from logs
```
DATE_FMT=""
```

## setting another color for a log level
colors are imported from abs.lib.colors
```
LOG_CLR_CRITICAL=$Cyan
```

