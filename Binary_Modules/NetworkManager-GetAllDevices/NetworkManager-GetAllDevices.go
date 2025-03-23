package main

import (
	"fmt"
	"os"
	dbus "github.com/godbus/dbus/v5"
)
	
func main() {
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return
	}
	obj := conn.Object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
	call := obj.Call("org.freedesktop.NetworkManager.GetAllDevices", 0)
	var result []string
	if err := call.Store(&result); err != nil{
		fmt.Fprintln(os.Stderr, err)
		return
	}
	for i := 0 ; i < len(result); i++{
		fmt.Println(result[i])
	}
}
