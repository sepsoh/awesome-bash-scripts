# Purpose Of This Directory
This directory contains binary modules that enable scripts to perform complex tasks.  
# Why File Names in Binary Modules Are In Pascal Case?
The reason for this is binary modules initial offered capabilities (if not all) is to facilitate using various dbus APIs on linux. Methods exposed via dbus are typically (if not always) in pascal case, so we kept it for better readability.
# Modules With Prefix 'NetworkManager-*'
These modules directly map to a method offered by NetworkManager.

