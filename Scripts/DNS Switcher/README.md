# DNS Switcher Script

This script allows you to easily switch between different DNS providers on your system. The script is interactive and allows you to choose from a list of DNS options using a simple menu interface.

## Features

- Switch DNS settings to popular providers including Shecan, Electro, Begzar, Google, 403, CloudFlare, and Radar.
- Restore the default DNS setting.
- Easy-to-use menu interface for selecting the desired DNS.
- Real-time update of `/etc/resolv.conf` to apply the chosen DNS settings.
- Displays the current DNS configuration by name.

## Usag

1. **Make the Script Executable:**

   ```bash
   chmod +x dns_switcher.sh
   ```

2. **Run the Script:**

   ```bash
   sudo ./dns_switcher.sh
   ```

   **Note:** Running the script with `sudo` is necessary to modify `/etc/resolv.conf`.

## Menu Options

The script provides the following DNS options:

- **Shecan**
- **Electro**
- **Begzar**
- **Google**
- **403**
- **CloudFlare**
- **Radar**
- **Default**

Navigate through the menu using the arrow keys and press Enter to select the desired DNS.

## Example

Upon running the script, you will see a menu like this:

```bash
Current DNS Configuration: Google

Which DNS do you want to use?
   Shecan
   Electro
   Begzar
   Google
-> 403
   CloudFlare
   Radar
   Default
```

Use the arrow keys to navigate through the options. The selected option will be highlighted in blue. Press `Enter` to set the DNS.

## Code Overview

### Variables

- **DNS Addresses:** Defined at the beginning of the script.
- **Options Array:** Contains the names of the DNS providers.
- **DNS Lists:** Two lists (`dns1_list` and `dns2_list`) hold the primary and secondary DNS addresses.

### Functions

- **print_menu:** Displays the interactive menu and highlights the selected option.
- **Main Loop:** Handles user input for navigating the menu and selecting an option.
- **Set DNS:** Updates `/etc/resolv.conf` with the chosen DNS settings.

## Author

Developed by [MrMeshky](https://github.com/mr-meshky) with love.
