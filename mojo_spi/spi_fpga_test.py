from pyb import SPI, Pin, LED
import sys
import time


led = LED(1)

sleep_intv = 0.003
do_sleep = False

cs_delay = 0.01
do_cs_delay = False

#reset = Pin('X4', Pin.OUT_PP)
spi_ss = Pin('X5', Pin.OUT_PP)
spi_ss.high()
# 16. 5.25Mhz
spi = SPI(1, SPI.MASTER, prescaler=16, polarity=0, phase=1)
tx_buf = bytearray(2)

#reset.high()
#print('.... resetting...')
#time.sleep(1)
#reset.low()
#time.sleep(1)
#print('.... done...')

def do_test():
    iter = 1

    while True:
        print('===== test iteration: ', iter);

        for v in range(255):
            #print('=== testing: ',v)
            # first write v
            tx_buf[0] = 0x02
            tx_buf[1] = v

            #print("=== writing:", v,tx_buf[0],tx_buf[1]);
            spi_ss.low()
            if do_cs_delay:
                time.sleep(cs_delay)

            d = spi.send_recv(tx_buf)

            if do_cs_delay:
                time.sleep(cs_delay)
            spi_ss.high()

            #print("=== write complete:", v, d[0], d[1]);

            #time.sleep(2);

            # second read back
            tx_buf[0] = 0x01
            tx_buf[1] = 0x00

            #print("=== reading:", v,tx_buf[0],tx_buf[1]);

            spi_ss.low()
            if do_cs_delay:
                time.sleep(cs_delay)
            d = spi.send_recv(tx_buf)

            if do_cs_delay:
                time.sleep(cs_delay)
            spi_ss.high()

            #print("=== read complete:", v, d[0], d[1]);

            if d[1] != v:
                print('led read failed: ', v, d[0], d[1])
                sys.exit(2);

            if do_sleep:
                time.sleep(sleep_intv)

        iter = iter + 1
        led.toggle()
