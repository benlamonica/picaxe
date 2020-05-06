#picaxe20x2

symbol SPACE=" "
symbol DATA_OFFSET=26
symbol DATA_SIZE=6

' set it to the fastest speed for the 40X2 without an external clock, baud must be set to 19200
setfreq m16

' === Variables ===
symbol sample_num = w0

'w1 is free

symbol num_circuits = b5 ' w2
symbol circuit = b6
symbol ctr1 = b7         ' w3
symbol data_ptr = b8

' data structure for each circuit
symbol adc_pin = b9      ' w4
symbol accumulator_msw = w5 'b10, b11
symbol accumulator_msw_lsb = b10
symbol accumulator_msw_msb = b11
symbol accumulator_lsw = w6 'b12, b13
symbol accumulator_lsw_lsb = b12
symbol accumulator_lsw_msb = b13
symbol max_current = b14

' b15 is free

' variables used while calculating current
symbol offset = w8
symbol current = w9
symbol sqr_current_msw = w10
symbol sqr_current_lsw = w11
symbol starting_v = w12

' a program to sum up
gosub setup_circuits

' main loop
loop_it: 
  gosub read_current
  gosub output_current
  pause 1000
goto loop_it

read_current:

  ' for each circuit
  for sample_num = 0 to 4095
    for circuit = 1 to num_circuits
      gosub load_circuit

      ' read the current
      readadc10 adc_pin, current

      ' square it
      sqr_current_msw = current ** current
      sqr_current_lsw = current * current

      ' add it to the accumulator
      accumulator_msw = accumulator_msw + sqr_current_msw
      accumulator_lsw = accumulator_lsw + sqr_current_lsw

      ' move to next circuit
      gosub save_circuit
    next circuit
  next sample_num

  ' average out the squares
  for circuit = 1 to num_circuits
      gosub load_circuit
      sqr_current_msw = accumulator_msw << 4
      sqr_current_lsw = accumulator_lsw >> 12
      accumulator_lsw = sqr_current_msw & sqr_current_lsw
      accumulator_msw = accumulator_msw >> 12
      gosub save_circuit
  next circuit
return

output_current:
  'send magic cookie and number of circuits to expect
  sertxd ("B", "A", "L", num_circuits)
  for circuit = 1 to num_circuits
    gosub load_circuit
    sertxd (max_current, accumulator_msw_msb, accumulator_msw_lsb, accumulator_lsw_msb, accumulator_lsw_lsb)
  next circuit
return

setup_circuits:
  num_circuits = 2
  
  accumulator_msw = 0
  accumulator_lsw = 0
  
  ' B.5
  adc_pin = 10
  circuit = 1
  max_current = 20
  gosub save_circuit
  adcsetup = adcsetup | %010000000000

  ' B.6
  adc_pin = 11
  circuit = 2
  max_current = 15
  gosub save_circuit
  adcsetup = adcsetup | %100000000000  
return

load_circuit:
    ' get the circuit pin from the array, in picaxe math, there are no parenthesis, and the operators occur in the order that they are shown (no normal operator precedence)
    data_ptr = circuit - 1 * DATA_SIZE + DATA_OFFSET
    peek data_ptr, adc_pin
    data_ptr = data_ptr + 1
    peek data_ptr, max_current
    data_ptr = data_ptr + 1
    peek data_ptr, word accumulator_msw
    data_ptr = data_ptr + 2
    peek data_ptr, word accumulator_lsw
return

save_circuit:
    ' get the circuit pin from the array
    data_ptr = circuit - 1 * DATA_SIZE + DATA_OFFSET
    poke data_ptr, adc_pin
    data_ptr = data_ptr + 1
    poke data_ptr, max_current
    data_ptr = data_ptr + 1
    poke data_ptr, word accumulator_msw
    data_ptr = data_ptr + 2
    poke data_ptr, word accumulator_lsw
return