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
-- balloons.lua - coordinate and size information for all the text balloons.
-- 
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--
-- First 14 channels are reserved for music, ambient and other looping sounds:
-- 
-- channel 1-2		-- music channels
-- channel 3-6		-- ambient (e.g., outdoor background sound)
-- channel 7-14		-- looping sounds
-- channels 15-32 -- open channels for UI, repeating sounds, or quick sounds
-- 
-- We could change the allocation, but be sure to also change the
-- 	audio.reserveChannels( 14 )
-- line in main.lua
-- 
-- Notes:
-- Each page can have sounds defined for both zoomed-out mode, as well as sounds
-- for each frame/camera-move. If nothing is defined for a specific frame, it uses
-- the sounds defined for the full page.
-- 
-- Be sure to fade out looping sounds when you move to a page or frame where you no
-- longer wish to hear it. For example, if there's a sound played in a specific
-- frame but it shouldn't play for the full page, then the full page definition
-- should include a fade out of that sound, as should adjacent frames, and adjacent
-- pages (if this is the first or last frame on a page).
-- -- 
-- Make sure you're not using the same channel for two different sounds at the same
-- time. Best practice would be to not use the same channel in adjacent
-- pages/frames so sounds don't step on each other. This is especially important if
-- you want cross fading between two sounds.
-- 
-- 
-- Parameters that can be included in the table:
--   channel - which channel to play the sound on
--   sound - the handle of the loaded sound, e.g., sndAmbOutdoors
--   start_volume - volume the sound should start at
--   targ_volume - the volume we want the sound to end up at, values of 0-1
--   fade_duration - how long should it take for the sound to reach its targ_volume (in miliseconds)
--   loop - number of times to loop, or -1 if it loops continuously
-- 
-- Additional notes - 9/20/11
-- In the full version of the app we're using audio.loadSound for many of the
-- sounds to speed up the initial load (especially for iPhone and NOOK Color.
-- Recent changes to Corona (after build 605) seem to cause problems here because
-- we're loading too many streams, resulting in "WARNING: Failed to create audio
-- sound()". In this demo version, we were getting an "59Testing error: Invalid
-- Operation" for an unknown reason.
-- 
-- If this isn't fixed in a future build then we may have to load sounds by chapter
-- rather than all at the beginning.
--


local sndDir = "sound/"
local sndExt = ".m4a"
if _G.device == "android" then
	sndExt = ".mp3"
end



------------------------------------------------------------
-- Reserved sound channel allocation
------------------------------------------------------------
local musicCh1 = 1
local musicCh2 = 2
local ambCh1 = 3
local ambCh2 = 4
local ambCh3 = 5
local ambCh4 = 6
local loopCh1 = 7
local loopCh2 = 8
local loopCh3 = 9
local loopCh4 = 10
local loopCh5 = 11
local loopCh6 = 12
local loopCh7 = 13
local loopCh8 = 14


------------------------------------------------------------
-- Load the sounds
------------------------------------------------------------

-- UI sounds, needed throughout the app
sndUIBeep1 = audio.loadSound( sndDir .. "ui_beep_1" .. sndExt )
sndUIClick1 = audio.loadSound( sndDir .. "ui_click_1" .. sndExt )
sndUIClick2 = audio.loadSound( sndDir .. "ui_click_2" .. sndExt )
sndUIPageTurn = audio.loadSound( sndDir .. "ui_page_turn_1" .. sndExt )
sndUIZoom1In = audio.loadSound( sndDir .. "zoom1_in" .. sndExt )
sndUIZoom1Out = audio.loadSound( sndDir .. "zoom1_out" .. sndExt )

-- Chapter-related sounds. Some of these may work better as loadStream
local musicMainTheme = audio.loadSound( sndDir .. "msc_theme" .. sndExt )
local sndAbbyCryFlashback = audio.loadSound( sndDir .. "abby_cry_flashback" .. sndExt )
local sndAmbHouseIndoor = audio.loadSound( sndDir .. "amb_house_indoor_lp" .. sndExt )
local sndAmbOutdoors = audio.loadSound( sndDir .. "amb_outdoor_lp" .. sndExt )
local sndAmbPoolFlashback = audio.loadSound( sndDir .. "amb_pool_flashback_lp" .. sndExt )
local sndAmbSuburbs = audio.loadSound( sndDir .. "amb_suburbs_short" .. sndExt )
local sndBasketballDribble = audio.loadSound( sndDir .. "basketball_dribble_01" .. sndExt )
local sndBasketballNet = audio.loadSound( sndDir .. "basketball_net" .. sndExt )
local sndBasketballShoot = audio.loadSound( sndDir .. "basketball_shoot_01" .. sndExt )
local sndBasketballShootDribble = audio.loadSound( sndDir .. "basketball_shoot_02" .. sndExt )
local sndBlender = audio.loadSound( sndDir .. "blender" .. sndExt )
local sndCheerGroup = audio.loadSound( sndDir .. "cheer_group" .. sndExt )
local sndCrowdMurmurSmall = audio.loadSound( sndDir .. "crowd_murmur_small_lp" .. sndExt )
local sndIceInGlass = audio.loadSound( sndDir .. "ice_in_glass_01" .. sndExt )
local sndLoopClappingFriends = audio.loadSound( sndDir .. "clapping_friends" .. sndExt )
local sndLoopPushup = audio.loadSound( sndDir .. "pushup" .. sndExt )
local sndMateoGrowl = audio.loadSound( sndDir .. "Mateo_growl_1" .. sndExt )
local sndMichelleLaugh = audio.loadSound( sndDir .. "michelle_laugh" .. sndExt )


------------------------------------------------------------
-- Sound table
------------------------------------------------------------
local sound =
{
  [0] = { 
		{ {delay = 1000, channel = musicCh1, sound = musicMainTheme, start_volume = 1, loop = -1} }, -- for full page mode
	},

  [1] = { 
		{ {channel = musicCh1, sound = musicMainTheme, start_volume = 0, targ_volume = 1, fade_duration = 2000, loop = -1}, -- for full page
			{channel = ambCh1, targ_volume = 0, fade_duration = 2000 }, -- fade out sndAmbSuburbs from page 2 (if we return to page 1)
			{channel = loopCh3, targ_volume = 0, fade_duration = 1000} },	-- fade out sndLoopClappingFriends from page 2 (if we return to page 1)
	},
	[2] = {
		{ {channel = musicCh1, targ_volume = 0, fade_duration = 2000}, 												-- for full page, fade out musicMainTheme from page 1
			{channel = loopCh3, sound = sndLoopClappingFriends, start_volume = 0, targ_volume = 1, fade_duration = 1000, loop = -1},
			{channel = loopCh4, targ_volume = 0, fade_duration = 500},  -- sndCrowdMurmurSmall
			{channel = loopCh6, targ_volume = 0, fade_duration = 500},  -- sndCheerGroup
			{channel = ambCh1, sound = sndAmbSuburbs, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1} },
		{ {channel = musicCh1, targ_volume = 0, fade_duration = 2000},		 																												-- frame 1, fade-out musicMainTheme from page 1
			{channel = loopCh3, sound = sndLoopClappingFriends, start_volume = 0, targ_volume = 1, fade_duration = 1000, loop = -1},
			{channel = ambCh1, sound = sndAmbSuburbs, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1} },
		{ {channel = loopCh3, sound = sndLoopClappingFriends, start_volume = 0, targ_volume = 1, fade_duration = 1000, loop = -1}, -- frame 2
			{channel = loopCh6, targ_volume = 0, fade_duration = 500},  -- sndCheerGroup
			{channel = ambCh1, sound = sndAmbSuburbs, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1} },
		{ {channel = loopCh3, sound = sndLoopClappingFriends, start_volume = 0, targ_volume = 1, fade_duration = 1000, loop = -1}, -- frame 3
			{delay = 950, channel = loopCh6, sound = sndCheerGroup, start_volume = .7 },
			{channel = ambCh1, sound = sndAmbSuburbs, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},
			{channel = loopCh4, targ_volume = 0, fade_duration = 500},  -- sndCrowdMurmurSmall
		},
		{ {channel = ambCh1, sound = sndAmbSuburbs, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},			-- frame 4
			{channel = loopCh6, targ_volume = 0, fade_duration = 1000},  -- sndCheerGroup
			{channel = loopCh3, targ_volume = 0, fade_duration = 2000},	-- sndLoopClappingFriends
			{channel = loopCh4, sound = sndCrowdMurmurSmall, start_volume = 0, targ_volume = .6, fade_duration = 1000, loop = -1},
			{channel = loopCh5, targ_volume = 0, fade_duration = 500},  -- sndMateoGrowl
		},
		{ {channel = ambCh1, sound = sndAmbSuburbs, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},			-- frame 5
			{channel = loopCh3, targ_volume = 0, fade_duration = 2000},	-- sndLoopClappingFriends
			{channel = loopCh4, sound = sndCrowdMurmurSmall, start_volume = 0, targ_volume = .6, fade_duration = 1000, loop = -1},
			{delay = 350, channel = loopCh5, sound = sndMateoGrowl, start_volume = .5},
		},
	},
	[3] = {
		{ {channel = ambCh1, sound = sndAmbSuburbs, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},	 -- for full page
			{channel = ambCh2, targ_volume = 0, fade_duration = 2000},	-- sndAmbOutdoors
			{channel = loopCh1, targ_volume = 0, fade_duration = 2000},	-- sndBasketballShootDribble
			{channel = loopCh2, targ_volume = 0, fade_duration = 2000},	-- sndBasketballDribble
			{channel = loopCh3, targ_volume = 0, fade_duration = 1000},	-- sndLoopClappingFriends
			{channel = loopCh4, targ_volume = 0, fade_duration = 500},  -- sndCrowdMurmurSmall
			{channel = loopCh5, targ_volume = 0, fade_duration = 500},  -- sndMateoGrowl
		},
	},
	[4] = {	-- chapter 1
		{ {channel = ambCh1, targ_volume = 0, fade_duration = 2000},																								-- for full page, sndAmbSuburbs, 
			{channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},
			{channel = loopCh2, targ_volume = 0},							-- remove sndBasketballDribble before restarting it
			{delay = 700, channel = loopCh1, sound = sndBasketballShootDribble, start_volume = 1},
			{delay = 2700, channel = loopCh2, sound = sndBasketballDribble, start_volume = 1, loop = -1} }, 
		{ {channel = ambCh1, targ_volume = 0, fade_duration = 2000},																												-- frame 1, sndAmbSuburbs
			{channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},
			{channel = loopCh2, start_volume = 0},							-- remove sndBasketballDribble before restarting it
			{delay = 700, channel = loopCh1, sound = sndBasketballShootDribble, start_volume = 1},
			{delay = 2700, channel = loopCh2, sound = sndBasketballDribble, start_volume = 1, loop = -1} },
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 1000, loop = -1},	-- frame 2
			{channel = loopCh2, start_volume = 0},							-- remove sndBasketballDribble before restarting it
			{delay = 500, channel = loopCh2, sound = sndBasketballDribble, start_volume = 1, loop = -1} },
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 1000, loop = -1},	-- frame 3
			{channel = loopCh2, start_volume = 0},							-- remove sndBasketballDribble before restarting it
			{delay = 500, channel = loopCh2, sound = sndBasketballDribble, start_volume = 1, loop = -1} },
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 1000, loop = -1},	-- frame 4
			{channel = loopCh2, start_volume = 0},							-- remove sndBasketballDribble before restarting it
			{delay = 500, channel = loopCh2, sound = sndBasketballDribble, start_volume = 1, loop = -1} },
	},
	[5] = {
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1}, -- for full page
			{channel = ambCh1, targ_volume = 0, fade_duration = 1000}, 	-- sndAmbPoolFlashback
			{channel = loopCh2, targ_volume = 0},										 		-- remove sndBasketballDribble before restarting it
			{delay = 700, channel = loopCh2, sound = sndBasketballDribble, start_volume = 1, loop = -1} },
		{ {delay = 700, sound = sndBasketballShoot, start_volume = 1 },																											-- frame 1
			{channel = loopCh2, start_volume = 0},							-- remove sndBasketballDribble before restarting it
			{delay = 1700, channel = loopCh2, sound = sndBasketballDribble, start_volume = 1, loop = -1} },
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},	-- frame 2
			{channel = loopCh2, start_volume = 0},										 -- remove sndBasketballDribble
			{delay = 700, channel = loopCh2, sound = sndBasketballShootDribble, start_volume = 1},
			{delay = 3700, sound = sndBasketballNet, start_volume = 1 },
			{delay = 5900, channel = loopCh2, sound = sndBasketballDribble, start_volume = 1, loop = -1} },
		{ },																																																								-- frame 3
		{ },																																																								-- frame 4
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},	-- frame 5
			{channel = ambCh1, targ_volume = 0, fade_duration = 1000}, -- sndAmbPoolFlashback
			{channel = loopCh2, start_volume = 0},										 -- remove sndBasketballDribble
			{delay = 700, sound = sndBasketballNet, start_volume = 1 },
			{delay = 2900, channel = loopCh2, sound = sndBasketballDribble, start_volume = 1, loop = -1} },
	},
	[6] = {
		{ {channel = ambCh2, targ_volume = 0, fade_duration = 2000},																	-- for full page, fade-out sndAmbOutdoors
			{channel = ambCh1, sound = sndAmbPoolFlashback, start_volume = 0, targ_volume = .5, fade_duration = 2000, loop = -1},
			{channel = loopCh2, start_volume = 0} },												-- remove sndBasketballDribble
		{ {channel = ambCh2, targ_volume = 0, fade_duration = 2000},			-- frame 1, remove sndAmbOutdoors
			{channel = loopCh2, start_volume = 0},													-- remove sndBasketballDribble
			{channel = ambCh1, sound = sndAmbPoolFlashback, start_volume = 0, targ_volume = .1, fade_duration = 2000, loop = -1} },
		{ {channel = ambCh1, sound = sndAmbPoolFlashback, targ_volume = .3, fade_duration = 2000, loop = -1} },			 				-- frame 2
		{ {channel = ambCh1, sound = sndAmbPoolFlashback, targ_volume = .3, fade_duration = 1000, loop = -1},				 				-- frame 3
			{delay=500, sound = sndIceInGlass, start_volume = 1},
			{delay=1000, sound = sndIceInGlass, start_volume = 1},
			{delay=2500, sound = sndIceInGlass, start_volume = 1},
			{delay=4500, sound = sndIceInGlass, start_volume = 1},
			{delay=7500, sound = sndIceInGlass, start_volume = 1},
			{delay=8200, sound = sndIceInGlass, start_volume = 1},
			{delay=8900, sound = sndIceInGlass, start_volume = 1},
			{channel = loopCh2, targ_volume = 0, fade_duration = 1000}, -- sndAbbyCryFlashback
			},
		{ {channel = ambCh1, sound = sndAmbPoolFlashback, targ_volume = .3, fade_duration = 1000, loop = -1}, 							-- frame 4
			{delay = 750, channel = loopCh2, sound = sndAbbyCryFlashback, start_volume = 1} },
		{ {channel = ambCh2, targ_volume = 0, fade_duration = 2000}, 																												-- frame 5, sndAmbOutdoors
			{channel = loopCh2, targ_volume = 0, fade_duration = 1000}, -- sndAbbyCryFlashback
			{channel = ambCh1, sound = sndAmbPoolFlashback, targ_volume = .1, fade_duration = 2000, loop = -1} }
	},
	[7] = {
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1}, -- for full page
			{channel = loopCh2, targ_volume = 0, fade_duration = 1000}, -- sndMichelleLaugh
			{channel = ambCh1, targ_volume = 0, fade_duration = 700}, -- sndAmbPoolFlashback
		},
		{ }, 																																																								-- frame 1
		{ }, 																																																								-- frame 2
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1}, 	-- frame 3
			{channel = loopCh2, targ_volume = 0, fade_duration = 1000}, -- sndMichelleLaugh
			},
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1}, 	-- frame 4
			{delay = 350, channel = loopCh2, sound = sndMichelleLaugh, start_volume = 1} },
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},	 -- frame 5
			{channel = loopCh2, targ_volume = 0, fade_duration = 1000}, -- sndMichelleLaugh
			{channel = loopCh1, targ_volume = 0, fade_duration = 1000}, -- sndLoopPushup
		},
		{ }, 																																																								-- frame 6
		{ }, 																																																								-- frame 7
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},	-- frame 8
			{channel = loopCh1, targ_volume = 0, fade_duration = 1000},}, -- sndLoopPushup
	},
	[8] = {
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1}, 	-- for full page
			{channel = ambCh1, targ_volume = 0, fade_duration = 1000}, -- sndAmbHouseIndoor
			{channel = loopCh1, targ_volume = 0, fade_duration = 1000}, -- sndLoopPushup
			{channel = loopCh2, targ_volume = 0, fade_duration = 1000}, -- sndBlender
			{channel = musicCh1, targ_volume = 0, fade_duration = 2000} }, -- musicMainTheme
		{ {channel = ambCh2, targ_volume = 0, fade_duration = 1000}, 																												-- frame 1, sndAmbOutdoors
			{channel = ambCh1, sound = sndAmbHouseIndoor, targ_volume = .3, fade_duration = 2000, loop = -1},
			{delay = 700, channel = loopCh1, sound = sndLoopPushup, start_volume = .7, loop = 4},
			{channel = loopCh2, targ_volume = 0, fade_duration = 1000} }, -- sndBlender
		{ {channel = loopCh1, targ_volume = 0, fade_duration = 1000},																												-- frame 2, sndLoopPushup
			{channel = ambCh1, sound = sndAmbHouseIndoor, targ_volume = .3, fade_duration = 2000, loop = -1},
			{channel = loopCh2, sound = sndBlender, start_volume = 1} },
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},	-- frame 3
			{channel = ambCh1, targ_volume = 0, fade_duration = 1000}, -- sndAmbHouseIndoor
			{channel = loopCh2, targ_volume = 0, fade_duration = 1000} }, -- sndBlender
		{ {channel = ambCh2, sound = sndAmbOutdoors, start_volume = 0, targ_volume = .3, fade_duration = 2000, loop = -1},	-- frame 4
			{channel = musicCh1, targ_volume = 0, fade_duration = 2000}, -- musicMainTheme
			{channel = ambCh1, targ_volume = 0, fade_duration = 1000}, -- sndAmbHouseIndoor
		},
	},
  [9] = { 
		{ {channel = ambCh2, targ_volume = 0, fade_duration = 2000}, 																						-- for full page, sndAmbOutdoors
			{channel = musicCh1, sound = musicMainTheme, start_volume = 0, targ_volume = 1, fade_duration = 2000, loop = -1},
			{channel = ambCh1, targ_volume = 0, fade_duration = 1000}, -- sndAmbHouseIndoor
		},
	},
	[10] = {
		{ {channel = musicCh1, sound = musicMainTheme, start_volume = 0, targ_volume = 1, fade_duration = 2000, loop = -1},	-- for full page
		},
	},
	[11] = {
		{{channel = musicCh1, targ_volume = 0, fade_duration = 2000} }  																				-- for full page, musicMainTheme
	},
	[12] = {
	},
	[13] = {
	},
	[14] = {
	},
	[15] = {
	},
	[16] = {
	},
	[17] = {
	},
}

return sound
