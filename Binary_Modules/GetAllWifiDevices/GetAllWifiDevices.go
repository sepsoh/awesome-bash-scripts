package main

import (
	"fmt"
	"os"
	"github.com/Wifx/gonetworkmanager/v3"
)

func if_err_log_and_die(err error){
	if err != nil {
		fmt.Println(err.Error())
		os.Exit(1)
	}
}

func main (){
	nm, err := gonetworkmanager.NewNetworkManager()
	if_err_log_and_die(err)

	devices, err := nm.GetAllDevices()
	if_err_log_and_die(err)

	for i := 0; i < len(devices); i++{
		device_type, err := devices[i].GetPropertyDeviceType()
		if_err_log_and_die(err)

		if device_type == gonetworkmanager.NmDeviceTypeWifi{
			fmt.Println(devices[i].GetPath())
		}	
	}
}
