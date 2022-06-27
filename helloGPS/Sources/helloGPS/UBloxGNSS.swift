//
//  firecrestHORIZON.uk
//  
//  e-Mail  : kieran.conlon@firecresthorizon.uk
//  Twitter : @firecrestHRZN and @Kieran_Conlon
//

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
