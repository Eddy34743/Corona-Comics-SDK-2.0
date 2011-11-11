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
-- coordinates.lua	- where should the "camera" move for each frame.
-- 
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--
-- Each element, [0] through [17] holds frame info for the page of the same number
-- Within each element: x_position, y_position, camera_view_width, camera_view_height
-- 

local data =
{
  [0] = { 								-- if a page has no frames, then empty data
	},

  [1] = { 
		{ 0,0,487,707}, 			-- x, y, w, h for the 1st frame of page 1
		{ 521,58,464,649}, 		-- x, y, w, h for the 2nd frame of page 1
	},

	[2] = {
		{ 46,90,323,245}, 
		{ 388,88,332,244}, 
		{ 44,339,681,400}, 
		{ 47,745,325,244}, 
		{ 391,745,329,242}, 
	},
	[3] = {
		{ 52,0,452,550}, 
		{ 501,167,247,325}, 
		{ 34,572,487,265}, 
		{ 0,553,768,471}, 
	},
	[4] = {
		{ 0,0,723,527}, 
		{ 20,71,190,235}, 
		{ 54,537,596,208}, 
		{ 53,769,658,214}, 
	},
	[5] = {
		{ 54,94,318,271}, 
		{ 400,93,321,272}, 
		{ 51,395,323,264}, 
		{ 401,392,317,267}, 
		{ 55,688,643,296}, 
	},
	[6] = {
		{ 33,83,279,288}, 
		{ 33,81,699,293}, 
		{ 39,379,691,294}, 
		{ 34,673,404,319}, 
		{ 432,676,306,318}, 
	},
	[7] = {
		{ 101,94,454,268}, 
		{ 396,94,325,269}, 
		{ 50,391,212,274}, 
		{ 184,374,318,305}, 
		{ 516,391,204,273}, 
		{ 50,693,214,292}, 
		{ 291,689,199,297}, 
		{ 514,690,204,297}, 
	},
	[8] = {
		{ 34,66,687,312}, 
		{ 50,384,305,602}, 
		{ 380,384,336,275}, 
		{ 380,682,337,304}, 
	},
  [9] = { 								-- no more frames from here to the end
	},
  [10] = { 
	},
	[11] = {
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
return data
