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
-- frames.lua - double-tap (to zoom) hot-spot rectangles for each frame. 
-- 		 Also includes hotspots for web URLs and email links
-- 
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--
-- Notes: Every page must be listed, but not every movement on the page. For
-- example, in some frames, we may have 2-3 camera moves (as defined in
-- coordinates.lua), but may only need 1 tapable rectangle filling the frame. In
-- the cases where the number of camera moves does not match the number of tappable
-- rectangles, or we need to overlay a rectangle on top of another rectangle, we
-- include an extra value to indicate which coordinates to zoom in on.
-- 
-- Within each element: x_position, y_position, frame_width, frame_height [, frame_number ]|[, link_flag, link_URL]
-- link_flag meanings:
--    -1= outside web URL, open in Safari
--    -2= open web URL in popup
--    -3= open email in the Mail app
--    -4= iTunes link
--

local frames = 
{
	[0] = {},								-- no tapable area on the cover page
  [1] = { 								-- 2 tapable areas on page 1
		{ 40,0,470,707}, 
		{ 520,78,472,630}, 
	},
	[2] = {
		{ 46,90,326,246}, 
		{ 386,87,337,249}, 
		{ 44,339,681,401}, 
		{ 47,743,326,247}, 
		{ 391,745,329,242}, 
	},
	[3] = {
		{ 46,0,444,550}, 
		{ 489,0,234,549}, 
		{ 46,553,686,471,4}, 	-- since these rectangles are drawn in the order listed, when they
		{ 46,577,438,121,3}, 	-- overlap, draw the bigger one first and add frame_number info
	},
	[4] = {
		{ 45,0,666,529}, 
		{ 41,69,170,238}, 
		{ 47,529,671,223}, 
		{ 47,765,673,223}, 
	},
	[5] = {
		{ 49,89,327,283}, 
		{ 392,88,329,283}, 
		{ 51,390,323,273}, 
		{ 396,390,327,274}, 
		{ 49,682,672,305}, 
	},
	[6] = {
		{ 33,83,279,288}, 
		{ 311,81,421,293}, 
		{ 39,379,691,294}, 
		{ 34,673,417,324}, 
		{ 456,676,282,324}, 
	},
	[7] = {
		{ 49,87,674,280,1}, 	-- not every coordinate set has a corresponding touchable rectangle
		{ 46,384,218,285,3}, 	-- on this page, so we need to number them all to indicate
		{ 269,374,233,305,4}, -- where to zoom in to
		{ 514,384,211,281,5}, 
		{ 45,685,225,302,6}, 
		{ 287,685,209,305,7}, 
		{ 509,684,215,306,8}, 
	},
	[8] = {
		{ 34,32,687,346}, 
		{ 46,379,312,613}, 
		{ 377,381,346,281}, 
		{ 375,676,349,314}, 
	},
	[9] = {},
	[10] = {},
	[11] = {
		{}, 
	},
	[12] = {
		{}, 
	},
	[13] = {	-- these pages have no touch-zoom areas. Because the 5th value is <0, we know they indicate a URL will follow
		{ 213,131,171,49, -2, "http://AnnieFox.com"}, 		-- open in pop-up window
		{ 42,178,141,194, -2, "http://AnnieFox.com"}, 
		{ 242,351,146,29, -2, "http://CruelsNotCool.org"}, 
		{ 351,379,171,30, -2, "http://FamilyConfidential.com"}, 
		{ 643,369,62,44, -4, "://itunes.apple.com/us/podcast/family-confidential-secrets/id313148780"}, -- launch iTunes app, go to this page
		{ 313,443,126,30, -2, "http://AnnieFox.com"}, 
		{ 95,478,276,56, -2, "http://facebook.com/Annie.Fox.author"}, 
		{ 423,478,225,56, -2, "http://twitter.com/Annie_Fox"}, 
		{ 42,610,141,194, -2, "http://MattKindt.com"}, 
		{ 243,559,171,49, -2, "http://MattKindt.com"}, 
		{ 451,809,137,34, -2, "http://MattKindt.com"}, 
	},
	[14] = {
		{ 244,128,224,50, -2, "http://www.freespirit.com"}, 
		{ 40,181,198,82, -2, "http://www.freespirit.com"}, 
		{ 95,453,291,63, -2, "http://facebook.com/freespiritpublishing"}, 
		{ 423,453,254,63, -2, "http://twitter.com/FreeSpiritBooks"}, 
		{ 254,558,224,49, -2, "http://ElectricEggplant.com"}, 
		{ 41,609,141,130, -2, "http://ElectricEggplant.com"}, 
		{ 95,928,275,62, -2, "http://facebook.com/ElectricEggplant"}, 
		{ 423,928,254,62, -2, "http://twitter.com/ElectrcEggplant"}, 
	},
	[15] = {},
	[16] = {
		{ 281,131,224,49, -2, "http://www.freespirit.com/catalog/item_detail.cfm?ITEM_ID=623"}, 
		{ 522,207,132,72, -2, "http://www.freespirit.com/catalog/item_detail.cfm?ITEM_ID=684"}, 
		{ 489,326,240,341, -2, "http://www.freespirit.com/catalog/item_detail.cfm?ITEM_ID=696"}, 
		{ 263,199,256,341, -2, "http://www.freespirit.com/catalog/item_detail.cfm?ITEM_ID=684"}, 
		{ 42,139,235,341, -2, "http://www.freespirit.com/catalog/item_detail.cfm?ITEM_ID=623"}, 
		{ 519,663,204,54, -2, "http://www.freespirit.com/catalog/item_detail.cfm?ITEM_ID=696"}, 
		{ 89,764,588,66, -2, "http://www.freespirit.com"}, 
		{ 437,974,240,42, -3, "mailto:help4kids@freespirit.com?subject=Be%20Confident%20App%20Email"}, -- email link
	},
	[17] = {},
}

return frames

