;pause 2000
;disconnect

; PICAXE 08M2
; +V              1 [   ] 8 0V
; In/SerIn    C.5 2 [   ] 7 C.0 Out/SerOut/adc
; ADC/In/Out  C.4 3 [   ] 6 C.1 In/Out/ADC/Touch/hserin/SRI/hi2c scl
; ADC/In/Out  C.3 4 [   ] 5 C.2 In/Out/ADC/Touch/pwm/tune/SRQ/hi2c sda scl

 ; this needs to change if you change the toggle switch pin
symbol INTERRUPT_PINS = %0001000
symbol INTERRUPT_ON_MASK =  %00000000 
symbol INTERRUPT_OFF_MASK = %00001000

;symbol green_led = C.0
symbol finger_servo = C.1
symbol peizo = C.2
symbol toggle_switch = pinC.3 ;SWITCH_PIN
symbol door_servo = C.4

symbol finger_state = b0
symbol switch_cycle_count = b1
symbol next_finger_state = b2
symbol is_interrupted = b3
symbol randnum = w2
symbol counter = b6
symbol pos_diff = b7
symbol step_delay = w4 

symbol AT_REST = 0
symbol TURN_OFF_SWITCH = 1
symbol TURNING_OFF_SWITCH = 2
symbol RETURNING_TO_REST = 3
symbol FINGER_AT_REST_POS = 90
symbol DOOR_AT_REST = 150
symbol DOOR_HALF_OPEN = 175
symbol DOOR_OPEN = 185
symbol FINGER_SWITCH_OFF_POS = 205
symbol SERVO_WAIT = 500

let finger_state = AT_REST

servo finger_servo, FINGER_AT_REST_POS
servo door_servo, DOOR_AT_REST

;sertxd("setting interrupt, toggle switch = ", #toggle_switch,13,10) 	
if toggle_switch = 1 then
	setint INTERRUPT_ON_MASK,  INTERRUPT_PINS
	next_finger_state = TURN_OFF_SWITCH
	;low green_led
else
	setint INTERRUPT_OFF_MASK,  INTERRUPT_PINS
	;high green_led
endif

main:
	random randnum
	is_interrupted = 0
	if next_finger_state = RETURNING_TO_REST then
		gosub return_to_rest
	elseif next_finger_state = TURN_OFF_SWITCH then
		gosub turn_off_switch2
	endif
	
	pause SERVO_WAIT
	goto main

return_to_rest:
	;sertxd("returning to rest",13,10)
	finger_state = RETURNING_TO_REST
	servopos finger_servo, FINGER_AT_REST_POS
	pause SERVO_WAIT
	servopos door_servo, DOOR_AT_REST
	next_finger_state = AT_REST
return
	
turn_off_switch2:
	inc switch_cycle_count
	finger_state = TURNING_OFF_SWITCH
	;sertxd("turning off switch, randnum =",#randnum,13,10)
	if randnum < 16384 then ; 0.25 of the time randnum will be less than 2^16/4
		gosub open_door_and_turn_off_switch
	elseif randnum < 32768 then
		;sertxd("playing a song", 13,10)
		gosub play_song_and_push_button
	elseif randnum < 49152 then
		;sertxd("nattering", 13,10)
		gosub natter_and_push_button
	else
		;sertxd("going slow", 13,10)
		gosub push_button_slowly
	endif
return

open_door_and_turn_off_switch:
	;sertxd("just turning off the switch, nothing special.", 13,10)
	; open the door
	servopos door_servo, DOOR_OPEN
	pause SERVO_WAIT
		
	if is_interrupted > 0 then
		return
	endif
				
	; just turn off switch	
	servopos finger_servo, FINGER_SWITCH_OFF_POS
return

natter_and_push_button:
	if randnum < 40960 then ; 0.5 of the time randnum will be less than 2^16/2
		for counter = 0 to 9
			gosub short_tap
		next counter
	else
		gosub long_tap
		gosub short_tap
		gosub short_tap
		gosub long_tap
		gosub long_tap
		pause 250
		gosub short_tap
		gosub long_tap			
	endif
	
	gosub open_door_and_turn_off_switch
return

push_button_slowly:
	pos_diff = DOOR_OPEN - DOOR_AT_REST
	step_delay = 2000 / pos_diff
	;sertxd("step_delay=",#step_delay,13,10)
	for counter = DOOR_AT_REST to DOOR_OPEN
		servopos door_servo, counter
		pause step_delay
		
		if is_interrupted > 0 then
			return
		endif
	next counter
	
	pos_diff = FINGER_SWITCH_OFF_POS - FINGER_AT_REST_POS
	step_delay = 3000 / pos_diff
	;sertxd("step_delay=",#step_delay,13,10)
	for counter = FINGER_AT_REST_POS to FINGER_SWITCH_OFF_POS
		servopos finger_servo, counter
		pause step_delay
		if is_interrupted > 0 then
			return
		endif
	next counter
return
	
play_song_and_push_button:
	; open the door
	servopos door_servo, DOOR_OPEN
	pause SERVO_WAIT

	if randnum < 24576 then ; 0.5 of the time randnum will be less than 2^16/2
		' Buttons
		tune 0,8,($64,$66,$22,$64,$66,$22,$64,$66,$64,$66,$64,$66,$29,$62,$64,$21,$62,$64,$21,$62,$64,$62,$64,$62,$64,$27)
		if is_interrupted > 0 then
			return
		endif
		servopos finger_servo, FINGER_SWITCH_OFF_POS
		pause SERVO_WAIT
	else
		' PopGoesWeasel
		tune 0,4,($67,$00,$40,$02,$42,$44,$47,$44,$00,$67,$00,$40,$02,$42,$04,$44,$00,$67,$00,$40,$02,$42,$44,$47,$44,$00,$40,$09,$49,$02,$45,$04,$44,$00,$40,$00,$40,$29,$40,$6B,$42,$6B,$27,$67,$00,$40,$29,$40,$2B,$6B,$27,$67,$25,$64,$25,$67,$29,$6B,$00,$42,$07,$47)
		if is_interrupted > 0 then
			return
		endif
		servopos finger_servo, FINGER_SWITCH_OFF_POS
		pause SERVO_WAIT
		' PopGoesWeasel - after pop
		tune 0,4,($02,$45,$04,$44,$00,$40)
	endif
return

long_tap:
	servopos door_servo, DOOR_HALF_OPEN
	pause 100

	servopos door_servo, DOOR_AT_REST
	pause 500
return

short_tap:
	servopos door_servo, DOOR_HALF_OPEN
	pause 100

	servopos door_servo, DOOR_AT_REST
	pause 100
return

interrupt:
	;sertxd("interrupt! toggle_switch ", #toggle_switch,13,10) 
	is_interrupted = 1
	if toggle_switch = 1 then
		;low green_led
		next_finger_state = TURN_OFF_SWITCH
		setint INTERRUPT_ON_MASK, INTERRUPT_PINS
	else
		;high green_led
		next_finger_state = RETURNING_TO_REST
		setint INTERRUPT_OFF_MASK, INTERRUPT_PINS
	endif
	return