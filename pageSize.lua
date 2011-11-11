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
-- pageSize.lua - lists which pages are available at 2x size for iPad and iPhone 4.
-- 
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Note: if the entry for a page is "", that means this is a 1024x768 image that
-- is not zoomable. If value is "@2x", then we have both a 1024x768 image and a 2x
-- image at 2048x1536. The 2x image is only loaded for iPad and iPhone 4.
-- 

local pageSize = {
  [0] = "", 
  [1] = "", 
	[2] = "@2x",
	[3] = "@2x",
	[4] = "@2x",
	[5] = "@2x",
	[6] = "@2x",
	[7] = "@2x",
	[8] = "@2x",
  [9] = "", 
	[10] = "",
	[11] = "",
	[12] = "",
	[13] = "",
	[14] = "",
  [15] = "", 
	[16] = "",
	[17] = "",
}
return pageSize
