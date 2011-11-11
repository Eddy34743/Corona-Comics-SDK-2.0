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
-- Reader.lua - the framework code, or the guts of the comic reader, loads pages, 
-- 		 handles all camera moves and page changes, has sound routines, and more
-- 
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--

module(..., package.seeall)

------------------------------------------------------------
-- Set-up
------------------------------------------------------------
local imgUIDir = "images/ui/"
if _G.device ~= "android" then
	removeAllPages = {}							-- forward declare function

	-- Add low memory event handler to remove pages immediately if there's a warning
	local function handleLowMemory( event )		-- this only works in iOS
		timer.performWithDelay(1500, removeAllPages)
	end
	 
	Runtime:addEventListener( "memoryWarning", handleLowMemory )

end

local lastScale = 0

local Object = Runtime.Object

local kTime = 350	-- how long most transitions will last


------------------------------------------------------------
-- Routines to recursively remove display objects/groups
------------------------------------------------------------
local coronaMetaTable = getmetatable(display.getCurrentStage())
-- Returns whether aDisplayObject is a Corona display object.
-- note that all Corona types seem to share the same metatable, which is used for the test.
-- @param aDisplayObject table - possible display object.
-- @return boolean - true if object is a display object
isDisplayObject = function(aDisplayObject)
	return (type(aDisplayObject) == "table" and getmetatable(aDisplayObject) == coronaMetaTable)
end

-- Function will bottom-up recursively removeSelf all display objects and groups that may be part of objectOrGroup, before removeSelf'ing itself.
-- @param objectOrGroup a display object or group to be removeSelf'ed with all its possible members.
local function cleanGroups ( objectOrGroup )
	if (not isDisplayObject(objectOrGroup)) then return end
	if objectOrGroup.numChildren then
		-- we have a group, so first clean that out
		while objectOrGroup.numChildren > 0 do
			-- clean out the last member of the group (work from the top down!)
			cleanGroups ( objectOrGroup[objectOrGroup.numChildren])
		end
	end
--  Do we also need to remove the touch and tap objects? Currently not doing that.
--	if objectOrGroup.touch then 
--		print("Object had touch event, remove it")
--		objectOrGroup:removeEventListener( "touch", Reader )
--	end
--	if objectOrGroup.tap then 
--		print("Object had tap event, remove it")
--		objectOrGroup:removeEventListener( "tap", Reader )
--	end
	-- we have either an empty group or a normal display object - remove it
	objectOrGroup:removeSelf()
	objectOrGroup = nil
	return
end



-------------------------------------------------------------------------------

local Frame = Object:new()

------------------------------------------------------------
-- Initialize the frame
------------------------------------------------------------
function Frame:initialize()
	local view = display.newGroup()
	self.view = view

	-- Center view in content
	local contentW = display.contentWidth
	local contentH = display.contentHeight

	local halfContentW = 0.5*contentW
	local halfContentH = 0.5*contentH
	view.x = halfContentW
	view.y = halfContentH

	-- max dimension 
	local unit = ( contentH > contentW ) and contentH or contentW
	self.unit = unit

	-- length needs to be long enough to cover diagonal of screen
	-- and also be an even integer
	local len = 2 * unit
	self.len = len

	-- Insert rects and position relative to view's origin
	local top = display.newRect( -halfContentW, -halfContentH, len, 0 )
	view:insert( top )
	local bottom = display.newRect( -halfContentW, halfContentH, len, 0 )
	view:insert( bottom )
	local left = display.newRect( -halfContentW, -halfContentH, 0, contentH )
	view:insert( left )
	local right = display.newRect( halfContentW, -halfContentH, 0, contentH )
	view:insert( right )

	view.top = top
	view.bottom = bottom
	view.left = left
	view.right = right
end


------------------------------------------------------------
-- Math function - floor (not used?)
------------------------------------------------------------
local function floor( a )
	return a - a%1
end


------------------------------------------------------------
-- Set the boundaries of the frame, crop with masking rectangles
------------------------------------------------------------
function Frame:setBounds( w, h, animate )
	local view = self.view

	local contentW = display.contentWidth
	local contentH = display.contentHeight
	-- only exchange values if we're not on the simulator. Work-around for Corona bug?
	if _G.isDeviceLandscape and system.getInfo( "environment" ) ~= "simulator" then
		contentW,contentH = contentH,contentW
	end

	-- Force h to be even integer
	h = math.ceil(h)
	if math.mod( h, 2 )~= 0 then
		h = h + 1
	end

	-- view group is at the center of the content bounds 
	local len = self.len
	local wNew = 0.5*(len - w)
	local hNew = 0.5*(len - h)

	local xNew = 0.5*(w + wNew)
	local yNew = 0.5*(h + hNew)
	h = h + 2	-- add extra pixels to avoid the gaps during transition
						-- fixes gaps, but during transition to full page we now see faint black line 
						-- at intersection where two rectangles overlap

	view.top.x = 0
	view.bottom.x = 0
	if animate then
		transition.to( view.top, { height=hNew, y=-yNew, time=kTime, transition=easing.inOutQuad } )
		transition.to( view.bottom, { height=hNew, y=yNew, time=kTime, transition=easing.inOutQuad } )
	else
		local top = view.top
		top.height = hNew
		top.x = 0
		top.y = -yNew

		local bottom = view.bottom
		bottom.height = hNew
		bottom.x = 0
		bottom.y = yNew
	end

	if animate then
		transition.to( view.left, { width=wNew, height=h, x=-xNew, y=0, time=kTime, transition=easing.inOutQuad } )
		transition.to( view.right, { width=wNew, height=h, x=xNew, y=0, time=kTime, transition=easing.inOutQuad } )
	else	
		local left = view.left
		left.width = wNew
		left.height = h
		left.x = -xNew
		left.y = 0
	
		local right = view.right
		right.width = wNew
		right.height = h
		right.x = xNew
		right.y = 0
	end
end

------------------------------------------------------------
-- Set the color and alpha of the masking rectangles
------------------------------------------------------------
function Frame:setColor( ... )
	local view = self.view
	local alpha = 255													-- Debug values:
	view.top:setFillColor( 0,0,0,alpha )			--   120,0,0
	view.bottom:setFillColor( 0,0,0,alpha )		--   0,120,0
	view.left:setFillColor( 0,0,0,alpha )			--   0,0,120
	view.right:setFillColor( 0,0,0,alpha )		--   200,0,0
end

-------------------------------------------------------------------------------



local Reader = Object:new()         
                                 
------------------------------------------------------------
-- Routines to play the UI sounds
------------------------------------------------------------
-- Play sound on free channel
local function playSound(sound, volume)
	if not volume then volume = 1 end
	local channel = audio.findFreeChannel()
	if channel then
		audio.setVolume( volume, { channel=channel } )
		audio.play( sound, { channel=channel } )
	end
end

-- UI sound effect for moving to next/previous frame or page
local function frameChangeSound()
	if _G.showFullPages or _G.currentPage >= firstAboutPage then	-- always use page turn sound on About pages
		playSound( sndUIPageTurn )
	else
		playSound( sndUIBeep1 )
	end
end

-- UI sound effect for zooming in or out
local function zoomSound()
	if _G.showFullPages then
		playSound( sndUIZoom1In, .3 )
	else
		playSound( sndUIZoom1Out, .3 )
	end
end



