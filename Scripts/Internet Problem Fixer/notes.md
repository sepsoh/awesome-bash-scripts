# current priorities:    
- dynamic sleep for dhclient and monitor if route table is updated    
- VPN detection and asking the user to turn it off    
- detect and igore VPN interfaces by default  
- need to seperate protocol availability, and connectivity to different segments of networks  
- need to be able to interpret icmp responses (destination forbidden/unreachable)    
- use abs.lib for logging and dependancy checks  
# things to check for in the future    
- check default route src ip ( need to ping that ip specifically )    
- check mtu    
- check ttl ( router might be misinformed based on incorrect ttl )    
- check if icmp works    
- check if tcp works    
- check if port 80 works    
- detect if dhclient didnt managed to renew the ip    
- if icmp is not available:    
    -test tcp and http      
    
    
    
# things to keep in mind    
- if intranet,internet is not reachable:    
    - check routing table ( wrong default gateway )    
    - check for forbidden icmp response    
    
- if default gateway is reachable:    
    - ttl is ok    
    - mtu os ok    
    - private ip is probably ok    
- if a protocol works and the others don't it's problem is either of these    
    - firewall    
    - VPN    
    - ISP ( reboot default gateway )    
- if vpn interface cant reach default vpn gw but lan is ok    
    - try turn off the vpn and test    
  
    
  

