-- Promotion Library for Corona SDK
-- Written by Reflare
-- http://reflare.com
-- Licensed AS IS meaning -> use it for whatever you want, don't blame me if it crashes

module(..., package.seeall)

local savefile =	"appNews.txt"
local numfile =		"appRate.txt"
local alertText = "We care what you think. Do you like ''Be Confident''? Let us know!"
local btnRate = 	"Rate it now"
local btnNotNow = "Remind me later"
local btnNever = 	"No thanks"

-- Do not customize below this line, unless you know what you are doing!
function autoWrappedText(text, font, size, color, width)
		-- Multi Line Text Wrapping Code
		-- Written by Cromax
		-- http://developer.anscamobile.com/code/multiline-text-width-pixel
	 	
        if not text or text == '' then return false end
        font = font or native.systemFont
        size = tonumber(size) or 12
        color = color or {255, 255, 255}
        width = width or (display.contentWidth -50)

        local result = display.newGroup()
        local currentLine = ''
        local currentLineLength = 0
        local lineCount = 0
        local left = 0
        local lineHeight = 1.5
        for line in string.gmatch(text, "[^\n]+") do
                for word, spacer in string.gmatch(line, "([^%s%-]+)([%s%-]*)") do
                        local tempLine = currentLine..word..spacer
                        local tempDisplayLine = display.newText(tempLine, 0, 0, font, size)
                        if tempDisplayLine.width <= width then
                                currentLine = tempLine
                                currentLineLength = tempDisplayLine.width
                        else
                                local newDisplayLine = display.newText(currentLine, 0, (size * lineHeight) * (lineCount - 1), font, size)
                                newDisplayLine:setTextColor(color[1], color[2], color[3])
                                result:insert(newDisplayLine)
                                lineCount = lineCount + 1
                                if string.len(word) <= width then
                                        currentLine = word..spacer
                                        currentLineLength = string.len(word)
                                else
                                        local newDisplayLine = display.newText(word, 0, (size * lineHeight) * (lineCount - 1), font, size)
                                        newDisplayLine:setTextColor(color[1], color[2], color[3])
                                        result:insert(newDisplayLine)
                                        lineCount = lineCount + 1
                                        currentLine = ''
                                        currentLineLength = 0
                                end 
                        end

                        tempDisplayLine:removeSelf();
                        tempDisplayLine=nil;
                end
                local newDisplayLine = display.newText(currentLine, 0, (size * lineHeight) * (lineCount - 1), font, size)
                newDisplayLine:setTextColor(color[1], color[2], color[3])
                result:insert(newDisplayLine)
                lineCount = lineCount + 1
                currentLine = ''
                currentLineLength = 0
        end
        result:setReferencePoint(display.CenterReferencePoint)
        return result
end

function strsplit(delimiter, text)
  local list = {}
  local pos = 1
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    if first then -- found?
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
end


local function evaluateURL(event)
	if ( event.isError ) then
--	    print( "Offline...")
	else
			local path = system.pathForFile(savefile, system.DocumentsDirectory)
			local fh,reason = io.open(path,"r")
			local oldText = ""
			if fh then
				oldText = fh:read("*a")
				io.close(fh)
			end
			if event.response ~= oldText then
				fh = io.open(path,"w")
				fh:write(event.response)
				
				local content = strsplit("||",event.response)
				
				-- Display News Update
--				print("show news")
				local page = reader.book.current
				local newsText = autoWrappedText(content[2], native.systemFont, 22, {255,255,255}, (page.width -60))
				if not newsText then return end

				local newsGroup = display.newGroup()
				local newsBG = display.newImageRect("images/promote/news.jpg",768,170)
				local newsClose = display.newImageRect("images/promote/close.png",30,30)
				newsBG.x = page.width / 2
				newsBG.y = page.height - 170 / 2
				newsClose.x = page.width - 21
				newsClose.y = page.height - 150
--				newsClose.xScale = .8
--				newsClose.yScale = .8
				newsText.x = page.width / 2
				newsText.y = page.height - 170 / 2
				newsGroup:insert(newsBG)
				newsGroup:insert(newsClose)
				newsGroup:insert(newsText)
				page.balGroup:insert(newsGroup)
				newsGroup:setReferencePoint(display.BottomCenterReferencePoint)
				newsGroup.y =  page.height - 170*2
				newsGroup.x = 0
				newsGroup.alpha = 0
				page.newsGroup = newsGroup
				local function closeNews(event)
					transition.to(newsGroup,{duration=1500,y=newsGroup.y+170, alpha=0})
					return true
				end

				transition.to(newsGroup,{duration=1500, y=newsGroup.y-170, alpha=1})
				newsClose:addEventListener("touch",closeNews)

				local function openNews(event)
					if string.len(content[1]) > 0 then
						system.openURL(content[1])
					end
					return true
				end

				newsText:addEventListener("touch",openNews)
			end
	end
end

function displayNews(url)
	network.request( url, "GET", evaluateURL )
end

-- is there a network connection?
function testNetConn()
	local netConn = require('socket').connect( "electriceggplant.com", 80)		-- please replace this domain with your own domain
	if netConn == nil then
--		print( "testNetConn: Offline...")
		return false
	end
	netConn:close()
--	print( "testNetConn: Online...")
	return true
end


-- should we trigger the rating alert? Call this from the Info page
--		> 0 yes - was ready to rate but not online before
--		= 0 no - hasn't gone through to the end
--		= -1 no - either rated, or said No thanks
function checkRatingStatus()
	local path = system.pathForFile(numfile, system.DocumentsDirectory)
	local fh,reason = io.open(path,"r")
	local launch = nil
	
	if fh then
		launch = tonumber(fh:read("*a"))
	else
		launch = 0
	end
--	print("Launch",launch)
	-- we could rate, but only if online
	if launch > 0 and not testNetConn() then
		launch = -1
	end
	return launch
end


function offerRating(newReading , url)
	local path = system.pathForFile(numfile, system.DocumentsDirectory)
	local fh,reason = io.open(path,"r")
	local launch = nil
	
	if fh then
		launch = tonumber(fh:read("*a"))
		io.close(fh)
	else
		launch = 0
	end
--	print("Launch",launch)
	if launch == -1 then	-- either already rated, or said No Thanks
		return
	end
	
	launch = launch + 1		-- incrementing, but for now, we don't care
	
	if newReading and testNetConn() then		-- only if we're connected
		_G.promoteFlag = false			-- don't do it again until a restart

		local function onComplete( event )
			if "clicked" == event.action then
				local i = event.index
				if 1 == i then					-- ok, rating it!
					system.openURL( url )
					launch = -1						-- don't ask again
				elseif 2 == i then			-- nothing to do if it's Remind me Later
		    	
				else 										-- don't ask again
					launch = -1
				end
				fh = io.open(path,"w")
				fh:write(launch)
				io.close(fh)
			end
		end
		
		local alert = native.showAlert("Rate Our App",alertText, {btnRate, btnNotNow, btnNever}, onComplete)
		
	else
		fh = io.open(path,"w")
		fh:write(launch)
		io.close(fh)
	end
	
end