------------------------------------------------------------
-- Initialize the Reader
-- reader:initialize( basename, data [, startPage, options] )
--
-- Options:
--  loadLastPage - should we load the bookmarked last page?
--  minPage - do not go earlier than this page number
--  maxPage - do not go past this page number
--  frameNum - go to this specific frame
--  fadeIn - if true, fade in from a black screen
--  doubleTapped - store flag from saved game so double-tap help message doesn't show up again
--  infoTapped - store flag from saved game so info-tap help message doesn't show up again
--  
------------------------------------------------------------
function Reader:initialize( basename, data, startPage, options )
	local contentWidth = display.contentWidth
	local contentHeight = display.contentHeight
	local viewableContentWidth, viewableContentHeight = display.viewableContentWidth, display.viewableContentHeight
	local isLandscape = _G.isDeviceLandscape
	local frameNum = 0
	local fadeIn = false
	-- only exchange values if we're not on the simulator. Work-around for Corona bug?
	if isLandscape and system.getInfo( "environment" ) ~= "simulator" then
		contentWidth,contentHeight = contentHeight, contentWidth
	end

	self.basename = basename
	self.data = data     
	self.loadLastPage = false
	self.minPage, self.maxPage = nil, nil
	-- check for passed option parameters
	if options then
		if options.loadLastPage == true then
			self.loadLastPage = true           		
		end
		if options.minPage then		-- do not go earlier than this page
			self.minPage = options.minPage
		end
		if options.maxPage then		-- do not go past this page
			self.maxPage = options.maxPage
		end
		if options.frameNum then	-- go to a specific frame
			frameNum = options.frameNum
		end
		if options.fadeIn then		-- fade in from black screen
			fadeIn = options.fadeIn
		end
		if options.doubleTapped then		-- store whether saved game had double-tapped stored
			self.doubleTapped = options.doubleTapped
		end
		if options.infoTapped then			-- store whether saved game had infoTapped stored
			self.infoTapped = options.infoTapped
		end
	end

	local view = display.newGroup()
	self.view = view
	if isLandscape then
		view:translate( 0.5*contentHeight, 0.5*contentWidth )
	else
		view:translate( 0.5*contentWidth, 0.5*contentHeight )
	end

	-- set up touchable rectangle that covers the screen (for page navigation)
	local maxWH = math.max(contentWidth,contentHeight)						-- get the widest value of width or height
	local fullscreenRect = display.newRect( 0, 0, maxWH, maxWH )	-- wide enough so it works in landscape mode as well!
	fullscreenRect.isHitTestable = true
	fullscreenRect:setFillColor( 0,0,0 )
	fullscreenRect.isVisible = false
	fullscreenRect:addEventListener( "touch", self )
	view:insert( fullscreenRect, true )

	-- store screen size info, and calculate tap margin area
	self.screenW = contentWidth
	self.screenH = contentHeight
	self.maxWH = maxWH
	self.margin = math.ceil(maxWH/10)
	if _G.iPhone then
		self.margin = 10
	elseif _G.iPhone4 then
		self.margin = 20
	end

	local book = display.newGroup()
	view:insert( book )

	local pages = {}
	book.pages = pages

	if _G.hasBalloons then
		local balloons = {}
		book.pages.balloons = balloons
	end

	self.book = book
	self.firstOrientationEventSuppressed = nil
	
	local f = Frame:new()
	f:initialize()
	f:setColor( 0, 0, 0 )
	self.frame = f
	view:insert( f.view, true )
	f.view.alpha = 0

	startPage = startPage or 0
	self:loadPage( startPage, frameNum, { fadeIn = fadeIn } )
	
	-- adjust screen orientation
	self:setOrientation( system.orientation )
end


------------------------------------------------------------
-- Look up and return coordinate data and page number
------------------------------------------------------------
function Reader:loadData( pageNum )

	local data = self.data
	if pageNum < 0 then
		pageNum = #data
	end

	return data[pageNum], pageNum
end


------------------------------------------------------------
-- Display the Double-Tap message on page 1, along with 'dot' animation
------------------------------------------------------------
local function doubleTapAnimation(page)
	local page = Reader.book.current
	if page.number == 1 then			-- still on page 1?
		local balGroup = page.balGroup
		local dotImg, doubleTapImg
		if not page.doubleTap then
			dotImg = display.newImage(balGroup,imgUIDir .. "dot.png",0,0,true)
			doubleTapImg = display.newImage(balGroup,imgUIDir .. "double-tap.png",0,0,true)
			page.doubleTap = doubleTapImg
			page.dot = dotImg
			doubleTapImg:setReferencePoint(display.TopLeftReferencePoint)
		else
			doubleTapImg = page.doubleTap
			dotImg = page.dot
		end
		
		doubleTapImg.alpha = 0
		dotImg.alpha = 0


		------------------------------------------------------------
		-- Update the position/scale of the double-tap image and dot
		-- based on screen size and orientation
		------------------------------------------------------------
		local function positionDoubleTap()
			local balScale = balGroup.yScale
			local bottomEdge = display.contentHeight/balScale/2
			local doubleTapImgOffsetY = 93/balScale
			if _G.isDeviceLandscape then
				-- only do this if we're not on the simulator. Work-around for Corona bug?
				if system.getInfo( "environment" ) ~= "simulator" then
					bottomEdge = display.contentWidth/balScale/2
				end
				doubleTapImg.xScale = .65
				doubleTapImg.yScale = .65
				doubleTapImg.x = -370
				doubleTapImg.y = bottomEdge-(262*doubleTapImg.yScale) -- actual size of doubleTapImg times scaled size
				dotImg.xScale = .75
				dotImg.yScale = .75
				dotImg.x = doubleTapImg.x+4 --/balScale
				dotImg.y = doubleTapImg.y
			else
				doubleTapImg.x = -400
				doubleTapImg.y = 250
				doubleTapImg.xScale = 1
				doubleTapImg.yScale = 1
				dotImg.x = -396
				dotImg.y = 250
				dotImg.xScale = 1
				dotImg.yScale = 1
			end
		end


		timer.performWithDelay(450, positionDoubleTap)	-- give it a delay so there's time for the orientation changet to take place
		transition.to( doubleTapImg, { delay = 500, alpha = 1, time = 500, transition=easing.inOutQuad } )
		for i = 1500,1900,400 do		-- two beeps, at 1500 and 1900 ms
			timer.performWithDelay(i, function() 
				if  _G.currentPage == 1 and not Reader.doubleTapped then	-- still on page 1?
					positionDoubleTap()	-- update the position/scale of the double-tap image and dot
					playSound( sndUIBeep1 )
					transition.to( dotImg, { alpha = .6, time = 200, transition=easing.inOutQuad } )
					transition.to( dotImg, { delay = 200, alpha = 0, time = 200, transition=easing.inOutQuad } )
				end
			end )
		end
	end
end


