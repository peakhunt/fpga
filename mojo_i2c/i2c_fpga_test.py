from pyb import Pin, LED
from machine import I2C
import sys
import time


led = LED(1)

sleep_intv = 0.003
do_sleep = False

i2c = I2C(2, freq = 400000)
addr = 0x4b

tx_buf = bytearray(1)

def do_test():
  iter = 1

  while True:
    print('===== test iteration: ', iter);

    for v in range(255):
      #print('=== testing: ',v)
      # first write v
      tx_buf[0] = v

      i2c.writeto(addr, tx_buf);

      d = i2c.readfrom(addr, 1);

      if d[0] != v:
        print('led read failed: ', v, d[0])
        sys.exit(2);

      if do_sleep:
        time.sleep(sleep_intv)

    iter = iter + 1
    led.toggle()
