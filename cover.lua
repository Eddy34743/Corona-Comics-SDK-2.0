----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- 
-- Abstract: Corona Comics 2 Demo
-- Be Confident in Who You Are: A Middle School Confidential™ Graphic Novel Lite Version
-- 
-- Version: 2.0 (September 20, 2011)

-- Sample code is MIT licensed, see http://developer.anscamobile.com/code/license
-- Copyright (C) 2011 Electric Eggplant. All Rights Reserved.
-- Copyright (C) 2011 ANSCA Inc. All Rights Reserved.
--
-- Images and text excerpted from "Be Confident in Who You Are" by Annie Fox, M.Ed.,
-- (C) 2008. Used with permission of Free Spirit Publishing Inc., Minneapolis,
-- MN; 800-735-7323; www.freespirit.com. All Rights Reserved.
--
-- cover.lua 	- animation of the book cover.
-- 
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--
-- Notes: Whenever the app starts up again and you were last on the cover page
-- (0), this animation will run again. You can also trigger it through the Info
-- page by tapping on the cover icon.
-- 
-- If you have Particle Candy installed, the "smoke" effect will trigger when the
-- "Graphic Novel" stamp hits the page.
 

module(..., package.seeall)

local sndDir = "sound/"
local sndExt = ".m4a"
local imgDir = "images/cover/"
if _G.device == "android" then
	sndExt = ".mp3"
