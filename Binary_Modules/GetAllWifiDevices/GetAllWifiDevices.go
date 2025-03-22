package main

import (
	"fmt"
	"os"
	"github.com/Wifx/gonetworkmanager/v3"
	"github.com/alexflint/go-arg"
)

const (
	detail_delim = ","
)
var args struct {
	Detailed bool
}

func if_err_log_and_die(err error){
	if err != nil {
		fmt.Println(err.Error())
		os.Exit(1)
	}
}

func output_device_based_on_args(device gonetworkmanager.Device) error {
	print_string := string(device.GetPath())

	if args.Detailed {
		ifname, err := device.GetPropertyInterface()
		if err != nil {
			return err
		}
		print_string += detail_delim
		print_string += ifname
	}
	fmt.Println(print_string)
	return nil
}

func main (){
	arg.MustParse(&args)

	nm, err := gonetworkmanager.NewNetworkManager()
	if_err_log_and_die(err)

	devices, err := nm.GetAllDevices()
	if_err_log_and_die(err)

	for i := 0; i < len(devices); i++{
		device_type, err := devices[i].GetPropertyDeviceType()
		if_err_log_and_die(err)

		if device_type == gonetworkmanager.NmDeviceTypeWifi{
			_ = output_device_based_on_args(devices[i])
		}	
	}
}
