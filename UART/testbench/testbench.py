import threading
import time
import serial
import queue
import time
tx_queue = queue.Queue()
stop_event = threading.Event()

class UART():
    def __init__(self, port, baudrate):
        self.port = port
        self.baudrate = baudrate
        self.ser = None
        self.rx_buffer = ""
        self.tx_buffer = ""
        
        self.rx_thread = None
        self.tx_thread = None
        
        self.__initializaiton()    
        
    def __initializaiton(self):
        self.ser = serial.Serial(
            port=self.port,
            baudrate=self.baudrate,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_TWO,
            timeout=0.05,
            write_timeout=1,
            xonxoff=False,
            rtscts=False,
            dsrdtr=False,
        )
        self.ser.reset_input_buffer()
        
    def read(self):
        while not stop_event.is_set():
            data = self.ser.read(self.ser.in_waiting or 1)
            
            if data: 
                try:
                    self.rx_buffer+= data.decode("utf-8")
                except:
                    print(self.rx_buffer)
                    raise Exception("UTF-8 error")
                    
                    
    def write(self):
        while not stop_event.is_set():
            if (len(self.tx_buffer) == 0): continue
            
            data = self.tx_buffer[0]
            self.tx_buffer = self.tx_buffer[1:]

            self.ser.write(data.encode("utf-8"))
            self.ser.flush()
    
    def start(self):
        self.rx_thread = threading.Thread(target=self.read, daemon=True)
        self.tx_thread = threading.Thread(target=self.write, daemon=True)
        
        self.rx_thread.start()
        self.tx_thread.start()
    
    def close(self):
        stop_event.set()
        self.rx_thread.join(timeout=1)
        self.tx_thread.join(timeout=1)
        self.ser.close()
    
    def __del__(self):
        self.close()
    
PORT = "COM9"
BAUD_RATE = 921600 # 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600
TIMEOUT = 5000
RX_TX_DATA_PRINT = False
DATA = """The quick brown fox jumps over the lazy dog while the UART transmitter sends each byte across the serial line. Every character must arrive in the correct order, without missing data, duplicated bytes, or unexpected changes. This message includes uppercase letters, lowercase letters, numbers, spaces, commas, periods, and other simple ASCII symbols.
UART communication may look simple, but reliable operation depends on accurate timing. The transmitter creates a start bit, eight data bits, and a stop bit for every byte. The receiver samples the signal at the correct moment and reconstructs the original data. If the clock rate or baud-rate divider is incorrect, even a small timing error can cause corrupted characters during a long transfer.
This paragraph is intended for a continuous communication test. The system should transmit and receive the complete message many times while preserving every byte. Test values include 0123456789, repeated letters such as AAAAA and zzzzz, and alternating patterns written as 01010101 and 10101010. Common punctuation is also included: ! ? , . : ; - _ ( ) [ ] { } + = / and *.
The final part of the test checks that the UART remains stable after many frames. A correct implementation should handle back-to-back traffic, short idle periods, and long streams without becoming stuck. When the transfer is complete, the received byte count and checksum should match the transmitted values exactly. UART ASCII TEST COMPLETE.
"""


def main():
    
    uart = UART(PORT, BAUD_RATE)
    uart.tx_buffer = DATA
    uart.start()
    
    print(f"{'Baud rate':>13}: {BAUD_RATE} bps\n")
    print(f"[{'TX':>13}]\n{DATA}")
    print(f"[{'RX':>13}]\n", end="")
    cnt = 0
    break_cond = False
    fail_cond = True
    while (1) :
        time.sleep(0.001)
        cnt += 1
        if (cnt > TIMEOUT):
            break_cond = True
            break 
            
        
        if(DATA == uart.rx_buffer):
            fail_cond = False
            break
    
    result = 'FAIL'if (fail_cond) else "PASS"
    timeou = '(timeout)' if (break_cond) else ''
    print(f"{uart.rx_buffer}\n\n{'Result':>13}: {result} {timeou}")
    
    uart.close()
    del uart
        
        
    
if __name__ == "__main__":
    print("─" * 100)
    main()
    print("─" * 100)