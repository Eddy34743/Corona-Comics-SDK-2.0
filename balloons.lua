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
-- Notes: Not every page has a text balloon, and some frames don't have one
-- either. We still need to define an element for every frame on every page,
-- though.
-- 
-- The values are:
-- balloon_number, x_position, y_position, balloon_width, balloon_height [, preScaled_flag]
-- 
-- if preScaled_flag == true, then this balloon was not saved at 2x the final size
-- as the rest are.
-- 
-- The same balloon can appear in multiple frames if necessary.
-- 

local balloons = 
{
	[0] = {},							-- no frames and no balloons on this page
	[1] = {								-- 2 frames, but no balloons on this page
		{},
		{},
	},
	[2] = {								-- 4 frames, with balloos on frames 2 and 4
		{},
		{1,600,81,85,98}, 
		{},
		{2,207,724,154,90},
		{},
	},
	[3] = {
		{1,314,55,283,108}, 
		{2,585,244,221,239},
		{3,52,589,432,105}, 
		{3,52,589,432,105}, 
	},
	[4] = {
		{1,20,67,191,240},	-- Same balloon is displayed in frames 1 and 2
		{1,20,67,191,240},
		{2,355,488,334,168},
		{3,58,837,152,88},
	},
	[5] = {
		{1,262,238,124,136},
		{2,559,102,160,198},
		{3,68,366,233,103},
		{4,492,379,110,113},
		{5,467,634,271,306},
	},
	[6] = {
		{1,191,40,235,129},
		{1,191,40,235,129},
		{2,55,412,598,163, true},	-- This balloon does not need to be displayed at 2x, it already fills the page.
		{3,65,775,146,151},
		{4,435,635,305,365},
	},
	[7] = {
		{1,224,73,143,113},
		{2,614,170,129,79},
		{3,50,373,200,132},
		{4,129,597,102,61},
		{5,490,375,211,154},
		{6,51,693,211,320},
		{7,391,815,92,90},
		{8,487,687,244,142},
	},
	[8] = {
		{1,10,16,377,183}, 
		{2,78,390,132,80}, 
		{3,499,373,238,129}, 
		{4,389,557,353,285}, 
	},
	[9] = {
		{},
	},
	[10] = {
		{},
	},
	[11] = {
		{}, 
	},
	[12] = {
		{}, 
	},
	[13] = {
		{}, 
	},
	[14] = {
		{}, 
	},
	[15] = {
		{}, 
	},
	[16] = {
		{}, 
	},
	[17] = {
		{}, 
	},
}

return balloons
