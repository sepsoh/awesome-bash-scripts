package main

import (
	"time"
	"fmt"
	"github.com/Wifx/gonetworkmanager/v3"
	"os"
)

const SCAN_SLEEP_NSECS = 2

func if_err_log_and_die(err error){
	if err != nil{
		fmt.Println(err.Error())
		os.Exit(1)
	}
}

func get_all_wifi_devs() (result []gonetworkmanager.DeviceWireless , err error) {
	var devices []gonetworkmanager.Device
	devices, err = nm.GetPropertyAllDevices()
	if err != nil {
		return
	}

	var device_type gonetworkmanager.NmDeviceType
	for _, device := range devices {
		device_type, err = device.GetPropertyDeviceType()
		if err != nil {
			return
		}	
		if device_type != gonetworkmanager.NmDeviceTypeWifi {
			continue
		}

		to_wifi, err:= gonetworkmanager.NewDeviceWireless(device.GetPath())
		if err != nil {
			continue
		}
		result = append(result, to_wifi)
	}
	
	return 
}

var nm gonetworkmanager.NetworkManager
func main() {

	/* Create new instance of gonetworkmanager */
	var err error
	nm, err = gonetworkmanager.NewNetworkManager()
	if_err_log_and_die(err)

	wifi_devices, err := get_all_wifi_devs()
	if_err_log_and_die(err)
	if (len(wifi_devices) == 0){
		return
	}

	wifi_devices[0].RequestScan()
	time.Sleep(SCAN_SLEEP_NSECS)

	var access_points []gonetworkmanager.AccessPoint
	access_points, err = wifi_devices[0].GetAllAccessPoints()
	if_err_log_and_die(err)

	var device_state gonetworkmanager.NmDeviceState
	device_state, err = wifi_devices[0].GetPropertyState()
	if_err_log_and_die(err)

	fmt.Println(device_state)
	
	for _,access_point := range access_points {
		fmt.Println(access_point.GetPath())
	}

	

	/* Show each device path and interface name */

	os.Exit(0)
}
