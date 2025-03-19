package main

import "fmt"
import dbus "github.com/godbus/dbus/v5"
	
func main() {
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		fmt.Println("err")
		fmt.Println(err)
		return
	}
	obj := conn.Object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
	call := obj.Call("org.freedesktop.NetworkManager.GetAllDevices", 0)
	var result []string
	if err := call.Store(&result); err != nil{
		fmt.Println(err)
		return
	}
	for i := 0 ; i < len(result); i++{
		fmt.Println(result[i])
	}
}