------------------------------------------------------------
-- Display the Info Button message on page 1, along with 'dot' animation
------------------------------------------------------------
local function infoTapAnimation()
	local page = Reader.book.current
	if page.number == 1 then			-- still on page 1?
		local balGroup = page.balGroup
		local dotImg, infoTapImg
		local animDelay = 500
		if not Reader.doubleTapped then animDelay = 2300 end	-- don't need to wait for double-tapped animation to finish
		if not page.infoTap then
			infoTapImg = display.newImage(balGroup,imgUIDir .. "info-tap.png",0,0,true)
			dotImg = display.newImage(balGroup,imgUIDir .. "dot.png",0,0,true)
			page.infoTap = infoTapImg
			page.dot2 = dotImg
			infoTapImg:setReferencePoint(display.BottomRightReferencePoint)
			dotImg:setReferencePoint(display.CenterReferencePoint)
		else
			infoTapImg = page.infoTap
			dotImg = page.dot2
		end

		------------------------------------------------------------
		-- Update the position/scale of the info-tap image and dot
		-- based on screen size and orientation
		------------------------------------------------------------
		local function positionInfoTap()
			local balScale = balGroup.yScale
			local bottomEdge = display.contentHeight/balScale/2
			local rightEdge = display.contentWidth/balScale/2
			local infoTapImgOffsetX = 27/balScale
			local infoTapImgOffsetY = 24/balScale
			local dotImgOffsetX = 26.3/balScale --/balScale*2
			local dotImgOffsetY = 25.9/balScale
	--		print("rightEdge, dotImgOffsetX",rightEdge, dotImgOffsetX)
			if _G.isDeviceLandscape then
				-- only change values if we're not on the simulator. Work-around for Corona bug?
				if system.getInfo( "environment" ) ~= "simulator" then
					bottomEdge = display.contentWidth/balScale/2
					rightEdge = display.contentHeight/balScale/2
				end
				infoTapImg.x = rightEdge-infoTapImgOffsetX
				infoTapImg.y = bottomEdge-infoTapImgOffsetY
				infoTapImg.xScale = .65
				infoTapImg.yScale = .65
				dotImg.x = rightEdge-dotImgOffsetX
				dotImg.y = bottomEdge-dotImgOffsetY
				dotImg.xScale = .75
				dotImg.yScale = .75
			else
				infoTapImg.x = 480		-- 512 is the right edge
				infoTapImg.y = bottomEdge-infoTapImgOffsetY
				infoTapImg.xScale = 1
				infoTapImg.yScale = 1
				dotImg.x = 512-dotImgOffsetX
				dotImg.y = bottomEdge-dotImgOffsetY
				dotImg.xScale = 1
				dotImg.yScale = 1
			end
		end

		infoTapImg.alpha = 0
		dotImg.alpha = 0
		timer.performWithDelay(animDelay, function()
			if Reader.infoTapped or Reader.infoTapSeen then return end	-- Info button has been tapped, or message seen no need to display it
			if _G.currentPage == 1 and not Reader.infoTapped and _G.showFullPages then
				positionInfoTap()
				transition.to( infoTapImg, { alpha = 1, time = 500, transition=easing.inOutQuad } )
				timer.performWithDelay(1000, function() 
					positionInfoTap()	-- update the position/scale of the info-tap image and dot
					if  _G.currentPage == 1 and not Reader.infoTapped and _G.showFullPages then	-- still on page 1?
						Reader.infoTapSeen = true
						playSound( sndUIBeep1 )
						transition.to( dotImg, { alpha = .6, time = 200, transition=easing.inOutQuad } )
						transition.to( dotImg, { delay = 200, alpha = 0, time = 200, transition=easing.inOutQuad } )
					else
						infoTapImg.alpha = 0
					end
				end )
			end
		end )
	end
end


