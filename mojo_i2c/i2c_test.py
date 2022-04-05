from pyb import Pin, LED
from machine import I2C
import sys
import time


led = LED(1)

sleep_intv = 0.100
do_sleep = True

i2c = I2C(2, freq = 400000)
addr = 0x4b

led_pat = 0x003c00

tx_buf = bytearray(1)
shift_dir = 'left'
count = 0
v = 0

def do_test():
  global led_pat
  global count
  global shift_dir

  while True:
    if shift_dir == 'left':
      led_pat = led_pat << 1
      count = count -1
    else:
      led_pat = led_pat >> 1
      count = count + 1

    if count == -5:
      shift_dir = 'right'

    if count == 5:
      shift_dir = 'left';

    v = led_pat & 0x00ff00
    v = v >> 8

    tx_buf[0] = v
    i2c.writeto(addr, tx_buf);

    d = i2c.readfrom(addr, 1);

    if d[0] != v:
      print('led read failed: ', v, d[0])
      sys.exit(2);

    time.sleep(0.08 + (0.01 * abs(count)))
    led.toggle()
