----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- 
-- Abstract: Corona Comics 2 Demo
-- Be Confident in Who You Are: A Middle School Confidential™ Graphic Novel Lite Version
-- 
-- Version: 2.0.1 (November 8, 2011)

-- Sample code is MIT licensed, see http://developer.anscamobile.com/code/license
-- Copyright (C) 2011 Electric Eggplant. All Rights Reserved.
-- Copyright (C) 2011 ANSCA Inc. All Rights Reserved.
--
-- Images and text excerpted from "Be Confident in Who You Are" by Annie Fox, M.Ed.,
-- (C) 2008. Used with permission of Free Spirit Publishing Inc., Minneapolis,
-- MN; 800-735-7323; www.freespirit.com. All Rights Reserved.
--
-- ABOUT THIS CODE
--This code is based on the November 11, 2010 version of Corona Comics, but with
--lots of bug fixes and many feature enhancements, including:
--
--	* Separate layer for the text balloons, floating on top of the background layer 
--		and above the masking layer. Balloons can be turned on for specific frames.
--	* Balloon layer uses sprites for faster loading and better memory management
--	* Works in both landscape and portrait orientations
--	* Support for 2x resolution (though not using the standard Corona 
--		implementation method)
--	* iOS and Android support (tested on NOOK Color)
--	* Memory management support
--	* Can read through in either full-page mode, or double-tap to switch to 
--		frame-by-frame zoomed-in mode (double-tap again to zoom out)
--	* Info screen (via info button) to let you jump to a specific page 
--	* Automatic bookmarking - remembers where you last were and starts up on 
--		the same page
--	* Sound support - handles multi-channel sound, using different sounds for 
--		full-page mode, or for each frame while zoomed-including
--	* Review this app - watches for when you finish the app and then invites to 
--		rate in iTunes
--	* Help code triggered on page 1 to explain zoomed-in mode and the info button
--	* Message pulled in from a remote website that can appear at the bottom of the 
--		info page
-- 
--	version 2.0.1 - added _G.hasBalloons flag so projects with no balloon layer
--		can be created.
--
-- FILES OVERVIEW:
-- main.lua - includes initialization code, info page
-- 
-- balloons.lua - coordinate and size information for all the text balloons
-- 
-- cover.lua 	- animation of the book cover.
-- 
-- coordinates.lua	- where should the "camera" move for each frame.
-- 
-- device.lua - just lists which OS. This should really be retrieved by checking
-- 		 the device hardware, but I found it easier to manage multiple versions this
-- 		 way.
-- 
-- frames.lua - double-tap (to zoom) hot-spot rectangles for each frame. 
-- 		 Also includes hotspots for web URLs and email links
-- 
-- pageSize.lua - lists which pages are available at 2x size for iPad and iPhone 4
--   (note that this is for the background images only. You'll still need 2x sprites)
--
-- promote.lua - Promotion Library for Corona SDK, Written by Reflare
-- 
-- Reader.lua - the framework code, or the guts of the comic reader, loads pages, 
-- 		 handles all camera moves and page changes, has sound routines, and more
-- 
-- sound.lua - loads the sound files, sets up the tables for controlling all the 
-- 		 sound effects
-- 
-- ui.lua - Corona UI code, with a few mods for hires text buttons
--
--
-- Particle Candy - we use a smoke effect in the cover screen animation. If you
-- own Particle Candy, include the lib_particle_candy.lua and uncomment the require
-- line below.
--
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

_G.device = require("device")
_G.model = ""
if _G.device == "nookcolor" then
	_G.model = "nookcolor"
	_G.device = "android"
end

local imgPageDir = "images/pages/"
local imgCoverDir = "images/cover/"
local imgUIDir = "images/ui/"
if _G.device ~= "android" then
	display.setStatusBar( display.HiddenStatusBar )
	io.output():setvbuf('no')
end

local model = system.getInfo("model")

-- this code may need to be re-written as new devices with different resolutions
-- hit the market.
if _G.device ~= "android" then
	if (display.contentWidth > 640) or model == "iPad" then
		 _G.iPad = true
	elseif (display.contentWidth == 640) or model == "iPhone4" then
		 _G.iPhone4 = true
	else
		 _G.iPhone = true
	end
end
if _G.iPad or _G.iPhone4 then
	_G.hires = true			-- use hires images for iPad and iPhone4
end

----------------------------------------------------------------------------------------------------
-- if you have a Particle Candy license, then uncomment this next line and add 
-- the lib_particle_candy.lua file to the Be Confident folder. The effect is only
-- used in the opening page animation (a smoke effect when the Graphic Novel stamp
-- hits the page).
-- Particles = require("lib_particle_candy")

_G.liteVer = true									-- is this the special Lite version? Disable certain features, change page range.
local startPage = 0
local bookmarking = true												-- do we want to turn on loadLastPage code?
if startPage ~= 0 then bookmarking = false end	-- can't have both!
local startBookDelay = 3												-- needs to be >2 if not using cover animation
_G.showFullPages = true
_G.infoPageButtonsActive = false								-- used to debounce buttons
_G.infoButtonActive = false
local orientation = system.orientation
_G.isDeviceLandscape = "landscapeLeft" == orientation or "landscapeRight" == orientation
_G.lastOrientation = orientation
if _G.lastOrientation == "faceUp" or _G.lastOrientation == "faceDown" then _G.lastOrientation = "portrait" end
_G.hasBalloons = true	-- set to false if your project is not using the balloons layer
_G.coverAnimation = true -- set to false if you want to start on Page0 without the cover animation
border = 50						-- how many pixels to reserve for the border (for tapping to move forward/back)

audio.reserveChannels( 14 )		-- reserve 14 audio channels for manual allocation

if _G.hasBalloons then		-- only need sprites if word balloons are in a separate layer
	require "sprite"
end
if _G.coverAnimation then	-- only need to load the cover animation code if we're going to use it
	cover = require("cover"); startBookDelay = 0
end
local arrow, buttonGroup, infoButton, infoButtonHandler, smallBackBtn
_G.currentPage, _G.currentFrame = -1,0
lastPageDisplayed, lastFrameDisplayed = nil, nil

local ui = require("ui")
data = require ("coordinates")
pageSize = require ("pageSize")

_G.infoPage = #data					-- info page is always the last page
_G.lastPage = #data - 1			-- last story page is 1 less than the info page
_G.promotePriorPage = 43		-- if we move from this page to the next page, trigger the Rate It alert. 
														-- This is the last page of the actual story and before the About pages

-- URL to rate the app. This is the URL for Be Confident in the app store. Replace with your own URL
_G.iTunesRatingURL = "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=428588931"

buyAppPage = nil
firstAboutPage = 44					-- page numbers for the various About pages
aboutCastPage = 44
aboutCreditsPage = 46
local aboutAppPage = 48
local aboutBooksPage = 49

-- URL to pull a text file for the message of the day (week/month, whatever)
local newsFeed = "http://middleschoolconfidential.com/news/msc1.txt"

-- if this is the Lite version, change the numbers of all these pages
if _G.liteVer then
	buyAppPage = 10
	firstAboutPage = 11
	aboutCastPage = 11
	aboutCreditsPage = 13
	aboutAppPage = 15
	aboutBooksPage = 16
	newsFeed = "http://middleschoolconfidential.com/news/msc1lite.txt"
end

sndEffects = {}

reader = require ("Reader")
reader.loadLastPage = bookmarking
startCoverAnimation = {}		-- forward declare function
lastScale = 1
local arrowTransition

local function initCode()
	if _G.hasBalloons then balloonsTable = require ("balloons") end
	frames = require ("frames")
	promote = require("promote")
	sound = require ("sound")
end

-- different startup routine since there's no startup image on Android
startup_background = nil
if _G.device == "android" then			-- put up a startup image to cover the load time
	startup_background = display.newImage("Default-Portrait.png", true)
	local startup_scale = display.contentWidth / startup_background.width
	startup_background.xScale, startup_background.yScale = startup_scale, startup_scale
	startup_background.x = 0.5*display.contentWidth
	startup_background.y = 0.5*display.contentHeight
	timer.performWithDelay(1000, initCode)
else
	initCode()
end


------------------------------------------------------------
-- used to fade all the sound channels
------------------------------------------------------------
function fadeAllSound(fade_duration)
	if not fade_duration then fade_duration = 1000 end
	for i = 1,32 do
		if fade_duration == 0 then
			audio.stop(i)
		else
			audio.fade({ channel=i, time=fade_duration, volume=0 } )
			timer.performWithDelay(fade_duration+1, function()													--  so use fade and then check if volume reached 0
				local volume_off = audio.getVolume( { channel=i } )
				if volume_off <= .01 then
					audio.stop(i)
				end
			end)
		end
	end
end


------------------------------------------------------------
-- After the cover screen startup animation, blnk the arrow
------------------------------------------------------------
local function animateArrow()
	if _G.currentPage == 0 then
		arrow.count = arrow.count + 1
		if arrow.count > 6 then return end		-- blink the arrow button
		local arrowDeltaX = 80								-- how far do we want to slide it on each animation cycle?
		arrow.x=reader.screenCenterX-(arrowDeltaX+10)
		arrow.x=384-(arrowDeltaX+10)
		if _G.isDeviceLandscape then
			arrow.x=(512*reader.screenW/reader.screenH)-(arrowDeltaX+20)
		end
		arrowTransition = transition.to(arrow, { delay=500, time=600, alpha=1, x=arrow.x+arrowDeltaX, transition=easing.inOutQuad, onComplete = 
			function()
				arrowTransition = transition.to(arrow, { time=200, alpha=0, onComplete = 
					function()
						animateArrow()
					end } )
			end } )
	end
end



----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Info Page
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- Remove the buttons on the info page when exiting
------------------------------------------------------------
local function removeButtons(restartFlag)
	if _G.currentPage ~= _G.infoPage or restartFlag then
		local infoPage = reader.book.pages[_G.infoPage]
		if infoPage.newsGroup then
			infoPage.newsGroup:removeSelf()
		end
		reader:removePage( _G.infoPage, { infoPage = true } )
		buttonGroup = nil		-- buttonGroup already removed, but set it to nil as well
		smallBackBtn:removeSelf()
		smallBackBtn = nil
	end	
	if restartFlag then
		infoButton:removeSelf()
		infoButton = nil
		_G.currentPage = -1
		reader.book:removeSelf()
		reader.book = nil 
	end
end

------------------------------------------------------------
-- Play the button-tap sound
------------------------------------------------------------
local function buttonSound(sound,vol)
	channel = audio.findFreeChannel()
	if not vol then vol = .5 end
	audio.setVolume( vol, { channel=channel } )
	audio.play( sound, { channel=channel } )
end


------------------------------------------------------------
-- Send us to the correct page when an About button is tapped
------------------------------------------------------------
local function btnRelease ( event )
	local t = event.target
	local id = t._id
	if _G.infoPageButtonsActive then return end		-- debounce
	_G.infoPageButtonsActive = true
	buttonSound(sndUIClick1,.5)
	if id == "castBtn" then
		reader:gotoPage(aboutCastPage, 0, { minPage = firstAboutPage, maxPage = _G.lastPage, aboutFlag = true })
	elseif id == "creditsBtn" then
		reader:gotoPage(aboutCreditsPage, 0, { minPage = firstAboutPage, maxPage = _G.lastPage, aboutFlag = true })
	elseif id == "aboutAppBtn" then
		reader:gotoPage(aboutAppPage, 0, { minPage = firstAboutPage, maxPage = _G.lastPage, aboutFlag = true })
	elseif id == "aboutBooksBtn" then
		reader:gotoPage(aboutBooksPage, 0, { minPage = firstAboutPage, maxPage = _G.lastPage, aboutFlag = true })
	end
	smallBackBtn.to = "info"
end


------------------------------------------------------------
-- Send us to the correct page when Chapter button is tapped
------------------------------------------------------------
local jumpToChapter = function( event )
	local restartFlag = false
	if _G.infoPageButtonsActive then return end		-- debounce
	_G.infoPageButtonsActive = true
	_G.showFullPages = true
	buttonSound(sndUIClick2,.4)
	local page = 0
	if event.target.page then page = event.target.page end
	if page == 0 and _G.coverAnimation then			-- start over, show animation
		restartFlag = true
		startCoverAnimation(restartFlag)	-- send restart flag
		transition.to(reader.book.current, { alpha = 0, time = 250, alpha = 0, transition = easing.linear } )	-- fade out current page
		transition.to(reader.book.current.balGroup, { time = 250, alpha = 0, transition = easing.linear}) 
		transition.to(buttonGroup, { time = 250, alpha = 0, transition = easing.linear}) 
		transition.to(infoButton, { time = 250, alpha = 0, transition = easing.linear}) 
	else
		reader:gotoPage(page, 0, { minPage = 0, maxPage = _G.lastPage })
		transition.to(infoButton, { time = 250, alpha = 1, transition = easing.linear })
	end
	transition.to(smallBackBtn, { time = 250, alpha = 0, transition = easing.linear })
	_G.infoButtonActive = false
	if page ~= lastPageDisplayed then
		reader:removePage(lastPageDisplayed)
	end
	lastPageDisplayed = nil
	for i = 44,_G.infoPage do
		reader:removePage(i)
	end
	timer.performWithDelay(350, function() removeButtons(restartFlag) end)
end


------------------------------------------------------------
-- Send us to the correct page when a Back button is tapped
------------------------------------------------------------
local gotoBack = function( event )
	local t = event.target
	if t.to == "info" then
		buttonSound(sndUIClick1,.5)
		_G.infoButtonActive = false
		infoButtonHandler()
		t.to = "story"
	else
		if _G.infoPageButtonsActive then return end
		buttonSound(sndUIClick1,.5)
		_G.infoPageButtonsActive = true
		reader:gotoPage(lastPageDisplayed, lastFrameDisplayed, { minPage = 0, maxPage = _G.lastPage, suppressAnimation = true })
		transition.to(smallBackBtn, { time = 250, alpha = 0, transition = easing.linear })
		transition.to(infoButton, { time = 250, alpha = 1, transition = easing.linear })
		_G.infoButtonActive = false
		for i = 44,_G.lastPage do
			if lastPageDisplayed ~= i then
					reader:removePage(i)
			end
		end
		local restartFlag = false
		lastPageDisplayed = nil
		timer.performWithDelay(350, function() removeButtons(restartFlag) end)
	end
end


------------------------------------------------------------
-- Reposition buttons when device is rotated
------------------------------------------------------------
function updateButtonsPosition(transTime)
	if transTime == nil then transTime = 200 end
	if transTime == 0 then transTime = 1 end	-- bug? Won't work if 0
	transition.to(infoButton, { time = transTime, x = reader.screenCenterX, y = reader.screenCenterY, transition = easing.inOutQuad })
	if smallBackBtn then
		local smallBackBtnOffset = smallBackBtn.xScale * 10
		if _G.iPhone or _G.iPhone4 then smallBackBtnOffset = smallBackBtnOffset * .5 end
		transition.to(smallBackBtn, { time = transTime, x = smallBackBtnOffset-reader.screenCenterX, y = smallBackBtnOffset-reader.screenCenterY, transition = easing.inOutQuad })
	end
	if arrowTransition then
		transition.cancel(arrowTransition)
		arrowTransition = nil
		arrow.alpha = 0
		animateArrow()		-- start it again with its new position
	end
	local view = reader.view
	if view and view.closeWebPopup then
		transition.to(view.closeWebPopup, { time = transTime, y = reader.screenH/2-28, transition = easing.inOutQuad })
	end
end


------------------------------------------------------------
-- Info button was tapped, set up the Info page
------------------------------------------------------------
infoButtonHandler = function( event )
	if _G.infoButtonActive then		-- debounce
		return
	end
	_G.infoButtonActive = true
	_G.infoPageButtonsActive = false					-- entered info page, turn off bounce protect for other buttons
	if not lastPageDisplayed then
		lastPageDisplayed, lastFrameDisplayed = _G.currentPage, _G.currentFrame
	end
	local page1 = reader.book.pages[1]				-- now tapped the Info button, no need to keep help message in memory
	if not reader.infoTapped and page1 and page1.infoTap then
		local loseInfoTap = page1.infoTap
		if loseInfoTap and loseInfoTap.removeSelf then
			loseInfoTap:removeSelf()
			page1.infoTap = nil
		end
	end
	reader.infoTapped = true
	local page = reader:gotoPage(_G.infoPage, 0, { minPage = _G.infoPage, maxPage = _G.infoPage })
	fadeAllSound(1000)

	-- add the buttons to the screen
	if not buttonGroup or not buttonGroup.removeSelf then
		local btnFontSize, btnOffset = 34, 1
		if system.getInfo( "environment" ) == "simulator" then btnOffset = -3 end	-- work-around for Corona bug
		local font_name = "SF Slapstick Comic"
		if _G.device == "android" and system.getInfo( "environment" ) ~= "simulator" then
			font_name = "SF_Slapstick_Comic"
			btnOffset = -1
		end
		local castBtn = ui.newButton{
			default = imgUIDir .. "buttonOrange.png",
			over = imgUIDir .. "buttonOrangeOver.png",
			onRelease = btnRelease,
			font = font_name,
			text = "About the Cast",
			id = "castBtn",
			size = btnFontSize,
			offset = btnOffset,
			emboss = true,
			retina = true
		}

		local creditsBtn = ui.newButton{
			default = imgUIDir .. "buttonOrange.png",
			over = imgUIDir .. "buttonOrangeOver.png",
			onRelease = btnRelease,
			font = font_name,
			text = "Credits",
			id = "creditsBtn",
			size = btnFontSize,
			offset = btnOffset,
			emboss = true,
			retina = true
		}

		local aboutAppBtn = ui.newButton{
			default = imgUIDir .. "buttonOrange.png",
			over = imgUIDir .. "buttonOrangeOver.png",
			onRelease = btnRelease,
			font = font_name,
			text = "About the App",
			id = "aboutAppBtn",
			size = btnFontSize,
			offset = btnOffset,
			emboss = true,
			retina = true
		}

		local aboutBooksBtn = ui.newButton{
			default = imgUIDir .. "buttonOrange.png",
			over = imgUIDir .. "buttonOrangeOver.png",
			onRelease = btnRelease,
			font = font_name,
			text = "About the Books",
			id = "aboutBooksBtn",
			size = btnFontSize,
			offset = btnOffset,
			emboss = true,
			retina = true
		}

		local backBtn = ui.newButton{
			default = imgUIDir .. "buttonGreen.png",
			over = imgUIDir .. "buttonGreenOver.png",
			onRelease = gotoBack,
			font = font_name,
			text = "Back to Story",
			id = "backBtn",
			size = btnFontSize,
			offset = btnOffset,
			emboss = true,
			retina = true
		}

		local infoButtonScale = 1
		if _G.iPhone then
			infoButtonScale = .75
		elseif _G.iPhone4 then
			infoButtonScale = 1.5
		end
		
		smallBackBtn = ui.newButton{ 
			default = imgUIDir .. "backButton.png", 
			over = imgUIDir .. "backButton_over.png",
			id = "smallBackBtn",
			onRelease = gotoBack
		}
		smallBackBtn:setReferencePoint(display.TopLeftReferencePoint)
		smallBackBtn.to = "story"
		smallBackBtn.alpha = 0
		smallBackBtn.xScale, smallBackBtn.yScale = infoButtonScale, infoButtonScale
		page.smallBackBtn = smallBackBtn 	-- so we can find it to remove later
		

		local buttonsX = 0
		local buttonsY = 0
		local buttonSpacing = 65
		local buttonScale = .85
		if not _G.iPad and not _G.model == "nookcolor" then
			buttonSpacing, buttonScale = 75, 1.0
		end
		castBtn.x = buttonsX; castBtn.y = buttonsY
		creditsBtn.x = buttonsX; creditsBtn.y = buttonsY+buttonSpacing*1
		aboutAppBtn.x = buttonsX; aboutAppBtn.y = buttonsY+buttonSpacing*2
		aboutBooksBtn.x = buttonsX; aboutBooksBtn.y = buttonsY+buttonSpacing*3
		backBtn.x = buttonsX; backBtn.y = buttonsY+buttonSpacing*4
		buttonGroup = display.newGroup()
		buttonGroup.alpha = 0
		buttonGroup:insert(castBtn)		-- insert all buttons but the smallBackBtn
		buttonGroup:insert(creditsBtn)
		buttonGroup:insert(aboutAppBtn)
		buttonGroup:insert(aboutBooksBtn)
		buttonGroup:insert(backBtn)
		page.balGroup:insert(buttonGroup)

		-- add the chapter buttons
		local chapterBtn = {}
		local scaleAdjust = 1/buttonScale		-- get back to full size for these buttons
		local chapterStart = {0,4,10,16,21,26,30,34,39}
		if _G.liteVer then
			chapterStart = {0,4,10,10,10,10,10,10,10}
		end
		local chapterBtnSpacing = 75
		local chapterBtnXStart = -340
		local chapterBtnYStart = 400
		if not _G.iPad and not _G.model == "nookcolor" then
			chapterBtnSpacing, chapterBtnXStart, chapterBtnYStart = 85, -374, 540
		end
		for i = 0,8 do
		  chapterBtn[i] = ui.newButton{
				default = imgUIDir .. "buttonCh"..i..".png",
				over = imgUIDir .. "buttonCh"..i.."Over.png",
				onRelease = jumpToChapter,
				emboss = false
			}
			chapterBtn[i].x = (i*chapterBtnSpacing + chapterBtnXStart) * scaleAdjust
			chapterBtn[i].y = chapterBtnYStart
			chapterBtn[i].xScale = scaleAdjust
			chapterBtn[i].yScale = scaleAdjust
			chapterBtn[i].page = chapterStart[i+1]
			buttonGroup:insert(chapterBtn[i])
		end

		buttonGroup.xScale = buttonScale
		buttonGroup.yScale = buttonScale
		buttonGroup.x = 41
		buttonGroup.y = -177
		local view = reader.view
		view:insert(smallBackBtn)	-- make sure we only do this once
		transition.to(buttonGroup, { delay = 100, time = 250, alpha=1, transition = easing.linear })
		if _G.device ~= "android" then
			timer.performWithDelay(360, function()		-- keep here to only check once the page is loaded first time, not on return from About pages
				if _G.currentPage == _G.infoPage then
					-- are we online and have we reached the end and not rated?
					if _G.device ~= "android" and promote.checkRatingStatus() > 0 and _G.promoteFlag and not _G.liteVer then
						promote.offerRating(_G.promoteFlag, _G.iTunesRatingURL )
					elseif promote.testNetConn() and _G.iPad then				-- rating or news, but not both, and don't display news on iPhone (not yet)
						-- Download News from our server, display with slide in effect
						-- if new news found
						promote.displayNews(newsFeed,view)
					end
				end
			end)	
		end
	end
	updateButtonsPosition(1)
	transition.to(infoButton, { time = 250, alpha=0, transition = easing.linear })
	transition.to(smallBackBtn, { time = 350, alpha=1, transition = easing.linear })
end



----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Open web popup overlays
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- Can we open the requested URL?
------------------------------------------------------------
testNetworkConnection = function ( URL, linkType )
	-- default messages for accessing a website
	local alertTitle = "Internet Error"
	local alertMsg = "Could not connect to this website. Please check your Internet connection or try again later."
	if linkType == -3 then return true end		-- email type, we don't care if they're online, let them fill out the email now
	if linkType == -4 then										-- iTunes type, adjust message
		alertTitle = "No Internet"
		alertMsg = "Could not access iTunes. Please check your Internet connection."
		URL = nil			-- use eletriceggplant.com as default
	end
	
	if not URL then
		URL = "electriceggplant.com"		-- please replace this domain with your own domain
	else
		local spliturl = promote.strsplit("://",URL)
		URL = spliturl[2]
		spliturl = promote.strsplit("/",URL)
		URL = spliturl[1]
	end
	local netConn = require('socket').connect( URL, 80)
	netConn:close()
	if not netConn then
		-- Offline...
		local function onComplete( event )
			if "clicked" == event.action then
				local i = event.index
			end
		end
		
		local alert = native.showAlert(alertTitle, alertMsg, {"OK"}, onComplete)
		return false
	end
	-- Online...
	return true
end

------------------------------------------------------------
-- Remove web popup window
------------------------------------------------------------
local function closePopup( event )
	local phase = event.phase
	if phase == "ended" then
		native.cancelWebPopup()
		local closeWebPopup = reader.view.closeWebPopup
		local coverscreenRect = reader.view.coverscreenRect
		if not coverscreenRect.fadeFlag then		-- avoid double-tapping of this (debounce)
			buttonSound(sndUIClick1,.5)						-- only want one click sound
			coverscreenRect.fadeFlag = true
			coverscreenRect.isHitTestable = false
			transition.to( closeWebPopup, { time=300, alpha = 0, transition=easing.linear, onComplete = 
				function()
					if closeWebPopup and closeWebPopup.removeSelf then
						closeWebPopup:removeSelf()
						closeWebPopup = nil
					end
				end } )
			transition.to( coverscreenRect, { time=300, alpha = 0, transition=easing.linear, onComplete = 
				function()
					if coverscreenRect and coverscreenRect.removeSelf then
						coverscreenRect:removeSelf()
						coverscreenRect = nil
					end
				end } )
		end
	end	
	return true
end


------------------------------------------------------------
-- Display web popup window or redirect to proper URL
------------------------------------------------------------
function openNetWindow(URL, linkType)
	local touchBorder = border
	local view = reader.view
	buttonSound(sndUIClick1,.5)
	if testNetworkConnection(URL, linkType) then						-- are we online?
		if linkType == -1 then																-- -1 = outside web URL
			system.openURL(URL)
		elseif linkType == -2 then														-- -2 = web URL in popup
			native.showWebPopup( touchBorder,0,reader.screenW - touchBorder*2,reader.screenH - 50, URL )
			local contentWidth = display.contentWidth
			local contentHeight = display.contentHeight
			local maxWH = math.max(contentWidth,contentHeight)						-- get the widest value of width or height
			local coverscreenRect = display.newRect( 0, 0, maxWH, maxWH )	-- wide enough so it works in landscape mode as well!
			coverscreenRect.isHitTestable = true
			coverscreenRect:setFillColor( 0,0,0 )
			coverscreenRect.isVisible = true
			coverscreenRect:addEventListener( "touch", closePopup )
			coverscreenRect.touch = closePopup
			coverscreenRect.alpha = 0
			transition.to( coverscreenRect, { time=300, alpha = .5, transition=easing.linear } )
			view:insert( coverscreenRect, true )
			view.coverscreenRect = coverscreenRect
	
			local btnFontSize, btnOffset = 32, 1
			if system.getInfo( "environment" ) == "simulator" then btnOffset = -3 end	-- work-around for Corona bug
			local font_name = "SF Slapstick Comic"
			if _G.device == "android" and system.getInfo( "environment" ) ~= "simulator" then
				font_name = "SF_Slapstick_Comic"
				btnOffset = -1
			end
			local closeWebPopup = ui.newButton{
				default = imgUIDir .. "buttonOrange.png",
				over = imgUIDir .. "buttonOrangeOver.png",
				onRelease = closePopup,
				font = font_name,
				text = "Close Window",
				size = btnFontSize,
				offset = btnOffset,
				emboss = true,
				retina = true
			}
			closeWebPopup.alpha = 0
			view:insert(closeWebPopup)
			view.closeWebPopup = closeWebPopup
			closeWebPopup.xScale = .85
			closeWebPopup.yScale = .85
			closeWebPopup.y = reader.screenH/2-28
			transition.to( closeWebPopup, { time=300, alpha = 1, transition=easing.linear } )
		elseif linkType == -3 then														-- -3 = email
			system.openURL(URL)
		elseif linkType == -4 then														-- -4 = iTunes link
			system.openURL(URL)
		end
	end
	return true
end

------------------------------------------------------------
-- Buy the app - redirect to the App Store
------------------------------------------------------------
local function buyApp()
	openNetWindow("itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=428588931", -4)
	return true
end

------------------------------------------------------------
-- Open a web popup and display reviews from our website
------------------------------------------------------------
local function seeReviews()
	openNetWindow("http://middleschoolconfidential.com/reviews.html", -2)
	return true
end



----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Lite version, set up Buy App page
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- Add the buttons to the Buy App page
------------------------------------------------------------
buyAppButtons = function()
	local page = reader.book.pages[buyAppPage]

	if not liteButtonGroup or not liteButtonGroup.removeSelf then
		local btnFontSize, btnOffset = 32, 1
		if system.getInfo( "environment" ) == "simulator" then btnOffset = -3 end	-- work-around for Corona bug
		local font_name = "SF Slapstick Comic"
		if _G.device == "android" and system.getInfo( "environment" ) ~= "simulator" then
			font_name = "SF_Slapstick_Comic"
			btnOffset = -1
		end

		local reviewsBtn = ui.newButton{
			default = imgUIDir .. "buttonOrange.png",
			over = imgUIDir .. "buttonOrangeOver.png",
			onRelease = seeReviews,
			font = font_name,
			text = "Read the Reviews",
			size = btnFontSize,
			offset = btnOffset,
			emboss = true,
			retina = true
		}
		reviewsBtn.id = "reviewsBtn"

		local buyAppBtn = ui.newButton{
			default = imgUIDir .. "buttonGreen.png",
			over = imgUIDir .. "buttonGreenOver.png",
			onRelease = buyApp,
			font = font_name,
			text = "Buy the App",
			size = btnFontSize,
			offset = btnOffset,
			emboss = true,
			retina = true
		}
		buyAppBtn.id = "buyAppBtn"

		local buttonsX = 0
		local buttonsY = 0
		local buttonSpacing = 70
		local buttonScale = 1
		reviewsBtn.x = buttonsX; reviewsBtn.y = buttonsY+buttonSpacing*3
		buyAppBtn.x = buttonsX; buyAppBtn.y = buttonsY+buttonSpacing*4
		liteButtonGroup = display.newGroup()
		liteButtonGroup.alpha = 0
		liteButtonGroup:insert(reviewsBtn)
		liteButtonGroup:insert(buyAppBtn)
		page.balGroup:insert(liteButtonGroup)

		liteButtonGroup.xScale = buttonScale
		liteButtonGroup.yScale = buttonScale
		liteButtonGroup.x = 0
		liteButtonGroup.y = 140
		local view = reader.view
		transition.to(liteButtonGroup, { delay = 100, time = 250, alpha=1, transition = easing.linear })
	end
end



----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Start the book
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function startBook(firstPage, firstFrame, options)
	local bookmark, doubleTapped, infoTapped = false, false, false
	if startup_background and startup_background.removeSelf then
		startup_background:removeSelf()
		startup_background = nil
	end
	if options then
		if options.bookmark then				-- fade in from black screen
			bookmark = options.bookmark
		end
		if options.doubleTapped then		-- record whether person has double-tapped to zoom before
			doubleTapped = options.doubleTapped
		end
		if options.infoTapped then			-- record whether person has tapped on the info button, or at least seen the info button message
			infoTapped = options.infoTapped
		end
	end
	if not firstPage then firstPage = startPage end
	if not firstFrame then firstFrame = 0 end
	_G.infoPageButtonsActive = false		-- used to debounce buttons
	_G.infoButtonActive = false
	if not reader.book then
		reader:initialize( imgPageDir .. "Page", data, firstPage, { loadLastPage = bookmarking, minPage = 0, maxPage = _G.lastPage, frameNum = firstFrame, fadeIn = bookmark, doubleTapped = doubleTapped, infoTapped = infoTapped  } )
	end
	reader.firstOrientationEventSuppressed = false		-- may no longer be necessary since we're doing this in the initialze routine
	if startBookDelay > 2 then	-- clear out book images and sound
		if _G.coverAnimation then cover.cleanupImages() end
		arrow = display.newImage(imgCoverDir .. "arrow.png", 0, 0, true)
		arrow:setReferencePoint(display.CenterRightReferencePoint)
		arrow.alpha=0
		reader.doubleTapped = false
		reader.infoTapped = false
		reader.infoTapSeen = false
		local page = reader.book.current
		page.balGroup:insert(arrow)
		arrow.y=0
		arrow.count = 0
		animateArrow()
	end
	
	infoButton = ui.newButton{
		default = imgUIDir .. "info.png",
		over = imgUIDir .. "info_over.png",
		onRelease = infoButtonHandler,
		id = "info"
	}
	local view = reader.view
	view:insert(infoButton)
	infoButton:setReferencePoint(display.BottomRightReferencePoint)
	infoButton.alpha = 0
	updateButtonsPosition(1)
	local infoButtonSize = 1
	if _G.iPhone then
		infoButtonSize = .6
	elseif _G.iPhone4 then
		infoButtonSize = 1.2
	end
	infoButton.xScale = infoButtonSize 
	infoButton.yScale = infoButtonSize 
	transition.to(infoButton, { delay = 100, time = 250, alpha=1, transition = easing.linear })
	
	if _G.coverAnimation then
		Runtime:removeEventListener( "orientation", cover.orientation )
	end
	Runtime:addEventListener( "orientation", reader )
end

----------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------
local function main( event )
	local page = _G.currentPage
	if arrow and page > 0 then
		if arrowTransition then
			transition.cancel(arrowTransition)
		end
		arrow:removeSelf()
		arrow,arrowTransition = nil,nil
	end	
end


----------------------------------------------------------------
-- Ready to animate the cover - do it!
----------------------------------------------------------------
function startCoverAnimation(restartFlag)
	_G.showFullPages = true
	_G.promoteFlag = true			-- set to true when we restart from title screen animation
	if _G.coverAnimation then
		if startup_background and startup_background.removeSelf then
			startup_background:removeSelf()
			startup_background = nil
		end
		startBookDelay = cover.coverAnimation(restartFlag)	-- trigger cover animation
		Runtime:addEventListener( "orientation", cover.orientation )
		if Particles then		-- if Particle Candy is installed, start updating particles
			Particles.StartAutoUpdate()
		end
	end
	timer.performWithDelay(startBookDelay,function() startBook() end)
end


----------------------------------------------------------------
-- Run the Program
-- only do this if bookmarking is turned off.
-- Otherwise the this will be handled by onSystemEvent in Reader
----------------------------------------------------------------

if not bookmarking then
	if startPage == 0 then		-- call cover animation
		startCoverAnimation()
	else	-- startPage not 0
		startBook()
	end
end
Runtime:addEventListener( "enterFrame", main )
