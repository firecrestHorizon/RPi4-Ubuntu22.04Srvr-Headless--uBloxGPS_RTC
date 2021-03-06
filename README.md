# Building a RaspberryPi4 with uBlox GPS-RTC on Ubuntu 22.04 Server

Aim of this project is to build a simple GNSS receiver, running on a RaspberryPi, that could then be used as a development test rig for GNSS applications.

## Basic Setup Procedure

1. Assemble the RPi and GNSS receiver board
2. Flash Ubuntu 22.04 LTS Server to microSD
3. Configure Ubuntu Server for headless setup and remote access using SSH
4. Configure I2C and serial/UART on RPi
5. Configure Ubuntu to use GNSS board's external real-time clock (RTC) and remove fake-hwclock
6. Test/check messages from the uBlox GNSS receiever

## Additional Setup Procedure

To use this RPI/GNSS as a development test rig it is useful to install a programming language (I am using Swift) and to perform some additional configuration steps.

This guide will also show how to configure the system so that we can edit code on a MacBook using Xcode, being able to keep the full benefit of the Xcode IDE.

1. Install Swift for ARM
2. (Optional) Install git
3. Configure network sharing with Samba
4. Connect to the network share on the RPi from macOS
5. Create a `helloGPS` application, on macOS
6. Compile and run `helloGPS` on RPi

---

## Basic Setup

### Equipment

The equipment used for this guide is:

- RaspberryPi 4 Model B, with power supply
- RaspberryPi GPS/RTC Expansion Board
- Active GPS Antenna (with SMA Connector)
- microSD card (16GB min, suggested 32GB)
- microSD card reader
- PC/laptop, connected to your WiFi

There are many GPS expansion boards and antennas available for the RPi, the GPS/RTC expansion board and GPS antenna used in this guide are:

