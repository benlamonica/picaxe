' === MAX7219_Driver.bas ============= 
' (c) 2012 - Ron Hackett, Evan Venn
' (c) 2106 - Ben La Monica

' This program runs on a PICAXE-08M & controls a MAX7219 LED display driver.
' The MAX7219 can be connected to eight 7-segment LED displays.

' === Constants ===

symbol DECODE_DIGITS = %00000111 ' bitmask of the digits that you want to use the internal font
symbol NUM_DIGITS = 4            ' number of digits that you want to multiplex
symbol BRIGHTNESS = 100          ' 100 = full brightness, 50 = half brightness, 25 = quarter brightness

' Hardware interface to the MAX7219 
symbol MAX_CLOCK_PIN = C.2   ' data is valid on the rising edge of the clock pin
symbol MAX_DATA_PIN = C.4    ' data bits are shifted out this pin to the MAX7219
symbol MAX_LOAD_PIN = C.1   ' briefly pulse this output to transfer data to LEDs

' Register addresses for the MAX7219
symbol REG_DECODE = 9      ' decode register; specify digits to decode
symbol REG_BRIGHTNESS = 10 ' intensity (brightness) register; 15 = 100%
symbol REG_SCAN = 11       ' scan-limit register; specify how many digits
symbol REG_DISPLAY = 12    ' 1 = display on; 0 = display off 
symbol REG_TEST_MODE = 0xF ' turn on all segments

' === Variables ===
symbol outword = w0        ' concatenation of maxreg and outbyte
symbol max_data = b0       ' data to be transmitted to the MAX7219
symbol max_register = b1   ' MAX7219 register that receives data
symbol index = b2          ' used in subroutine for...next loop

' === Main Program ===

' the MAX7219 clock can only be pulsed at max of 10Mhz, so stay below that
setfreq m8

' Initialize the MAX7219
gosub init_max7219

' put some test numbers up
max_register = 1
max_data = 3
gosub send_data

max_register = 2
max_data = 2
gosub send_data

max_register = 3
max_data = 1
gosub send_data

max_register = 4
max_data = %01111011
gosub send_data

goto endofprogram

' === End Main Program - Subroutines Follow ===============================
turn_on_display:
  max_data = 1
  max_register = REG_DISPLAY
  gosub send_data
  return

turn_off_display:
  max_data = 0
  max_register = REG_DISPLAY
  gosub send_data
  return

set_display_digits:
  max_register = REG_SCAN
  gosub send_data
  return

set_decode_mode:
  max_register = REG_DECODE
  gosub send_data
  return

set_brightness:
  max_register = REG_BRIGHTNESS
  gosub send_data
  return

set_test_mode:
  max_register = REG_TEST_MODE
  gosub send_data
  return
  
init_max7219:
  max_data = DECODE_DIGITS    ' turn on decode mode for the first 3 digits
  gosub set_decode_mode

  max_data = BRIGHTNESS / 6 - 1
  gosub set_brightness

  max_data = NUM_DIGITS - 1   
  gosub set_display_digits

  gosub turn_on_display
  return

' ===== send_data Subroutine ==================================================
' Shift out the 16-bit data word to the MAX7219 (MSB first)
send_data:
  for index = 1 to 16	' MAX7219 specifies a 16-bit word
    if bit15 = 1 then	' set sdata to correspond to bit15
      high MAX_DATA_PIN
    else
      low MAX_DATA_PIN
  endif

    pulsout MAX_CLOCK_PIN,1  ' pulse clock line 
    outword = outword * 2    ' shift outword left for next MSB 
  next index

  pulsout MAX_LOAD_PIN,1     ' load the data word into MAX7219
  return
  
 endofprogram:
