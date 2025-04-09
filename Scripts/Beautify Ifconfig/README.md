# Beautify ifconfig
Display of available network interfaces next to IP, netmask and flags related to each one with more readability.

## Usage
`chmod +x beautify-ifconfig.sh`

`./beautify-ifconfig.sh`

## Options
- `--color`: Colorize the output based on interface types:
  - Docker interfaces: Sky Blue
  - Ethernet (eth*): Green
  - Wireless (wlan*/wlp*): Yellow
  - Loopback (lo): Purple
  - Physical network cards (enp*/ens*): Cyan
  - Virtual interfaces and bridges (veth*/br*): Red
  
### Example with color option
`./beautify-ifconfig.sh --color`