------------------------------------------------------------
-- Load a page and its data into memory 
-- (or if it's already there, make sure settings are correct)
------------------------------------------------------------
function Reader:loadPage( pageNum, frameNum, options )
	local book = self.book
	local pages = book.pages
	local page = pages[pageNum]
	local fadeIn = false
	if options then
		if options.fadeIn then		-- fade in from black screen
			fadeIn = options.fadeIn
		end
	end
	_G.currentPage = pageNum	-- store in global variable for control issues
	_G.currentFrame = 0

	if not page or (page and not page.removeSelf) then
		-- lazily load page
		local data, pageImg
		data, pageNum = self:loadData( pageNum )

		if data then
			page = display.newGroup()
			local basename = self.basename .. pageNum
			local hires = ""
			if _G.hires then		-- should we use the hires or lores images?
				hires = pageSize[pageNum]
			end
			pageImg = display.newImage( page, basename .. hires .. ".jpg",0,0,true )		-- insert new page image into page group
					
			pages[pageNum] = page -- add into array of pages
			book:insert( page, true )
			if math.max(pageImg.width,pageImg.height) > 1024 then
				pageImg.xScale = .5
				pageImg.yScale = .5
			end
			pageImg.x = 0
			pageImg.y = 0
			pageImg.centerX = pageImg.width/2
			pageImg.centerY = pageImg.height/2
						
			page.data = data
			page.number = pageNum
			
			local sData = sound[pageNum]
			page.sound = sData

			page.balGroup = display.newGroup()
			local balGroup = page.balGroup
			view = self.view
			view:insert( balGroup, true )
			local pageOffsetX, pageOffsetY = pageImg.xScale*pageImg.centerX, pageImg.yScale*pageImg.centerY

			if _G.hasBalloons then
				local bData = balloonsTable[pageNum]
				local balloons = {}
				page.balloons = balloons
				local balloonSet
				if #bData > 1 then						-- balloons not used on pages with less than 2 frames
					local spriteSize = "@2x"		-- for iPad, iPhone 4, NOOKColor
					if _G.iPhone then spriteSize = "" end		-- use lores spritesheets for iPhone 3
					local spriteImg = "Page" .. pageNum .. spriteSize
					local spriteFile = spriteImg		-- tried putting these files in a separate folder, works fine on simulator, breaks on iPad (build 2011.619)
					local balloonData = require(spriteFile)
					local spriteData = balloonData.getSpriteSheetData()
					local spriteCount = #spriteData.frames
		
					local balloonSprite = sprite.newSpriteSheetFromData( "images/sprites/" .. spriteImg .. ".png", spriteData )
					balloonSet = sprite.newSpriteSet(balloonSprite,1,spriteCount)
					for i = 1,spriteCount do		-- set up pointers to each of the balloons
						sprite.add(balloonSet,i,i,1,1,0)
					end
					page.balloonSprite = balloonSprite		-- save handle to sprite sheet so we can dispose it later
				end
				
				-- Load balloon data
				-- if your graphic novel doesn't use separate balloons, may want to consider rewriting this section
				for i = 1,#bData do
					local bArray = bData[i]
					if #bArray>0 then
						local bNum,bX,bY,bW,bH,preScaled = unpack(bArray, 1, 6)
						balloons[i] = sprite.newSprite(balloonSet)
						balGroup:insert( balloons[i], false )
						if not preScaled and not iPhone then					-- for balloons that are not going to scale up, we'll use
							balloons[i].xScale = .5
							balloons[i].yScale = .5
						end
						balloons[i].x = bX-pageOffsetX + bW/2 --384 	--hack because sprite positioning is off
						balloons[i].y = bY-pageOffsetY + bH/2 -- 512
						balloons[i].bX = bX
						balloons[i].bY = bY
						balloons[i].bW = bW
						balloons[i].bH = bH
						balloons[i].bxMax = bX + bW
						balloons[i].byMax = bY + bH
						balloons[i]:prepare(bNum)
					else	-- no balloons for this frame, so just load tiny place-holder png.
						balloons[i] = display.newImage("images/sprites/null.png")
					end
				end
			end

			if fadeIn then
				page.alpha = 0
				transition.to( page, { alpha=1, time=kTime, transition=easing.inOutQuad } )
				balGroup.alpha = 0
				if not _G.showFullPages then
					transition.to( balGroup, { alpha=1, time=kTime, transition=easing.inOutQuad } )
				end
			end

			-- set up touchable zoom-in rectangles for each frame
			local fData = frames[pageNum]
			local borderOverlap
			for i = 1,#fData do
				local fArray = fData[i]
				if #fData>0 then
					local fX,fY,fW,fH,targetFrame,fURL = unpack(fArray, 1, 6)
					if fX then
						borderOverlap = border - fX
						if borderOverlap > 0 then								-- make sure the double-tap region doesn't overlap the page turn region
							fX = border
							fW = fW - borderOverlap
						end
						if (fX + fW) > pageImg.width - border then fW = pageImg.width - fX - border end
						local tapRect = display.newRect( balGroup, 0, 0, fW, fH )
						if targetFrame == nil then
							targetFrame = i
						end
						tapRect.isHitTestable = true
						tapRect:setFillColor( 255,0,0,128)
						tapRect.isVisible = false
						if fURL then										-- if there's a URL, store it in the rectangle
							if targetFrame == -4 then			-- iTunes link, check for platform
								if _G.device == "android" then
									fURL = "http" .. fURL
									targetFrame = -2					-- Android dev can't go into the iTunes store, so switch to standard URL
								else
									fURL = "itms" .. fURL
								end
							end
							tapRect.URL = fURL
							tapRect:addEventListener( "touch", self )
						else
							if _G.device == "android" then
								tapRect:addEventListener( "touch", self )
							else
								tapRect:addEventListener( "tap", self )
							end
						end
						tapRect:setReferencePoint(display.TopLeftReferencePoint)
						tapRect.x = fX-pageOffsetX
						tapRect.y = fY-pageOffsetY
						tapRect.targetFrame = targetFrame
					end
				end
			end
		end
	else
		page.alpha = 1
		page.xOrigin = 0
		page.yOrigin = 0
		page.xReference = 0
		page.yReference = 0
		page.balGroup.alpha = 1
		page.balGroup.xOrigin = 0
		page.balGroup.yOrigin = 0
		page.balGroup.xReference = 0
		page.balGroup.yReference = 0
	end

	if ( page ) then
		book.current = page		
		if(frameNum) then
			page.index = frameNum
		else
			page.index = 0 -- show entire page
		end
	end
	return page
end


------------------------------------------------------------
-- Update first frame and on orientation. Play the sound only 
-- the first time, otherwise no need to trigger sounds again.
------------------------------------------------------------
function Reader:invalidateFrame( params )
	local suppressSound, fadeIn, suppressAnimation = false, false, false
	if params then
		if params.suppressSound then suppressSound = params.suppressSound end
		if params.fadeIn then fadeIn = params.fadeIn end
		if params.suppressAnimation then suppressAnimation = params.suppressAnimation end
	end
	if (self and self.book) then
		local page = self.book.current
		local index = page.index
		if page.number == 0 then
			suppressSound = false
		end	-- don't do this for the start of the book
		self:showFrame( index, { orientationChange = true, suppressSound = suppressSound, fadeIn = fadeIn, suppressAnimation = suppressAnimation } )
	end
end


------------------------------------------------------------
-- Remove a page from memory, along with its balloons
-- Uncomment code below if you want to watch memory handling.
------------------------------------------------------------
function Reader:removePage( pgNumber, params )
	local infoPage = false
	if params and params.infoPage then infoPage = true end
		
	if _G.currentPage == pgNumber then return false end
	if pgNumber >= 0 and pgNumber < #self.data or infoPage then
--		print( "TextureMemory: " .. system.getInfo("textureMemoryUsed")/1024 .. " Kbytes")
		local losePage = self.book.pages[pgNumber]
		if losePage and losePage.removeSelf then 
--			print( "TextureMemory start: " .. system.getInfo("textureMemoryUsed")/1024 .. " Kbytes" )
--			print("dropping page "..pgNumber)
			local loseBalGroup = losePage.balGroup
			if _G.hasBalloons then
				local loseBalloons = losePage.balloons
				local loseSpritesheet = losePage.balloonSprite
				for i = #loseBalloons,1,-1 do
					loseBalloons[i]:removeSelf()
					loseBalloons[i] = nil
				end
				loseBalloons = nil
				if loseSpritesheet then loseSpritesheet:dispose() end
			end
			cleanGroups(loseBalGroup)
			losePage:removeSelf()
			losePage = nil
      collectgarbage("collect")
--      timer.performWithDelay(1, function()
--				print("collect garbage "..collectgarbage("count"))      
--				print( "TextureMemory finished: " ..  system.getInfo("textureMemoryUsed")/1024 .. " Kbytes" )
--				for i = 0,#self.data do						-- debug: what pages are still in memory?
--					losePage = self.book.pages[i]
--					if losePage and losePage.removeSelf then
--						print("in mem",i)
--					end
--				end
--			end)
		end			
	end
	return true
end


------------------------------------------------------------
-- Remove all pages (except current one) - received memory warning 
------------------------------------------------------------
function removeAllPages()
--	print("Memory low, removing all pages")
	local losePage
	for i = 0,#Reader.data do
		losePage = Reader.book.pages[i]
		if losePage and losePage.removeSelf then
			Reader:removePage( i )
		end
	end
end


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Jump to a page, or move to the next or previous page
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- Jump to a specific page and Frame:initialize
-- Used from main.lua when we want to jump to a chapter or Return to book
------------------------------------------------------------
function Reader:gotoPage(pageNum, frameNum, options)
	local page = self.book.current
	local aboutFlag, suppressAnimation = false, false
	if options then
		if options.minPage then		-- do not go earlier than this page
			self.minPage = options.minPage
		end
		if options.maxPage then		-- do not go past this page
			self.maxPage = options.maxPage
		end
		if options.aboutFlag then	-- currently not being used here
			aboutFlag = options.aboutFlag
		end
		if options.suppressAnimation then
			suppressAnimation = options.suppressAnimation
		end
	end
	local balGroup = page.balGroup
	
	local index = 0
	if frameNum then index = frameNum end
	-- Show entire next page

	local newPage = self:loadPage( pageNum )
	if newPage then
		self:showFrame( index, {suppressAnimation = suppressAnimation} )
	else                                   
		newPage = self:loadPage( 0 )	-- load cover
		self:showFrame( 0 ) 					-- hide frame
	end

	local newBalGroup = newPage.balGroup
	transition.to( page, { alpha = 0, time=kTime, transition=easing.linear } )
	transition.to( balGroup, { alpha = 0, time=kTime, transition=easing.linear } )
	transition.from( newPage, { alpha = 0, time=kTime, transition=easing.linear } )
	transition.from( newBalGroup, { alpha = 0, time=kTime, transition=easing.linear } )
	newPage.index = index

	return newPage
end


------------------------------------------------------------
-- Move to the next frame (or page)
-- Called from the touch event
------------------------------------------------------------
function Reader:nextFrame(orientation)       
	if "portraitUpsideDown" == orientation or "landscapeLeft" == orientation then 
		self:prevFrame()
		return
	end
	local page = self.book.current
	if self.maxPage == page.number then
		return
	end
	frameChangeSound()
	local balGroup = page.balGroup
	
-- If full page mode, always go to the next full page
-- If not full page mode, always go to the next frame. 
-- If there is no next frame on the current page, go to the first frame on the next page.
-- If the next page has no frames, just show the full page.	

	local index = page.index + 1
	
	if not _G.showFullPages and ( self:existsFrame( index ) ) then		-- not in full page mode, and there is another frame
		self:showFrame( index )
		page.index = index
	else
		-- Show entire next page if not in full page mode
		
		-- if value stays 0, then either we're in full page mode, or there are no frames on page
		index = 0																													

		-- remove objects for previous page
		Reader:removePage( page.number - 1 )

		if _G.device ~= "android" and not _G.liteVer and page.number == _G.promotePriorPage then		
			-- Check if this is the first time triggered for this pass through the story
			-- and show please rate dialogue. If user accepts, send him to rating link.
			promote.offerRating(_G.promoteFlag, _G.iTunesRatingURL )
		end

		local newPage = self:loadPage( page.number + 1 )
		if newPage then																									-- we have a next page
			local framesOnNewPage = self:existsFrame( 1 )
			if not _G.showFullPages and framesOnNewPage then							-- and we have a next frame and not in full page mode
				index = 1																										-- so show the first frame
			end
			self:showFrame( index, { newPage = true } )										-- passing flag so balloons turn off immediately
		else                                   
			newPage = self:loadPage( 0 ) -- load cover
			self:showFrame( 0 ) -- hide frame
		end

		local newBalGroup = newPage.balGroup
		local transDelay = 	1
		transition.to( page, { delay = transDelay, alpha = 0, time=kTime, transition=easing.inOutQuad } )
		transition.to( balGroup, { delay = transDelay, alpha = 0, time=kTime, transition=easing.inOutQuad } )
		transition.from( newPage, { delay = transDelay, alpha = 0, time=kTime, transition=easing.inOutQuad } )
		transition.from( newBalGroup, { delay = transDelay, alpha = 0, time=kTime, transition=easing.inOutQuad } )
		newPage.index = index
		
	end

	return true
end


------------------------------------------------------------
-- Move to the previous frame (or page)
-- Called from the touch event
------------------------------------------------------------
function Reader:prevFrame(orientation)
	if "portraitUpsideDown" == orientation or "landscapeLeft" == orientation then
		self:nextFrame()
		return
	end
	local page = self.book.current
	--print("self.minPage",self.minPage, page.number)
	if self.minPage == page.number then
		return
	end
	frameChangeSound()
	local balGroup = page.balGroup

-- If full page mode, always go to the previous full page
-- If not full page mode, always go to the previous frame. 
-- If there is no previous frame on the current page, go to the first frame on the previous page.
-- If the previous page has no frames, just show the full page.

	local index = page.index - 1

	if (not _G.showFullPages and index >=1 and self:existsFrame( index ) ) then 
		self:showFrame( index )
		page.index = index
	else
		-- Show entire previous page if not in full page mode

		index = 0

		-- remove objects for previous page
		Reader:removePage( page.number + 1 )

		local newPage = self:loadPage( page.number - 1 )
		if newPage then
			if not _G.showFullPages then									-- in zoom in mode, so get the last frame of previous page
				index = #newPage.data
			end
			self:showFrame( index, { newPage = true } )		-- passing flag so balloons turn off immediately
		else
			newPage = self:loadPage( 0 ) -- load cover
			self:showFrame( 0 ) -- hide frame
		end

		local newBalGroup = newPage.balGroup
		local transDelay = 	1
		transition.to( page, { delay = transDelay, alpha = 0, time=kTime, transition=easing.inOutQuad } )
		transition.to( balGroup, { delay = transDelay, alpha = 0, time=kTime, transition=easing.inOutQuad } )
		transition.from( newPage, { delay = transDelay, alpha = 0, time=kTime, transition=easing.inOutQuad } )
		transition.from( newBalGroup, { delay = transDelay, alpha = 0, time=kTime, transition=easing.inOutQuad } )
		newPage.index = index
	end

	return true
end


------------------------------------------------------------
-- Does the requested next/previous frame exist?
------------------------------------------------------------
function Reader:existsFrame( index )
	local page = self.book.current      
	local data = page.data
	if ( index <= #data ) then
		return true
	else
		return false
	end
end


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Sound Routines
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- Before we play a delayed sound effect, make sure we're 
-- still on the target page/frame
------------------------------------------------------------
local function playDelayedSound(delay, sound, channel, loop, fade_duration, start_volume, targ_volume, page, frame )
	--	print("entering playDelayedSound")
	if page ~= _G.currentPage then return end
	if frame and frame ~= _G.currentFrame then return end
	if channel > audio.reservedChannels then channel = audio.findFreeChannel() end	-- channel not allocated yet
	audio.setVolume( start_volume, { channel=channel } )
	audio.play( sound, { channel=channel, loops=loop } ) 
	if fade_duration > 0 then
		audio.fade({ channel=channel, time=fade_duration, volume=targ_volume } )
		if targ_volume == 0 then	-- see if we should free the channel
			timer.performWithDelay(fade_duration+1, function()													--  so use fade and then check if volume reached 0
				local volume_off = audio.getVolume( { channel=channel } )
				if volume_off <= .01 then
					audio.stop(channel)
				end
			end)
		end
	end
end


------------------------------------------------------------
-- Accept sound data for the current page or frame 
-- and trigger the sound
------------------------------------------------------------
local function soundSetup(page, frame, params)
	local delay, channel, sound, start_volume, targ_volume, fade_duration, loop = params.delay, params.channel, params.sound, params.start_volume, params.targ_volume, params.fade_duration, params.loop
	
	local soundOn
	if not channel then				-- short sound, so we didn't reserve a channel for it
		channel = audio.findFreeChannel()
		if fade_duration or targ_volume then
			fade_duration = nil
			targ_volume = nil
		end
	else
		soundOn = audio.isChannelPlaying( channel )
		if not start_volume and soundOn then
			start_volume = audio.getVolume( { channel = channel } )
		end
		if not start_volume then start_volume = 0 end
	end
	if not targ_volume then targ_volume = start_volume end
	if not fade_duration then fade_duration = 0 end
	if targ_volume ~= start_volume and fade_duration == 0 then start_volume = targ_volume end
	if not soundOn and targ_volume > 0 then
		audio.setVolume( start_volume, { channel=channel } )
		if delay and delay > 0 then																	-- we have a delay before we want to start playing the sound
			timer.performWithDelay(delay, function() 
				playDelayedSound(delay, sound, channel, loop, fade_duration, start_volume, targ_volume, page, frame)
			end)
		else
			audio.play( sound, { channel=channel, loops=loop } )
			if fade_duration > 0 then
				audio.fade({ channel=channel, time=fade_duration, volume=targ_volume } )
			end
		end
	else																													-- sound is already plaing for this channel, we're going to change it
		local current_vol = audio.getVolume( { channel = channel } )
		if soundOn and targ_volume == 0 then												-- fade out channel, but only if it's on
			if fade_duration > 0 then
				audio.fade({ channel=channel, time=fade_duration, volume=targ_volume } )		-- can't use fadeOut since it can't be interrupted,
				timer.performWithDelay(fade_duration+1, function()													--  so use fade and then check if volume reached 0
					local volume_off = audio.getVolume( { channel=channel } )
					if volume_off <= .01 then
						audio.stop(channel)
					end
				end)
			elseif delay and delay > 0 then
				audio.stopWithDelay( delay, { channel = channel }  )
			else			
				audio.setVolume( targ_volume, { channel=channel } )
				audio.stop(channel)
			end
		elseif targ_volume and targ_volume ~= current_vol then												-- change volume level
			-- sound already playing, fade it up
			audio.fade({ channel=channel, time=fade_duration, volume=targ_volume } )  
		end
	end
end


------------------------------------------------------------
-- Grab the sound data for the current page or frame 
-- and pass it on to soundSetup()
------------------------------------------------------------
local function decodeSounds(snds, page, frame)
	local sndData = {}
	for i = 1,#snds do
		sndData = unpack( snds, i, i )
		if sndData then 
			soundSetup(page, frame, sndData)
		end
	end	
end


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Show a frame
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Reader:showFrame( index, params )
	local result = true
	local suppressAnimation, doubleTap, newPage, orientationChange, suppressSound, fadeIn = false, false, false, false, false, false
	if params then
		if params.doubleTap then doubleTap = params.doubleTap end
		if params.suppressAnimation then suppressAnimation = params.suppressAnimation end
		if params.newPage then newPage = params.newPage end
		if params.orientationChange then orientationChange = params.orientationChange end
		if params.suppressSound then suppressSound = params.suppressSound end
		if params.fadeIn then fadeIn = params.fadeIn end
	end
	local page = self.book.current    
	local data = page.data
	local sound = page.sound
	local balGroup = page.balGroup
	local balloons = page.balloons
	local contRect
	_G.infoButtonActive = false 											-- clear debounce if we changed pages, just to be safe
	if fadeIn then suppressAnimation = true end
	if not suppressSound then					-- no need to trigger sound again if page just rotated
		local sndElem = sound[index+1]	-- will be = 1 for whole page, and 2 for first frame on page.
		if sndElem and #sndElem > 0 then
			decodeSounds(sndElem, page.number, index)
		elseif index > 0 then						-- no sound for the frame. Is there any for the page?
			-- no sound found, can we play the page sound?
			sndElem = sound[1]						-- will be = 1 for whole page, and 2 for first frame on page.
			if sndElem then								-- play page sound
				decodeSounds(sndElem, page.number)
			end
		end
	end
	local transTime = kTime
	if suppressAnimation then transTime = 1 end
	if ( 0 == index ) then
		local scale = 1
		if ( page.width > self.screenW ) or ( page.height > self.screenH ) then
			local sx = self.screenW / page.width
			local sy = self.screenH / page.height
			scale = ( sx < sy ) and sx or sy
		end

		-- Check to see if there's a special button or action on this page
		if (page.number == aboutCastPage or page.number == aboutCreditsPage) and not page.contRect then		-- special button for this page: "Continued..."
			page.contRect = true															-- make sure we only add it once
			contRect = display.newRect( 0, 0, 195, 70 )
			contRect.isHitTestable = true
			contRect:setFillColor( 255,0,0,128)
			contRect.isVisible = false
			contRect:addEventListener( "touch", self )
			balGroup:insert( contRect, true )
			contRect:setReferencePoint(display.TopLeftReferencePoint)
			contRect.x = 168
			contRect.y = 387
			contRect.id = "continue"
		elseif page.number == 1 then			-- page 1, put up help messages
			if not self.doubleTapped then		-- put up the Double-Tap message and animation
				timer.performWithDelay(10,doubleTapAnimation)
			end
			if not self.infoTapped then		-- put up the Double-Tap message and animation 
				timer.performWithDelay(10,infoTapAnimation)
			end
		end
		
		-- if this is the Lite version, are we on the page where we ask people to buy the app?
		if _G.liteVer and page.number == buyAppPage then buyAppButtons() end
		
		if _G.hasBalloons and (not page.lastPageMode or doubleTap) then								-- coming from zoom mode to full page, lighten all balloons
			for i = 1,#balloons do
				transition.to( balloons[i], { delay = 1, alpha = 1, time = transTime, transition=easing.inOutQuad } )
			end
		end
		self.scale = scale
		if not doubleTap and _G.showFullPages and scale ~= 1 or (not _G.showFullPages and #data == 0) then
			page.xScale,page.yScale,balGroup.xScale,balGroup.yScale = scale,scale,scale,scale	-- no need to transition to scale if full page
		end

		-- coming from zoom mode to full page, or orietnation change, or on page with no frames, reposition the balloons, etc.
		if doubleTap or orientationChange or #data == 0 or (page.xScale ~= scale) then
			transition.to( balGroup, { delay = 1, alpha = 1, xOrigin = 0, yOrigin = 0, xReference = 0, yReference = 0, xScale = scale, yScale = scale, time=transTime, transition=easing.inOutQuad } )
			transition.to( self.frame.view, { delay = 1, alpha = 0, time=transTime, transition=easing.inOutQuad } )
			transition.to( page, { delay = 1, xOrigin = 0, yOrigin = 0, xReference = 0, yReference = 0, xScale = scale, yScale = scale, time=transTime, transition=easing.inOutQuad } )
		end
	elseif ( index > 0 and index <= #data ) then
		local elem = data[index]
		local x,y,w,h = unpack( elem, 1, 4 )
		local orientation = system.orientation
		local screenMargin = self.margin
		local wMax = self.screenW - screenMargin
		local hMax = self.screenH - screenMargin
		local w2,h2 = w,h
		local balloon
		if _G.hasBalloons then
			balloon = balloons[index]
			
			-- need to recalculate w and h to include the balloons. Store in w2,h2
			-- then use these new values to scale the image even smaller if neccessary
			local nxMin = x
			local nxMax = x + w
			local nyMin = y
			local nyMax = y + h
			local xDif,yDif = 0,0
			if balloon.bX then
				if balloon.bX < nxMin then xDif = nxMin - balloon.bX end
				if balloon.bxMax > nxMax then 
					if balloon.bxMax - nxMax > xDif then xDif = balloon.bxMax - nxMax end
				end
				w2 = w2 + (2*xDif)  
				if balloon.bY < nyMin then yDif = nyMin - balloon.bY end
				if balloon.byMax > nyMax then 
					if balloon.byMax - nyMax > yDif then yDif = balloon.byMax - nyMax end
				end
				h2 = h2 + (2*yDif)
			end
		end

		local pageAspect = w2 / h2
		local screenAspect = wMax / hMax
		local zoomWidth = ( screenAspect < pageAspect )
		local random = math.random
		local scale = (zoomWidth) and (wMax / w2) or (hMax / h2)
		local maxScale = 2.5		-- we don't want to zoom in more than 2.5x or the 2x images will degrade too much
		if scale > maxScale then 
			repeat		-- make sure we don't end up with the same scale twice in a row (triggers Corona transition bug)
				scale = maxScale + random(1000000000)/10000000000
			until scale ~= lastScale
		elseif scale == lastScale then
			repeat		-- make sure we don't end up with the same scale twice in a row (triggers Corona transition bug)
				scale = scale + random(1000000000)/10000000000
			until scale ~= lastScale
		end		-- keep the scale from getting too big
		lastScale = scale
		
		local f = self.frame
		f.view.alpha = 1

		local animate = (not suppressAnimation)

		f:setBounds( scale*w, scale*h, animate )

		if doubleTap then			-- fade in black borders if moving from fullpage to zoom modes
 			transition.from( f.view, { delay = 1, alpha = 0, time=transTime, transition=easing.inOutQuad } )
		end
		
		local bTime = 200
		local bDelay = 100
		if not animate then
			bTime = 1
			bDelay = 1
		end

		if _G.hasBalloons then
			for i = 1,#balloons do
				if i == index then			-- fade up the current frame's balloon
					transition.to( balloon, { alpha = 1, time=bTime, delay=bDelay })
				else										-- fade out the rest of the balloons
					if newPage and (index == 1 or index == #data) or fadeIn then			-- if fadeIn, then must have just loaded app  
						transition.to( balloons[i], { alpha = 0, time=1, delay = 1 })		-- quick transition since we just entered page
					else
						transition.to( balloons[i], { alpha = 0, time=bTime, delay=bDelay })
					end
				end
			end
		end

		local wPage = page.width
		local hPage = page.height
		local xCenter = x + 0.5*w
		local yCenter = y + 0.5*h
		local xNew = 0.5*wPage - xCenter
		local yNew = 0.5*hPage - yCenter
		local xRef = (xCenter-0.5*wPage)
		local yRef = (yCenter-0.5*hPage)
		
		transition.to( page, { delay = 1,xOrigin=xNew, yOrigin=yNew, xReference=xRef, yReference=yRef, xScale=scale, yScale=scale, time=transTime, transition=easing.inOutQuad } )
		transition.to( balGroup, { delay = 1,xOrigin=xNew, yOrigin=yNew, xReference=xRef, yReference=yRef, xScale=scale, yScale=scale, time=transTime, transition=easing.inOutQuad } )
	else
		result = false
	end

	_G.currentFrame = index
	return result
end


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Tap and Touch handlers
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- Handle double-tap events
-- We're not using Corona's built-in double-tap since we
-- needed more flexibility on the timings.
-- Note: not used for Android (not supported).Use touch
-- handler instead.
------------------------------------------------------------
function Reader:tap( event )
	local page = self.book.current
	local index = page.index
	local doubleTap = false
	local maxDelta = 500
	local currentTime = system.getTimer()
	local touchBorder = border
	if not self.lastTap then self.lastTap = currentTime end
	local deltaTime = currentTime - self.lastTap
	if deltaTime > 10 and deltaTime < maxDelta then		-- got a doubletap!
		doubleTap = true
		self.lastTap = nil
	elseif deltaTime >= maxDelta then									-- too long since last tap, so start over
		self.lastTap = currentTime
	end
	if doubleTap then
		local target = event.target
		local targetFrame = target.targetFrame
		local x,y = event.x,event.y
		if _G.isDeviceLandscape then
			x = y
		end
		zoomSound()
		_G.infoButtonActive = false 				-- clear debounce if we double-tapped, just to be safe
		if index == 0 then									-- we only care if we're on a full page
			_G.showFullPages = false
			page.lastPageMode = false
			page.index = targetFrame
			self:showFrame( targetFrame, { doubleTap = true } )
			if not self.doubleTapped then		-- first double-tap, then remove the double-tap message box
				self.doubleTapped = true
				local page1 = self.book.pages[1]
				if page1 and page1.doubleTap then
					transition.to( page1.doubleTap, { alpha = 0, time = 500, transition=easing.inOutQuad } )
					transition.to( page1.dot, { alpha = 0, time = 500, transition=easing.inOutQuad } )
				end
			end
		-- only zoom out if double tapped on frame we're viewing, and if we're not inside the touchBorder area
		elseif (x > touchBorder and x < (self.screenW - touchBorder)) then
			-- zoom out tap
			_G.showFullPages = true
			page.lastPageMode = true
			page.index = 0
			self:showFrame( 0, { doubleTap = true } )
		end
	end
	return true
end


------------------------------------------------------------
-- Handle touch events
-- We're not using Corona's built-in double-tap since we
-- needed more flexibility on the timings.
------------------------------------------------------------
function Reader:touch( event )
	if not self.book then return end

	local phase = event.phase
	local startPos = 0
	local target = event.target
	if "began" == phase then
		self.touchStartPosX = event.x
		self.touchStartPosY = event.y
		if _G.device == "android" then	-- no Android Corona tap event support yet, so try to capture it here instead
			local page = self.book.current
			local index = page.index
			local doubleTap = false
			local maxDelta = 500
			local currentTime = system.getTimer()
			local touchBorder = border
			if not self.lastTap then self.lastTap = currentTime end
			local deltaTime = currentTime - self.lastTap
			if deltaTime > 10 and deltaTime < maxDelta then		-- got a doubletap!
				doubleTap = true
				self.lastTap = nil
			elseif deltaTime >= maxDelta then									-- too long since last tap, so start over
				self.lastTap = currentTime
			end
			if doubleTap then
				local targetFrame = target.targetFrame
				if targetFrame then										-- only act on double-tap if person tapped on panel hotspot
					local x,y = event.x,event.y
					if _G.isDeviceLandscape then
						x = y
					end
					zoomSound()
					_G.infoButtonActive = false 				-- clear debounce if we double-tapped, just to be safe
					if index == 0 then									-- we only care if we're on a full page
						_G.showFullPages = false
						page.lastPageMode = false
						page.index = targetFrame
						self:showFrame( targetFrame, { doubleTap = true } )
						if not self.doubleTapped then			-- first double-tap, then remove the double-tap message box
							self.doubleTapped = true
							local page1 = self.book.pages[1]
							if page1 and page1.doubleTap then
								transition.to( page1.doubleTap, { alpha = 0, time = 500, transition=easing.inOutQuad } )
								transition.to( page1.dot, { alpha = 0, time = 500, transition=easing.inOutQuad } )
							end
						end
					-- only zoom out if double tapped on frame we're viewing, and if we're not inside the touchBorder area
					elseif (x > touchBorder and x < (self.screenW - touchBorder)) then
						_G.showFullPages = true
						page.lastPageMode = true
						page.index = 0
						self:showFrame( 0, { doubleTap = true } )
					end
				end
			end
			return true
		end
	else
		local resetStartPos = true

		if "ended" == phase then
			local x,y = event.x,event.y
			startPos = self.touchStartPosX
			local endPos = x
			local orientation = system.orientation
			if _G.isDeviceLandscape then
				startPos = self.touchStartPosY				
				endPos = y
			end

			local delta = 50
			local touchBorder = border
			if _G.currentPage == 0	-- give them a really wide border on the title page
				then touchBorder = 170
			end
			if startPos and endPos < (startPos - delta) then				-- swipe left, next frame
				self:nextFrame(orientation)
			elseif startPos and endPos > (startPos + delta) then		-- swipe right, previous frame
				self:prevFrame(orientation)
			elseif endPos > (self.screenW - touchBorder) or event.target.id == "continue" then		-- clicked near the right edge or Continue...
				self:nextFrame(orientation)
			elseif endPos < touchBorder then												-- clicked near the left edge
				self:prevFrame(orientation)
			elseif target and target.URL then												-- web URL or email link
				local linkType = target.targetFrame
				local URL = target.URL
				openNetWindow(URL, linkType)
			end
		elseif "cancelled" == phase then
		else
			resetStartPos = false
		end

		if resetStartPos then
			self.touchStartPosX = nil
			self.touchStartPosY = nil
		end
	end
	return true
end


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Orientation
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- Handle an orientation change.
-- If animate == false, then just snap to position instead
-- of rotate transition.
-- Note: Not currently supported for NOOK Color so locked
-- in Portrait orientation.
------------------------------------------------------------
function Reader:setOrientation( orientation, animate, delta )
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
	if _G.model == "nookcolor" then		-- no orientation change on NOOK Color
		animate = false
		_G.isDeviceLandscape = false
		orientation = "portrait"
		if delta then delta = 0 end
	end
	_G.infoButtonActive = false 											-- clear debounce if we rotated the device, just to be safe
	local rotation = angles[orientation]
	if self.view.rotation > 360 or self.view.rotation < 0 then 	-- if paused, sometimes this value gets crazy big/small
		self.view.rotation = 0 -- maybe set to proper value?
		animate = false
	end
	if rotation < 0 then
		animate = false
		if not self.firstOrientationEventSuppressed then 
			rotation = angles[_G.lastOrientation]	-- don't skip skip if faceUp or faceDown and this is first time through, set to initial orientation
		else
			return				-- skip if we moved into faceUp or faceDown territory
		end
	else							-- don't change landscape flag if we're flat
		_G.isDeviceLandscape = ("landscapeLeft" == orientation or "landscapeRight" == orientation)
		_G.lastOrientation = orientation
	end

	self.screenW = display.contentWidth
	self.screenH = display.contentHeight
	self.screenCenterX = display.contentCenterX
	self.screenCenterY = display.contentCenterY
	-- only exchange values if we're not on the simulator. Work-around for Corona bug?
	if ( rotation == 90 or rotation == 270 ) and system.getInfo( "environment" ) ~= "simulator" then
		self.screenW,self.screenH = self.screenH,self.screenW
		self.screenCenterX,self.screenCenterY = self.screenCenterY,self.screenCenterX
	end
	if not delta then animate = false end
	if delta == -90 and rotation == 0 then 
		rotation = 360
	elseif rotation == 270 and delta == 90 then 
		rotation = -90
	elseif delta == 0 and (self.view.rotation == rotation or lastOrientation == orientation) then -- test if rotation/orientation is different than last time
		-- No change, exit
		return
	end

	if animate then
		updateButtonsPosition(300)
		transition.to( self.view, {
				rotation=rotation,
				time=300,
				transition=easing.linear,
				onComplete = 
				function()
					if self.view.rotation >= 360 then		-- if paused, sometimes this value gets crazy big
						self.view.rotation = 0
					elseif self.view.rotation == -90 then
						self.view.rotation = 270
					end
				end})
	else
		-- no animation, update buttons and rotation
		updateButtonsPosition(1)
		self.view.rotation = rotation
	end
	self:invalidateFrame({suppressSound = self.firstOrientationEventSuppressed, fadeIn = not self.firstOrientationEventSuppressed, suppressAnimation = not animate })
	self.firstOrientationEventSuppressed = true			-- we've had our first orientation event so set the flag
end


------------------------------------------------------------
-- This is the actual orientation handler 
------------------------------------------------------------
function Reader:orientation( event )
	self:setOrientation( event.type, true, event.delta )
end
    

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Bookmarking
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- Save user's last page and load it on next application launch
------------------------------------------------------------
local function onSystemEvent( event )

	-- cleanup function needed for NOOK Color
	local timerEnd = function() 
		local t = display.newText("string", -100, -100, native.systemFont, 12)
		transition.to( t, {time = 500, alpha = 0}, function() t.removeSelf() end )
	end

	-- for NOOKcolor, make sure we actually kill the app on quit
	if _G.model == "nookcolor" then
		timer.performWithDelay( 250, timerEnd )
	end


	if Reader.loadLastPage then			-- only execute this if the flag was set in main.lua

		local filePath = system.pathForFile( "msc1prefs.txt", system.DocumentsDirectory )
		if "applicationExit" == event.type or "applicationSuspend" == event.type then
			if event.type == "applicationExit" then
				fadeAllSound(200)
			else		-- must be applicationSuspend
				Runtime:removeEventListener( "orientation", cover.orientation )
				Runtime:removeEventListener( "orientation", Reader )
			end
			if Reader.book and Reader.book.current then
				local file = io.open( filePath, "w" )     
				local page = Reader.book.current			
				local data = {page.number, page.index}   
				local datastring = table.concat(data, ",")

				-- if they exited while on the Info page we store last page visited instead
				-- otherwise they'd lose their place in the book
				if lastPageDisplayed then 				
					page.number = lastPageDisplayed
					page.index = lastFrameDisplayed
				end
				if not Reader.doubleTapped then Reader.doubleTapped = false end

				if file then
						file:write( "page="..tostring(page.number) .. ", index="..tostring(page.index) .. 
							", showFullPages="..tostring(_G.showFullPages) .. ", doubleTapped="..tostring(Reader.doubleTapped) .. 
							", infoTapped="..tostring(Reader.infoTapped) .. ", promoteFlag="..tostring(_G.promoteFlag) )
					io.close( file )
				 else -- create file b/c it doesn't exist yet 
					local file = io.open( filePath, "w" )     
					file:write( "page="..tostring(page.number) .. ", index="..tostring(page.index) .. 
							", showFullPages="..tostring(_G.showFullPages) .. ", doubleTapped="..tostring(Reader.doubleTapped) .. 
							", infoTapped="..tostring(Reader.infoTapped) .. ", promoteFlag="..tostring(_G.promoteFlag) )
					io.close( file )
				end
			end
		elseif "applicationStart" == event.type then
	
			-- io.open opens a file at filePath. returns nil if no file found
			local file = io.open( filePath, "r" )           
			if file then
				-- read all contents of file into a string
				local contents = file:read( "*a" )				
				io.close( file )
	
				local fields = {}
				for k, v in string.gmatch(contents, "(%w+)=(%w+)") do
					if tonumber(v) then				-- if it's a number then convert to a number, otherwise, as is
						fields[k] = tonumber(v)
					elseif v == "false" then
						fields[k] = false
					elseif v == "true" then
						fields[k] = true
					else
						fields[k] = v
					end
				end							   			 	
				local startPage = fields["page"]
				if not startPage then startPage = 0 end
				local frameNum = fields["index"]
				_G.showFullPages = fields["showFullPages"]
				_G.promoteFlag = fields["promoteFlag"]
				if _G.device == "android" then
					timer.performWithDelay(2000, function()		-- on Android, need to display the startup screen.
						if startPage == 0 then									-- run the opening animation
							startCoverAnimation()
						else
							startBook(startPage,frameNum, { bookmark = true, justLoadedApp = true, doubleTapped = fields["doubleTapped"], infoTapped = fields["infoTapped"] } )
						end
					end)
				else
					if startPage == 0 then									-- run the opening animation without delay on iOS devices
						startCoverAnimation()
					else
						startBook(startPage,frameNum, { bookmark = true, justLoadedApp = true, doubleTapped = fields["doubleTapped"], infoTapped = fields["infoTapped"] } )
					end
				end
			else
				-- create file b/c it doesn't exist yet
				file = io.open( filePath, "w" )      
				io.close( file )
				
				if _G.device == "android" then
					timer.performWithDelay(2000, function()		-- on Android, need to display the startup screen
						startCoverAnimation()
					end)
			else
					startCoverAnimation()
				end
			end
		elseif "applicationResume" == event.type then
			_G.infoButtonActive = false 											-- clear debounce if we woke from sleep, just to be safe
			if Reader.book then
					Runtime:addEventListener( "orientation", Reader )
					Reader:setOrientation( system.orientation, false )
			else
					Runtime:addEventListener( "orientation", cover.orientation )
					cover.setOrientation( system.orientation, false )
			end
		end		
	end
end


Runtime:addEventListener( "system", onSystemEvent )             

return Reader
