//
//  firecrestHORIZON.uk
//  
//  e-Mail  : kieran.conlon@firecresthorizon.uk
//  Twitter : @firecrestHRZN and @Kieran_Conlon
//

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
