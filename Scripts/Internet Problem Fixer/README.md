# Internet problem fixer
```
Options:
        -v      verbose
        -d      debug: redirects the used commands to stdout
        -n      no fix: don't try to fix ( eliminate the requirement for the script to be root )
        -i INTERFACE_NAMES      include interface: troubleshoot the provided interfaces only if used -x will be ignored
        -x INTERFACE_NAMES      exclude interface: ignore the provided interfaces
        -p PING_OPTION=VALUE,.. pass arbitrary switches to pings used in the script, seperated by ',' and wrappen in double qoutes '"'
                reserved switches: (-A, -I, -c, -W) there are other switches to set arbitrary value for -c, -W
        -W TIMEOUT      set value for -W switch of ping
        -c COUNT        set value for -c switch of ping

Usage Examples:
        ./internet-problem-fixer.sh -i eth0,wlan0       troubleshoots only eth0 and wlan0 interfaces
        ./internet-problem-fixer.sh -n -i eth0  doesn't try to fix eth0 just shows the states instead
        ./internet-problem-fixer.sh -x tun0,lo  ignore tun0 and lo
        ./internet-problem-fixer.sh -p "-t=64,-r"       put -t 64 -r before other ping switches
 ```
