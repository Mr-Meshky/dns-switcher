# DNS Switcher Script

This script allows you to easily switch between different DNS providers on your system. The script is interactive and allows you to choose from a list of DNS options using a simple menu interface.

## Features

- Switch DNS settings to popular providers including Shecan, Electro, Begzar, Google, 403, CloudFlare, and Radar.
- Restore the default DNS setting.
- Easy-to-use menu interface for selecting the desired DNS.
- Real-time update of `/etc/resolv.conf` to apply the chosen DNS settings.
- Displays the current DNS configuration by name.

## Usage

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/Mr-Meshky/dns-switcher.git
   cd dns-switcher
   ```

2. **Install the Script:**

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **Run the Script:**

   ```bash
   change-dns
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

## Updating the Repository

To update the repository, use the provided `update.sh` script. The script checks if the current directory is a Git repository, and if so, it pulls the latest changes. If not, it checks for the existence of the `dns-switcher` directory, navigates into it if it exists, and pulls the latest changes. If the directory does not exist, it clones the repository.

### Running the Update Script

1. **Make the Script Executable:**

   ```bash
   chmod +x update.sh
   ```

2. **Run the Script:**

   ```bash
   ./update.sh
   ```

## Contributing

Feel free to submit issues and pull requests for new features or improvements. Your contributions are welcome!

## Author

Developed by [MrMeshky](https://mrmeshky.ir) with love.
