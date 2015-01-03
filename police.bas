; PICAXE 08M2
; +V              1 [   ] 8 0V
; In/SerIn    C.5 2 [   ] 7 C.0 Out/SerOut/adc
; ADC/In/Out  C.4 3 [   ] 6 C.1 In/Out/ADC/Touch/hserin/SRI/hi2c scl
; ADC/In      C.3 4 [   ] 5 C.2 In/Out/ADC/Touch/pwm/tune/SRQ/hi2c sda scl

disconnect

symbol BLUE_OUT = C.4
symbol BLUE_IN = C.0
symbol RED_IN = C.2
symbol RED_OUT = C.1

symbol blue_led = b0
symbol red_led = b1

main:
	blue_led = BLUE_OUT
	red_led = RED_OUT
	gosub pulse_led
	pause 50

	blue_led = BLUE_IN
	red_led = RED_IN
	gosub pulse_led
	pause 50

goto main

pulse_led:
	pulsout blue_led, 10000
	pulsout red_led, 10000
	pause 50
	pulsout blue_led, 10000
	pulsout red_led, 10000
	pause 50
	pulsout blue_led, 10000
	pulsout red_led, 10000
	pause 50
	pulsout blue_led, 10000
	pulsout red_led, 10000
	return