- **Uputronics RPi GPS-RTC Expansion Board** available from [PiHUT](https://thepihut.com/collections/raspberry-pi-gps-gsm-lora-hats/products/raspberry-pi-gps-hat) or direct from [Uputronics](https://store.uputronics.com/index.php?route=product/product&path=60_64&product_id=81).  I am actually using a slightly older version of this expansion board (without the USB-C header connector) but the procedure should be the same with the more modern version of the board.
- **uBlox Multi-Band Active GPS Patch Antenna**.  Being multi-band (GPS/Galileo/GLONASS/BeuDou) this antenna is slightly more expensive that the single-band (GPS-only) versions, either antenna should work.  Multi-band antenna available from [Uputronics](https://store.uputronics.com/index.php?route=product/product&path=60_65&product_id=120).  Single-band antennas available from [PiHUT](https://thepihut.com/products/gps-antenna-external-active-antenna-3-5v-28db-5-meter-sma) or [Uputronics](https://store.uputronics.com/index.php?route=product/product&path=60_65&product_id=67).

### Assemble the Hardware

For my setup I decided to buy a case to hold my RPi and GPS expansion board, not necessary for this project but it does help keep all the parts held together and saves possible damage.

![Project Hardware Parts](./images/IMG_1949.png)

The purchased my case from PiHut, [GPS HAT Case for RPi](https://thepihut.com/products/gps-hat-case-for-raspberry-pi-4)

The final assembly.

![Project Hardware Assembled](./images/IMG_1948.png)

### Flash Ubuntu 22.04 Server to microSD

I used the offical Raspberry Pi Imager app to flash an OS to the microSD card, available from [raspberrypi.com/software](https://www.raspberrypi.com/software/).  Other flash applications are available, such as [balenaEtcher](https://www.balena.io/etcher/), the process to flash the OS will be very similar.

![RPi Imager](./images/RPi_imager.png)

For the OS I don't want the overhead of a desktop on the RPi but I want to make the most of the 64-bit architecture on the RPi so will use Ubuntu Server 22.04 LTS (RPi 4, 64-bit).  

- Connect the SD card reader to your laptop and insert a blank microSD card.
**N.B.** If the microSD card is not blank, flashing the OS to the SD card will completely overwrite any data on the card.

On the RPi Imager app click...

- Choose OS
- Other general-purpose OS
- Ubuntu
- Ubuntu Server 22.04 LTS (RPi Zero/2/3/4/400), 64-bit for arm64

![Ubuntu Server 22.04 LTS](./images/RPi_imager_SelectedOS.png)

Next, choose which storage device to flash the OS image to, click...

- Choose Storage
- Select the microSD card from the list

![Flash OS to microSD Card](./images/RPi_imager_SelectedStorage.png)

Before flashing the OS, the RPi Imager application allows you to configure settings that will help for a headless installation.  Click the gear icon ![gear icon](./images/RPi_imager_gearicon.png) then set the following...

- **Image customization options**: I suggest using `for this session only`, but if you intend to repeat this setup multiple times then selecting `to use always` is OK.
- **Set hostname**:  OK to leave blank (default setting = `raspberrypi`)
- **Enable SSH**: Enable the checkbox
  - **Use password authentication**
- **Set username and password**: Enable the checkbox
  - **Username**: {your_username} (default = pi)
  - **Password**: {your_password}
- **Configure wireless LAN**: Enable the checkbox
  - **SSID**: {your_wifi_ssid}
  - **Password**: {your_wifi_password}
  - **Wireless LAN country**: {your_country_code}
- **Set locale settings**:  Enable the checkbox
  - **Time zone**: Etc/UTC (we want of RPi's TZ to be the same as GPS's TZ)
  - **Keyboard layout**: {your_country_keyboard}

Click `SAVE` to save settings and dismiss the pop-up.

With all the settings done, click `WRITE`, you will shown a warning to let you know that the any data on the SD card will be erased, to continue downloading the OS image file and flash the microSD card, clilck `YES`.

Depending on your computer's security settings, you may be prompted for your username and password; this is to give the RPi Imager app permissions to write to the SD card.

![System Permissions](./images/RPi_imager_LocalPermissions.png)

The RPi Imager will download the OS image, write the OS to the SD card and then verify that it has copied to the SD card correctly, this could take some minutes to complete.

![OS flash complete](./images/RPi_imager_FlashComplete.png)

When the flash process has finished, click `CONTINUE`, then eject and remove your microSD card from the reader.

Insert the microSD card into the RPi, then power-up the RPi.

### Finding the IP address of the RPi

When the RPi boots, it will connect to the WiFi using DHCP and the credentials provided during the microSD flash process.  In order to connect to the RPi using SSH we need to know the IP address that the WiFi router has assigned to the RPi.

Open a `terminal` window on your laptop/PC and scan the network for available devices using one or all of the following:

#### Using `arp`

``` bash
arp -a
```

Use `arp` and `grep` to return only IPs with name `raspberry` or part of the RPi's MAC address

``` bash
arp -a | grep raspberry
```

``` bash
arp -a | grep dc:a6
```

#### Using `nmap`

IP range assignment may vary for individual routers, typically `192.168.1.0` is the base address of most routers with a mask of `/24` to give access to a range of IPs from `192.168.1.0` to `192.168.1.255`

``` bash
nmap -sn 192.168.1.0/24
```

Check the list of devices to find the one with `raspberry` in the description.

### Connect to RPi using SSH

From a terminal window on your laptop/PC, connect to the RPi using `ssh`, replace `xx.xx.xx.xx` with the IP of the RPi. When prompted, enter the SSH password created during the microSD flash process.

``` bash
ssh pi@xx.xx.xx.xx
```

### Update the OS

Before making any changes to the RPi it is recommended to update the Ubuntu OS.

``` bash
sudo apt update
```

The update process may take some time, then upgrade the OS.

``` bash
sudo apt upgrade
```

The upgrade may take some time to complete, you may be prompted to restart some services or reboot.  

### Setup Serial and I2C Interfaces

Before we can use the GNSS expansion board with the RPi we need to configure the serial ports and I2C interfaces correctly.

#### Serial Port Configuration

By default Ubuntu is set to enable a serial-console, this must be disabled otherwise the `root` user will constantly take ownership of the serial port, typically this will be on `/dev/serial0`, a symlink to `/dev/ttyS0` which is the UART serial port that the GPS board is using.

``` bash
sudo nano /boot/firmware/cmdline.txt
```

![cmdline.txt](./images/cmdline_txt_unmodified.png)

Delete the entry `console=serial0,115200`

![cmdline.txt](./images/cmdline_txt_modified.png)

Save and exit nano.

Reboot `sudo reboot`, login via SSH after approx. 1 minute.

Check that the `pi` user is able to read data the GPS board is sending to the serial port.

``` bash
cat /dev/serial0
```

The data may contain a lot of blank lines and/or 'unknown' data.  For a cleaner output it may help to exclude these.

``` bash
cat /dev/serial0 | grep -v -E "(unknown|^$)" 
```

Example output:

``` bash
$GNGSA,A,3,21,01,08,32,22,03,17,19,04,,,,1.13,0.69,0.89*13
$GNGSA,A,3,88,72,65,87,81,66,73,82,,,,,1.13,0.69,0.89*1F
$GPGSV,4,1,14,01,74,107,42,03,71,235,27,04,20,177,26,08,09,167,17*7B
$GPGSV,4,2,14,14,12,252,16,17,46,296,38,19,25,314,38,21,47,117,38*72
$GPGSV,4,3,14,22,36,060,36,28,,,32,31,06,090,14,32,20,042,37*4F
$GPGSV,4,4,14,36,23,142,,49,29,173,*7C
$GLGSV,3,1,11,65,68,059,35,66,45,199,25,72,19,037,23,73,12,005,23*6C
$GLGSV,3,2,11,74,00,047,,80,10,319,,81,64,317,38,82,14,316,35*6E
$GLGSV,3,3,11,87,11,134,30,88,57,134,41,95,10,319,*58
```

### Configuring the I2C bus and hardware clock

To use the GPS board fully and to make use of the hardware real-time clock (RTC) on the GPS board, we have to setup the I2C correctly and modify the `hwclock` settings.

Install the necessary tools.

``` bash
sudo apt install i2c-tools python3-smbus
```

Check the current configuration of I2C

``` bash
sudo i2cdetect -y 1
```

Output should be...

``` bash
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:                         -- -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40: -- -- 42 -- -- -- -- -- -- -- -- -- -- -- -- -- 
50: -- -- 52 -- -- -- -- -- -- -- -- -- -- -- -- -- 
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
70: -- -- -- -- -- -- -- --                         
```

The RTC is at addr `0x52` and the GPS at addr `0x42` on the I2C bus.

We need to modify the system config such that the RTC can be used by the OS.

``` bash
sudo nano /boot/firmware/config.txt
```

At the end of the file, after `[all]` add ...

``` bash
dtoverlay=i2c-rtc,rv3028
```

The RTC on the Uputronics board is a Micro Crystal RV-3028-C7 real time clock module, `rv3028` is the identifier for this RTC.

Reboot and SSH login again.

Check that the I2C bus has been updated correctly.

``` bash
sudo i2cdetect -y 1
```

Output should be...

``` bash
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:                         -- -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40: -- -- 42 -- -- -- -- -- -- -- -- -- -- -- -- -- 
50: -- -- UU -- -- -- -- -- -- -- -- -- -- -- -- -- 
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
70: -- -- -- -- -- -- -- --                         
```

Now at adrr `0x52` should be `UU` to indicate that the RTC is being used by the OS kernel driver.

Now the OS must be configured to use the hardware RTC instead of the fake hardware clock that is used by default.

``` bash
sudo apt-get -y remove fake-hwclock
sudo update-rc.d -f fake-hwclock remove
sudo systemctl disable fake-hwclock
sudo nano /lib/udev/hwclock-set
```

Comment out the lines:

``` bash
#if [ -e /run/systemd/system ] ; then
#    exit 0
#fi
#
#/sbin/hwclock --rtc=$dev --systz
```

To read the hwclock

``` bash
sudo hwclock -v -r
```

![hwclock](./images/hwclock-output.png)

### Configure the GPS/PPS

In order for correct NTP operation, the PPS from the GPS must also be configured.

``` bash
sudo apt install pps-tools
sudo nano /boot/firmware/config.txt
```

At the end of the file, after `[all]` add ...

``` bash
dtoverlay=pps-gpio
```

We also need to update the system modules

``` bash
sudo nano /etc/modules
```

At the end of the file, add...

``` bash
pps-gpio
```

Reboot and SSH login again.

Check that the PPS is operating correctly.

``` bash
sudo ppstest /dev/pps0
```

Output should be similar to...

![pps output](./images/pps_output.png)

**N.B.**  Since V3.00 of the Ublox firmware the time pulse is not released until all time parameters are known including leap seconds. There it could be up to 12.5 minutes before time pulse is available however positional lock is achieved from cold in the expected sub 30 seconds.

---

## Additional Setup

### Install Swift

- Run system update and upgrade, install `curl`

``` bash
sudo apt update && sudo apt upgrade
sudo apt install curl
```

- Run Swift lang quick install script

``` bash
curl -s https://archive.swiftlang.xyz/install.sh | sudo bash
```

- Script will check for system compatibility, our config should be OK, when prompted select (1) latest release.

![Swift Version Check](./images/swift_version_select.png)

- Install Swift

``` bash
sudo apt install swiftlang
```

- Check Swift version

``` bash
swift --version
```

![Swift Installed Version](./images/swift-version.png)

### (Optional) Install git

Git should be installed by default with this the current config, check that git is installed.

``` bash
git --version
```

![git --version](./images/git-version.png)

If git is not installed...

``` bash
sudo apt install git
```

### Setup a shared network folder using Samba

This shared folder will be used so that we can edit code on the RPi from another computer, specifically to use Xcode and have all the benefits of using that Xcode IDE whilst having all the code saved on the RPi.

We will create a `code` folder in the pi user's home folder; create a user group `coders`; then we will configure samba.

In the pi user home folder create a new folder `code`.

``` bash
cd ~
mkdir code
```

Create a new user group `coders`, then add the `pi` user to this group.

``` bash
sudo groupadd coders
sudo usermod -aG coders pi
```

Set the `coders` group to be the group owner of this folder, then give the `coders` group read-write permissions.

``` bash
sudo chgrp -R coders: ./code
sudo chmod -R g+rw ./code
```

With the share setup, we can install and configure samba.

``` bash
sudo apt-get install -y samba

sudo nano /etc/samba/smb.conf
```

If your RPi needs to join a specific workgroup of domain, update the `WORKGROUP` name as required.

``` bash
workgroup = WORKGROUP
```

At the end of the `smb.conf` file add...

``` bash
[CODE]
path = /home/pi/code
valid users = @coders
browsable = yes
writable = yes
read only = no
```

Save and close the file.

Restart the samba service for the changes to take effect.

``` bash
sudo systemctl restart smbd
```

Add the `pi` user to Samba.

``` bash
sudo smbpasswd -a pi
```

Confirm by entering the password for the `pi` user when prompted.  Then enable the user.

``` bash
sudo smbpasswd -e pi
```

To connect to the share from macOS, use Finder.  Select `Go -> Connect To Server ...`.  In the pop-up window enter the Samba location of the share, replace xx.xx.xx.xx with the IP address of the RPi.

``` bash
smb://xx.xx.xx.xx/code
```

When prompted, enter the username and password we have created.

![samba user credentials](./images/samba-login-macOS.png)

### Build a 'helloGPS' application

For the `helloGPS` app we are going to make use of the existing `SwiftyGPIO` repo.

Uraimo's `UBloxGPS.swift` repo is very close to what we need, but is written to only parse GPS messages, our application must parse multi-GNSS message so we will create a UBloxGNSS parser based on UBloxGPS.swift; both repos created by [uraimo](https://github.com/uraimo).

On the RPi, create a new directory for the `helloGPS` application.

``` bash
cd ~/code
mkdir helloGPS
cd helloGPS
```

Optionally, enable `git` for this project.

``` bash
git init
git add .
```

Use Swift's package management (SPM) to create a blank executable package.

``` bash
swift package init --type executable
```

Now that we have a blank Swift package and a open share on the RPi, we can write the code of our `helloGPS` app using Xcode on macOS.  Using Xcode, open the `package.swift` file that we just created; should just need to open `package.swift`, located in `/Volumes/code/helloGPS/` in Finder.

![helloGPS starter project in Xcode](./images/xcode_helloGPS_blankproject.png)

In `Package.swift` update the package dependencies to include the `SwiftyGPIO` repo, this will download the `SwiftyGPIO` package; then add this package as a target dependency.

``` swift
import PackageDescription

let package = Package(
    name: "helloGPS",
    dependencies: [
      .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.1")
    ],
    targets: [
        .executableTarget(
            name: "helloGPS",
            dependencies: ["SwiftyGPIO"])
    ]
)
```

In `helloGPS/Sources/helloGPS` create a new swift file, `UBloxGNSS.swift` with the following code.

``` swift
import Foundation
import SwiftyGPIO

public class UBloxGNSS{
  var uart: UARTInterface
  var updateThread: Thread?
  var running = false
  
  public var isDataValid = false
  public var datetime = "N/A"
  public var latitude: Double = 0
  public var longitude: Double = 0
  public var satellitesActiveNum = 0
  public var altitude: Double = 0
  public var altitudeUnit: String = "N/A"
  
  // Internal fields for quadrant location used to compute lat/lon
  var NS: Int = 1
  var EW: Int = 1
    
  public init(_ uart: UARTInterface) {
    self.uart = uart
    uart.configureInterface(speed: .S9600, bitsPerChar: .Eight, stopBits: .One, parity: .None)
    print("Init'd")
  }
  
  public func startUpdating(){
    //Ignored by Linux
    guard #available(iOS 10.0, macOS 10.12, *) else {return}
    
    if updateThread == nil {
      updateThread = Thread{ [unowned self] in
        self.update()
      }
    }
    running = true
    updateThread!.start()
  }
  
  public func stopUpdating(){
    running = false
    updateThread = nil
  }
  
  public func printStatus(){
    print()
    print("\tGNSS Values:",(isDataValid ? "valid." : "invalid."))
    print("\tDate:", datetime)
    print("\tLatitude:",latitude,"Longitude:",longitude)
    print("\tAltitude:",altitude,altitudeUnit)
    print("\tUsable satellites:",satellitesActiveNum)
    print("\t-------------------------------------------------------- ctl-c to quit")
    print()
  }
  
  private func update(){
    while running {
      let s = uart.readLine()
      parseNMEA(s)
    }
  }
  
  /// Parse the NMEA0183 protocol strings that follow the format:
  ///
  /// $ttsss,d1,d2,...,dn<CR><LF>
  ///
  /// - Parameter text: a string conforming to the protocol
  ///
  private func parseNMEA(_ text: String){
    let comp = text.components(separatedBy: ",")
    
    switch comp[0] { //$ttsss
    case "$GNRMC":
      // time,valid,lat,NorS,lon,EorW,speed,course,date,magn,EorW,ck
      // time= hhmmss.ss, date= ddmmyy
      if comp[1].count > 0 {
        datetime = comp[9]+" "+String(comp[1].dropLast(3))
      }
      
      isDataValid = (comp[2] == "A")
      // quadrants, will be used to apply the right sign to lat/lon
      NS = (comp[2] == "N") ? -1 : 1
      EW = (comp[6] == "E") ? 1 : -1
      
      // latitude and longitude in degrees+minutes format
      if (comp[3].count > 0) && (comp[5].count > 0) {
        latitude = Double(String(comp[3].prefix(2)))! +
        Double(String(comp[3].dropFirst(2)))!/60
        latitude *= Double(NS)
        latitude = latitude.roundTo(places: 8)
        longitude = Double(String(comp[5].prefix(3)))! +
        Double(String(comp[5].dropFirst(3)))!/60
        longitude *= Double(EW)
        longitude = longitude.roundTo(places: 8)
      }
    case "$GNGGA":
      // time,lat,NorS,lon,EorW,quality,numSats,Hdiluition,altitude,unitAltitude,geoidsep,unitGeoidsep,dataAge,[missing in ublox],ck
      satellitesActiveNum = Int(comp[7]) ?? 0
      altitude = Double(comp[9]) ?? 0
      altitudeUnit = comp[10]
    default:
      //Unrecognized or ignored string
      return
    }
  }
  
  deinit{
    stopUpdating()
  }
}

extension Double {
  func roundTo(places:Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return (self * divisor).rounded() / divisor
  }
}

```

Edit the `main.swift` file as follows.

``` swift
import Foundation
import SwiftyGPIO

var signalReceived: sig_atomic_t = 0
signal(SIGINT) { signal in
  signalReceived = signal
}

let uarts = SwiftyGPIO.UARTs(for: .RaspberryPi4)!
var uart = uarts[0]
let gnss = UBloxGNSS(uart)

gnss.startUpdating()
while signalReceived == 0 {
  #if os(Linux)
    system("clear")
  #endif
  gnss.printStatus()
  sleep(1)
}
gnss.startUpdating()

exit(signalReceived)

```

Save the Xcode project.

On the RPi, build the application in the terminal window.

``` bash
swift build
```

Assuming there are no errors, then run the application.

``` bash
swift run
```

The appliction will read the messages sent from the UBlox GNSS receiver and will decode the `$GNRMC` and `$GNGGA` messages, update the display every second, displaying the receiver position and usable satellite count.

![helloGPS](./images/helloGPS_app_output.png)


#### Build and install a release version of `helloGPS`

``` bash
swift build -c release
cd .build/release
sudo cp -f helloGPS /user/local/bin/hellogps
```

Invoke the application by running `hellogps`

**That's All Folks!**

---
