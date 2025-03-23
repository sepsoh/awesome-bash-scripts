package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/Wifx/gonetworkmanager/v3"
	"github.com/alexflint/go-arg"
	"github.com/godbus/dbus/v5"
)

var args struct {
	No_sleep bool `default:false`
	AccessPoint_Path string `arg:"required"`
	Device_Path string `arg:"required"`
}

const (
	SCAN_SLEEP_NSECS = 3
)

func if_err_log_and_die(err error){
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func is_activeconnection_present(connection gonetworkmanager.ActiveConnection) (bool){
	conn, err := connection.GetPropertyConnection()

	if err != nil {
		return false
	}
	if conn == nil {
		return false
	}
	return true
}

func get_all_wifi_devs(nm gonetworkmanager.NetworkManager) (result []gonetworkmanager.DeviceWireless , err error) {
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

func get_all_access_points(nm gonetworkmanager.NetworkManager)(result []gonetworkmanager.AccessPoint, err error){

	wifi_devices, err := get_all_wifi_devs(nm)
	if err != nil {
		return 
	}
	if (len(wifi_devices) == 0){
		return
	}

	for _, wifi_dev := range wifi_devices{
		wifi_dev.RequestScan()
	}
	if args.No_sleep == false{
		time.Sleep(time.Second * SCAN_SLEEP_NSECS)
	}

	var access_points []gonetworkmanager.AccessPoint
	for _, wifi_dev := range wifi_devices {
		access_points, err = wifi_dev.GetAllAccessPoints()
		if err != nil{
			return 
		}
		result = append(result, access_points...)

	}

	return result, nil
}

func number_generated_for_connection_by_nm(connection gonetworkmanager.ActiveConnection) (int64, error) {

	splited := strings.Split(string(connection.GetPath()), "/")
	str := splited[ len(splited) - 1 ]
	return strconv.ParseInt(str, 10, 64) 

}

func main (){	
	exit_code := 0

	arg.MustParse(&args)
	nm, err := gonetworkmanager.NewNetworkManager()
	if_err_log_and_die(err)

	ap, err := gonetworkmanager.NewAccessPoint(dbus.ObjectPath(args.AccessPoint_Path))
	if_err_log_and_die(err)

	wifi_dev, err := gonetworkmanager.NewDeviceWireless(dbus.ObjectPath(args.Device_Path))
	if_err_log_and_die(err)

	connection := make(map[string]map[string]interface{})

	ssid, err := ap.GetPropertySSID()
	if_err_log_and_die(err)

	connection["802-11-wireless"] = make(map[string]interface{})
	connection["802-11-wireless"]["ssid"] = ssid 

	connection["connection"] = make(map[string]interface{})
	connection["connection"]["id"] = ssid
	connection["connection"]["type"] = "802-11-wireless"

	ifname, err := wifi_dev.GetPropertyInterface()
	connection["connection"]["interface-name"] = ifname

	conn, err := nm.AddAndActivateWirelessConnection(connection, wifi_dev, ap)
	if_err_log_and_die(err)

	time.Sleep(5 * time.Second)
	if_err_log_and_die(err)

	
	connection_success := is_activeconnection_present(conn)
	if_err_log_and_die(err)

	if connection_success == false {
		//TODO delete the setting generated in NetworkManager
		//_ , err:= number_generated_for_connection_by_nm(conn)
		exit_code = 1
		if_err_log_and_die(err)
	}


	if_err_log_and_die(err)
	os.Exit(exit_code)

}
