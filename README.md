# L2CapDemo
Demonstration of using Core Bluetooth L2CAP channels in Swift on iOS.  Use the [L2Cap swift module](https://github.com/paulw11/L2Cap)

You will need two iOS devices to run this demo.  Bluetooth is not supported in the simulator.

On one device, turn on the *Scan* switch - this device is the central that will look for a peripheral
On the other device, turn on tyhe *Advertise* switch - This device is the peripheral.

Once a connection is made, text entered into the text field on the central will be displayed on the peripheral when you tap *Send*

