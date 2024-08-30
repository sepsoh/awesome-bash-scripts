
# Internet status checker

```
Options:
        -v      verbose
        -d      debug: redirects the used commands to stdout
        -p PING_OPTION=VALUE,.. pass arbitrary switches to pings used in the script, seperated by ',' and wrappen in double qoutes '"'
                reserved switches: (-A, -I, -c, -W) there are other switches to set arbitrary value for -c, -W
        -W TIMEOUT      set value for -W switch of ping
        -c COUNT        set value for -c switch of ping
        -i INTERFACE_IP set value for interface ip, interface self connectivity won't be checked if not set
        -g GATEWAY_IP   set value for gateway ip, if lan connectivity won't be checked if not set

Usage Examples:
        ./internet-status.checker.sh -p "-t=64,-r"      put -t 64 -r before other ping switches
```
