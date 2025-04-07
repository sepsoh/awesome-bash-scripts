package main

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/Wifx/gonetworkmanager/v3"
	"github.com/alexflint/go-arg"
)

const (
	OUPUT_DETAIL_DELIMITER = ","
	SCAN_SLEEP_NSECS = 3
)

var args struct {
	Detailed bool
	No_sleep bool `default:false`
}

func if_err_log_and_die(err error){
	if err != nil{
		fmt.Fprintln(os.Stderr, err.Error())
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



//path,ssid,is_password_protected
func output_accesspoint_based_on_args(access_point gonetworkmanager.AccessPoint) error{
	var print_string string = string(access_point.GetPath())
	if args.Detailed {
		ssid, err := access_point.GetPropertySSID()
		if err != nil {
			return err
		}

		print_string += OUPUT_DETAIL_DELIMITER
		print_string += ssid 

		wpa_flags , err := access_point.GetPropertyWPAFlags()

		print_string += OUPUT_DETAIL_DELIMITER
		print_string += strconv.FormatUint(uint64(wpa_flags), 10)


		if err != nil{
			return nil
		}

	}
	fmt.Println(print_string)
	return nil
}

var nm gonetworkmanager.NetworkManager
func main() {
	arg.MustParse(&args)

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
	if args.No_sleep == false{
		time.Sleep(time.Second * SCAN_SLEEP_NSECS)
	}

	var access_points []gonetworkmanager.AccessPoint
	access_points, err = wifi_devices[0].GetAllAccessPoints()
	if_err_log_and_die(err)

	for _,access_point := range access_points {
		output_accesspoint_based_on_args(access_point)
	}

	os.Exit(0)
}