end


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- All cover routines are in this coverAnimation function
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function coverAnimation(restartFlag)

	------------------------------------------------------------
	-- Initialize: load images and sound
	------------------------------------------------------------
	local contentWidth = display.contentWidth
	local contentHeight = display.contentHeight
	local startOrientation = system.orientation
	local isLandscape = _G.isDeviceLandscape
	if _G.model == "nookcolor" then		-- no orientation change on NOOK Color
		isLandscape = false
		_G.isDeviceLandscape = false
		startOrientation = "portrait"
	end
	-- only exchange values if we're not on the simulator. Work-around for Corona bug?
	if isLandscape and system.getInfo( "environment" ) ~= "simulator" then
		contentWidth,contentHeight = contentHeight, contentWidth
	end
	
	local coverArt = display.newGroup( )
	
	------------------------------------------------------------
	-- Routines for screen orientation
	------------------------------------------------------------
	function setOrientation( orientation, animate, delta )
		local angles = {
			portrait = 0,
			faceUp = -1,		-- ignore faceUp and faceDown
			faceDown = -1,
			landscapeRight = 90,
			landscapeLeft = 270,
			portraitUpsideDown = 180
		}
		local lastOrientation = _G.lastOrientation
		local device = _G.device
		local rotation = angles[orientation]
		if coverArt.rotation > 360 or coverArt.rotation < 0 then coverArt.rotation = 0 end	-- if paused, sometimes this value gets crazy big
		if rotation < 0 then
			animate = false
			if not coverArt.firstOrientationEventSuppressed then 
				rotation = angles[_G.lastOrientation]	-- don't skip skip if faceUp or faceDown and this is first time through, set to initial orientation
			else
				return				-- skip if we moved into faceUp or faceDown territory
			end
		else			 -- don't change landscape flag if we're flat
			_G.isDeviceLandscape = ("landscapeLeft" == orientation or "landscapeRight" == orientation)
			_G.lastOrientation = orientation
		end

		coverArt.screenW = display.contentWidth
		coverArt.screenH = display.contentHeight
		coverArt.contentCenterX = display.contentCenterX
		coverArt.contentCenterY = display.contentCenterY
		-- only exchange values if we're not on the simulator. Work-around for Corona bug?
		if _G.isDeviceLandscape and system.getInfo( "environment" ) ~= "simulator" then
			coverArt.screenW,coverArt.screenH = coverArt.screenH,coverArt.screenW
		end
		local scale = 1

		if ( coverArt.contentWidth > coverArt.screenW ) or ( coverArt.contentHeight > coverArt.screenH ) then
			local sx = coverArt.screenW / coverArt.screenWidth
			local sy = coverArt.screenH / coverArt.screenHeight
			scale = ( sx < sy ) and sx or sy
		end
		if not delta then animate = false end		-- added to test cover rotation
		if delta == -90 and rotation == 0 then 
			rotation = 360
		elseif rotation == 270 and delta == 90 then 
			rotation = -90
		end
		if animate then
			transition.to( coverArt, {
					rotation=rotation,
					time=300,
					xScale=scale,
					yScale=scale,
					transition=easing.inOutQuad,
					onComplete = 
					function()
						if coverArt.rotation >= 360 then		-- if paused, sometimes this value gets crazy big
							coverArt.rotation = 0
						elseif coverArt.rotation == -90 then
							coverArt.rotation = 270
						end
					end})
		else
			coverArt.rotation = rotation
			coverArt.xScale = scale
			coverArt.yScale = scale		
		end
		coverArt.firstOrientationEventSuppressed = true
	end
	


	------------------------------------------------------------
	-- Orientation listener
	------------------------------------------------------------
	function orientation( event )
		if _G.model ~= "nookcolor" then		-- no orientation change on NOOK Color
			setOrientation( event.type, true, event.delta )
		end
	end
	

	------------------------------------------------------------
	-- Set up the initial screen images
	------------------------------------------------------------
	local background = display.newImage(coverArt, imgDir .. "background.jpg", true)
	
	local defaultPng
	if restartFlag then
		background.alpha = 0		-- need to set background to invisible so we can fade it up during this restart
	else											-- no need to pull in the background if this is a restart
		local startup_image = "Default-Portrait.png"
		if _G.device == "android" then startup_image = "startup.jpg" end
		defaultPng = display.newImage(coverArt, startup_image, true)
	end
	coverArt.screenWidth = coverArt.width			-- record the size before adding other elements
	coverArt.screenHeight = coverArt.height
	coverArt.screenW = display.contentWidth
	coverArt.screenH = display.contentHeight
	coverArt.xReference = 0.5*coverArt.contentWidth
	coverArt.yReference = 0.5*coverArt.contentHeight
	if isLandscape and system.getInfo( "environment" ) == "simulator" then
		coverArt.x = 0.5*coverArt.screenH
		coverArt.y = 0.5*coverArt.screenW
	else
		coverArt.x = 0.5*coverArt.screenW
		coverArt.y = 0.5*coverArt.screenH
	end

	setOrientation(startOrientation, false, 0)
	
	-- if Particle Candy is installed, then load smoke image (if you've 'required' their library file in main.lua)
	if Particles then
		local smoke = display.newImage(coverArt, imgDir .. "smoke.png", 0, -1380) 
	end

	local backgroundDelay = 500	-- minimum time the default bacground should be displayed
	if _G.model == "nookcolor" and not restartFlag then backgroundDelay = 500 end
	local	smokeDelay = backgroundDelay + 6170
	local lastDelay = 0
	
	-- x,y coordinates for the upper left corner of the rectangles that mask the MSC lettering
	-- as the letters are "typed", we move the mask rectangle to the next position, uncovering
	-- 1 letter
	-- mask1 is for the top line of letters (Middle School)
	local mask1 = {
			{44,185},
			{95,180},
			{138,175},
			{188,170},
			{237,165},
			{287,159},
			{340,154},
			{365,151},
			{414,144},
			{458,141},
			{509,136},
			{558,130},
			{606,125},
			{662,120},
		}
	
	-- mask2 is for the second line of letters (Confidential)
	local mask2 = {
			{107,262},
			{152,257},
			{208,251},
			{257,246},
			{303,241},
			{353,235},
			{407,229},
			{464,223},
			{513,218},
			{558,215},
			{615,208},
			{678,200},
		}
	
	-- Load all the sound effects
	local swishSnd = audio.loadSound( sndDir .. "swish" .. sndExt )
	local typeSnd = audio.loadSound( sndDir .. "type" .. sndExt )
	local typeReturnSnd = audio.loadSound( sndDir .. "type_return" .. sndExt )
	local titleswishSnd = audio.loadSound( sndDir .. "title_swish" .. sndExt )
	local bellSnd = audio.loadSound( sndDir .. "typewriter_bell" .. sndExt )
	local stampSnd = audio.loadSound( sndDir .. "stamp" .. sndExt )
	local rollSnd = audio.loadSound( sndDir .. "roll" .. sndExt )
	
	
	------------------------------------------------------------
	-- Routines for disposing of images and sound
	------------------------------------------------------------
	function cleanupImages()
		if Particles then		-- if Particle Candy is installed, clean up
			Particles.CleanUp()
		end
		coverArt:removeSelf()
		collectgarbage("collect")
	--	print("collect garbage "..collectgarbage("count"))      
	--	print( "TextureMemory finished: " ..  system.getInfo("textureMemoryUsed")/1024 .. " bytes" ) 
	end
	
	local function cleanupSound()
		fadeAllSound(0)
		swishSnd=nil
		audio.dispose(typeSnd)
		typeSnd=nil
		audio.dispose(typeReturnSnd)
		typeReturnSnd=nil
		audio.dispose(titleswishSnd)
		titleswishSnd=nil
		audio.dispose(bellSnd)
		bellSnd=nil
		audio.dispose(stampSnd)
		stampSnd=nil
		audio.dispose(rollSnd)
		rollSnd=nil
	end
	
	
	-- Load all the images and set to initial positions/scale/alpha (usually out of sight)
	local masthead = display.newImage(coverArt, imgDir .. "masthead.png", 0, -1380, true) 
	masthead:setReferencePoint(display.TopLeftReferencePoint)
	
	local msc = display.newImage(coverArt, imgDir .. "msc.png", 47, -5125, true) 
	msc:setReferencePoint(display.TopLeftReferencePoint)
	local maskRect1 = display.newRect(coverArt, 0, 0, coverArt.screenWidth, 65 ) 
	maskRect1:setFillColor(35,31,32 )
	maskRect1:setReferencePoint(display.TopLeftReferencePoint)
	maskRect1.y = -5190
	maskRect1.x = 0
	maskRect1:rotate(-6.3)
	local maskRect2 = display.newRect(coverArt, 0, 0, coverArt.screenWidth, 65 ) 
	maskRect2:setFillColor(35,31,32)
	maskRect2:setReferencePoint(display.TopLeftReferencePoint)
	maskRect2.y = -5274
	maskRect2.x = 0
	maskRect2:rotate(-6.3)
	
	local title = display.newImage(coverArt, imgDir .. "title.png", -5000, 43, true) 
	title:setReferencePoint(display.TopLeftReferencePoint)
	
	local book_1 = display.newImage(coverArt, imgDir .. "book_1.png", 664+74/2, 21, true) 
	book_1:setReferencePoint(display.CenterReferencePoint)
	book_1.xScale=0.0001
	book_1.yScale=0.0001
	book_1.x=664+74/2		-- reset x after changing reference point?
	
	-- if Particle Candy is installed, then initialize particle animation effect
	if Particles then
		-- CREATE AN EMITTER   (NAME, SCREENW, SCREENH, ROTATION, ISVISIBLE, LOOP, AUTO-DESTROY)
		Particles.CreateEmitter("stampEmitter", 289+222, 301+81, -10, false, false, true)
		
		-- DEFINE PARTICLE TYPE PROPERTIES
		local Properties 				= {}
		Properties.imagePath					= imgDir .. "smoke.png"
		Properties.imageWidth					= 256		-- PARTICLE IMAGE WIDTH  (newImageRect)
		Properties.imageHeight				= 256		-- PARTICLE IMAGE HEIGHT (newImageRect)
		Properties.velocityStart			= 10		-- PIXELS PER SECOND
		Properties.velocityVariation	= 50		-- RANDOMLY ADDED SPEED VARIATION
		Properties.alphaStart					= 0.15	-- PARTICLE START ALPHA
		Properties.alphaVariation			= 0.65	-- RANDOMLY ADDED ALPHA VARIATION
		Properties.fadeInSpeed				= 1.0		-- PER SECOND
		Properties.fadeOutSpeed				= -0.45	-- PER SECOND
		Properties.fadeOutDelay				= 100		-- WHEN TO START FADE-OUT
		Properties.scaleStart					= 0.05	-- PARTICLE START SIZE
		Properties.scaleVariation			= 0.20	-- RANDOM SCALE VARIATION
		Properties.scaleInSpeed				= 0.40	-- SCALE-IN SPEED PER SECOND
		Properties.scaleOutSpeed			= 0.1		-- SCALE-OUT SPEED PER SECOND
		Properties.scaleOutDelay			= 5500	-- SCALE-OUT DELAY
		Properties.rotationVariation	= 360		-- RANDOM ROTATION
		Properties.rotationChange			= 10		-- ROTATION CHANGE PER SECOND
		Properties.weight							= 0.03  -- PARTICLE WEIGHT (>0 FALLS DOWN, <0 WILL RISE UPWARDS)
		Properties.emissionShape			= 1 		-- 0 = POINT, 1 = LINE, 2 = RING, 3 = DISC
		Properties.killOutsideScreen	= false	-- PARENT LAYER MUST NOT BE NESTED OR ROTATED! 
		Properties.lifeTime						= 20000	-- MAX. LIFETIME OF A PARTICLE
		
		Properties.emissionShape		= 1
		Properties.emissionRadius		= 222
		Particles.CreateParticleType ("particleLine", Properties)

		local numSmokeParticles = 50
		if _G.iPhone then numSmokeParticles = 25 end		-- use fewer particles for the older iPhones to avoid a lag
		Particles.AttachParticleType("stampEmitter", "particleLine", numSmokeParticles, 20000, smokeDelay ) -- trigger 300 ms early
		
		-- CREATE A GROUP:
		particleGroup = display.newGroup( )
		coverArt:insert(particleGroup)
		
		-- PUT EMITTER INTO GROUP:
		particleGroup:insert( Particles.GetEmitter("stampEmitter") )
	end		
	
	local stamp
	if _G.liteVer then -- different "stamp" used on lite vs. production versions
	  stamp = display.newImage(coverArt, imgDir .. "stamp.png", 289, 281, true)
	else
		stamp = display.newImage(coverArt, imgDir .. "stamp.png", 289, 301, true)
	end
	stamp:setReferencePoint(display.CenterReferencePoint)
	local stampStartScale = 5
	stamp.xScale=stampStartScale
	stamp.yScale=stampStartScale
	stamp.alpha=0
	
	local auth_illus = display.newImage(coverArt, imgDir .. "author_illustrator.png", 380, 897+120, true)
	auth_illus:setReferencePoint(display.TopLeftReferencePoint)
	
	local free_spirit = display.newImage(coverArt, imgDir .. "free_spirit.png", -170, 940, true) 
	free_spirit:setReferencePoint(display.TopLeftReferencePoint)
	
	-- add a mask for the left and right edges, in case we're in Landscape rotation
	-- we need to hide the images that are off-screen when in Portrait orientation,
	-- they're not offscreen in Landscape
	local maxWH = math.max(coverArt.screenWidth,coverArt.screenHeight)					-- get the widest value of width or height
	local rightEdge = coverArt.screenWidth
	local bottomEdge = coverArt.screenHeight
	local leftMaskRect = display.newRect(coverArt, 0, 0, maxWH, maxWH ) 
	leftMaskRect:setFillColor(0,0,0)	--(255,0,0)
	leftMaskRect:setReferencePoint(display.TopRightReferencePoint)
	leftMaskRect.y = 0
	leftMaskRect.x = 0
	local rightMaskRect = display.newRect(coverArt, 0, 0, maxWH, maxWH ) 
	rightMaskRect:setFillColor(0,0,0)	--(0,255,0)
	rightMaskRect:setReferencePoint(display.TopLeftReferencePoint)
	rightMaskRect.y = 0
	rightMaskRect.x = rightEdge
	local bottomMaskRect = display.newRect(coverArt, 0, 0, maxWH, maxWH ) 
	bottomMaskRect:setFillColor(0,0,0)	--(0,0,255)
	bottomMaskRect:setReferencePoint(display.TopLeftReferencePoint)
	bottomMaskRect.y = bottomEdge
	bottomMaskRect.x = 0

	--	fade background
	if not restartFlag then
		transition.dissolve( defaultPng, background, 600, backgroundDelay )
	else
		transition.to( background, { time=600, delay=backgroundDelay, alpha = 1, transition = easing.linear })
	end



	------------------------------------------------------------
	-- Start the animation
	------------------------------------------------------------
	
	-- Drop down black masthead section
	local tDelay = backgroundDelay + 200
	local mastheadDelay = 500
	
	transition.to(masthead, { delay=tDelay, time=mastheadDelay, y=0, transition=easing.inOutQuad } )
	
	lastDelay = tDelay + mastheadDelay
	tDelay = 500
	typeDelay = 60
	
	-- Move the MSC title in place plus the rectangles to cover the letters
	transition.to(maskRect1, { delay=lastDelay, time=0, y=190, transition = easing.linear } )
	transition.to(maskRect2, { delay=lastDelay, time=0, y=274, transition = easing.linear } )
	transition.to(msc, { delay=lastDelay, time=0, y=125, transition = easing.linear } )
	timer.performWithDelay(lastDelay-300, function() audio.play( swishSnd ) end)
	
	-- Uncover the letters, one at a time using table data
	for i = 1,#mask1 do
		local bX,bY = unpack(mask1[i], 1, 2)
		tDelay = lastDelay + typeDelay*i*2
		transition.to(maskRect1, { delay=tDelay, time=typeDelay, x=bX, y=bY, transition = easing.linear } )
		timer.performWithDelay(tDelay, function() audio.play( typeSnd ) end)
	end
	timer.performWithDelay(tDelay, function() audio.play( typeReturnSnd ) end )
	lastDelay = tDelay+700
	for i = 1,#mask2 do
		local bX,bY = unpack(mask2[i], 1, 2)
		tDelay = lastDelay + typeDelay*i*2
		transition.to(maskRect2, { delay=tDelay, time=typeDelay, x=bX, y=bY, transition = easing.linear } )
		timer.performWithDelay(tDelay, function() audio.play( typeSnd ) end )
	end
	lastDelay = tDelay
	
	-- Slide in the title on the orange bar
	transition.to(title, { delay=lastDelay, time=500, x=0, transition = easing.inOutQuad } )
	timer.performWithDelay(lastDelay+200, function() audio.play( titleswishSnd ) end )
	lastDelay = lastDelay + 500
	
	-- Increase the scale of "Book 1" and shrink it to 1
	local scale = 1.25
	tDelay = 100
	transition.to(book_1, { delay=lastDelay, time=0, transition = easing.linear } )
	transition.to(book_1, { delay=lastDelay+tDelay, time=500, xScale=scale, yScale=scale, transition = easing.inOutQuad } )
	timer.performWithDelay(lastDelay+tDelay+300, function() audio.play( bellSnd ) end )
	lastDelay = lastDelay + tDelay + 500
	scale = 1
	transition.to(book_1, { delay=lastDelay, time=250, xScale=scale, yScale=scale, transition = easing.inOutQuad } )
	lastDelay = lastDelay + 250
	
	-- Scale down the stamp.
	scale = 1
	transition.to(stamp, { delay=lastDelay+tDelay, time=400, xScale=scale, yScale=scale, alpha=1, transition = easing.linear } )
	lastDelay = lastDelay + tDelay + 500
	
	if Particles then		-- if Particle Candy is installed, then trigger the effect
		-- Turn on the particles. One shot emission is set to true so all of the smoke appears immediately.
		Particles.StartEmitter("stampEmitter",true)
	end

	-- Stamp impact sound effect	
	timer.performWithDelay(lastDelay-100, function() audio.play( stampSnd ) end )
	
	-- Ratchet up the author and illustrator names
	timer.performWithDelay(lastDelay+tDelay+100, function() audio.play( rollSnd ) end )
	for i = 0,2 do
		transition.to(auth_illus, { delay=lastDelay+tDelay+640*i, time=200, y=897+42.333333333333333*(2-i), transition = easing.inOutQuad } )
	end
	lastDelay = lastDelay+tDelay+640+640 + 300
	
	-- Slide in the Free Spirit logo
	transition.to(free_spirit, { delay=lastDelay, time=500, x=1, transition = easing.inOutQuad } )
	timer.performWithDelay(lastDelay+300, function() audio.play( titleswishSnd, { onComplete=cleanupSound } ) end )
	lastDelay = lastDelay + 500
	--print("Last delay ="..lastDelay)
	
	return lastDelay -- return the length of the entire animation to the calling routine so it knows how long to wait
	
end

return Cover
