
local midi = require "luamidi"

local inputports = midi.getinportcount()
local indevicenumber = 0
local in0 = nil

local outputports = midi.getoutportcount()
local outChannel = 1	-- (channels start with 0-15)
local outdevicenumber = 0
local out0 = midi.openout(outdevicenumber)
local outputdeveicename = midi.getOutPortName(outdevicenumber)

function love.load()
	if inputports > 0 then
		print("Midi Input Ports: ", inputports)
		table.foreach(midi.enumerateinports(), print)
		print( 'Receiving on device: ', luamidi.getInPortName(indevicenumber))
		-- not needed for this demo
--		in0 = midi.openin(indevicenumber)
	else
		print("No Midi Input Ports found!")
	end
	print()

	if out0 and outputports > 0 then
		print("Midi Output Ports: ", outputports)
		table.foreach(midi.enumerateoutports(), print)
		print()
		print( 'Play on device: ', outputdeveicename )

		-- change Program: 16 midi channels (192-207), program (0-127), - not used -
		out0:sendMessage( 192+outChannel, 1, 0 )	-- on midi channel 1, change program to 1

		out0:sendMessage( 192+outChannel+1, 90, 0 )	-- on midi channel 2, change program to 120


		-- change Control Mode: 16 midi channels (176-191), control (0-127), control value (0-127)
		out0:sendMessage( 176+outChannel, 7, 50)	-- on midi channel 1, change volume, to 80

		----------------------------------------------------
		-- Play notes using the following two possibilities:
		----------------------------------------------------
		
		-- Play note: midi port, note, [vel], [channel]
		midi.noteOn(0, 60, 100, outChannel) -- play on port 0, note 10, velocity 80, on midi channel 1

		-- or
		
		-- Play note: note, [vel], [channel]
		out0:noteOn( 10, 10, outChannel+1 ) -- play on choosen port out0, note 60, velocity 100, on channel outChannel
	else
		print("No Midi Output Ports found!")
	end
	print()
end

-- current input nodes
local a,b,c,d = nil, 60, 100, nil

function love.draw()
	love.graphics.setColor(255,255,255)
	love.graphics.print( 'Play on device: ' .. outputdeveicename, 200, 10 )

	love.graphics.print( 'Press Q,W,E,R,T on your PC-Keyboard or connect a Midi-Keyboard to play Notes.', 200, 60 )

	love.graphics.print( 'Input devices: ' .. inputports, 200, 100 )
    love.graphics.print( 'Input', 200, 120)
    love.graphics.print( 'Command: ' ..tostring(a) .. ' Note: ' .. tostring(b) .. ' Vel.: ' .. tostring(c) .. ' delta-time: ' .. tostring(d), 200, 140)
	
	love.graphics.setColor(a or 255,b or 255,c or 255)
	love.graphics.circle('fill', (b or 0)*6, 350, (c or 0)/2 or 1, 25)
end

function love.update(dt)
	if out0 and inputports > 0 and outputports > 0 then
		-- command, note, velocity, delta-time-to-last-event (just ignore)
		a,b,c,d = midi.getMessage(indevicenumber)
		
		if a ~= nil then
			if a == 144 then	-- listen for Note On on First Midi Channel
				print('Note turned ON:	', a, b, c, d)
				out0:noteOn( b, c, outChannel )
			elseif a == 128 then	-- listen for Note Off on First Midi Channel
				print('Note turned OFF:', a, b, c, d)
				out0:noteOff( b, c, outChannel )
			elseif a == 176 then	-- if channel volume is changed
				print('Channel Volume changed (Ch/Vol):', b, c)
				out0:sendMessage( 176+outChannel, 7, c)
			else
				-- other messages
				print('SYSTEM:', a,b,c,d)
			end
		end
	end
end

--					C4			D4			E4			F4			G4
local mapping = { ['q'] = 60, ['w'] = 62, ['e'] = 64, ['r']= 65, ['t']= 67 }
function love.keypressed( key, isrepeat )
	if mapping[key] then
		b,c = mapping[key], 100
		out0:noteOn( b,c, outChannel )
	end
end

function love.keyreleased(key)
	if mapping[key] then
		b,c = mapping[key], 64
		out0:noteOff( b,c, outChannel )
	end
end

function love.quit()
	midi.gc()
end