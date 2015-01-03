main:
output C.4
input C.3
setfreq m8 ; set to 8Mhz
symbol maxDistance = w2
symbol distance = w1
symbol sensorOutput = w0
symbol triggerPin = C.4
symbol echoPin = C.3
symbol ledPin = C.2
symbol ledTimeout = w3

low ledPin

sense:

; I am using a PicAxe 08M2, which runs at 8 Mhz
; trigger the sonar detector, for 10 usecs (2 * 5 usecs)
pulsout triggerPin, 2

; listen for the pulse length to determine the distance
sensorOutput = 1
pulsin echoPin, 1, sensorOutput ; @8Mhz, timeout is 327 ms

if sensorOutput > 0 then
	; sensorOutput is the number of 5 usec cycles the PicAxe counted
	distance = sensorOutput * 5 / 58
	; the div by 58 comes from 
	;1 / (340m/s * 100 (convert to cm(/100000 (convert to usecs) / 2 (only need to know the trip to the object, not the round trip))
	ledTimeout = 0
else
	inc ledTimeout
endif

if distance > maxDistance then
	maxDistance = distance
endif

; if the object we were tracking vanishes for more than 3 measurements, turn off the led 
if distance < 16 and ledTimeout < 3 then
	high ledPin
else
	low ledPin
endif

;debug

; print out information to the serial port
if sensorOutput > 0 then
	sertxd("Distance: ", #distance, " cm", " Max Distance: ", #maxDistance, " cm",13,10) 
	pause 60
else
	pause 1000
endif

goto sense

