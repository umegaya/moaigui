--[[
* The MIT License
* Copyright (C) 2011 Derick Dong (derickdong@hotmail.com).  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	FILE: textbox.lua
	DESCRIPTION: A box displaying multiple lines of text
	AUTHOR: Derick Dong
	VERSION: 0.1
	MOAI VERSION: 0.7
	CREATED: 9-9-11

	UPDATED: 4-27-12
	VERSION: 0.2
	MOAI VERSION: v1.0 r3
]]

local _M = {}

local class = require "gui/support/class"
local util = require "gui/support/utilities"

local awindow = require "gui/awindow"
local label = require "gui/label"
local awidgetevent = require "gui/awidgetevent"

_M.TextBox = class(awindow.AWindow)

local SCROLL_BAR_WIDTH = 5

function _M.TextBox:_createTextboxAddTextEvent(newText)
	local t = awidgetevent.AWidgetEvent(self.EVENT_TEXT_BOX_ADD_TEXT, self)
	t.fullText = self._fullText
	t.newText = newText

	return t
end

function _M.TextBox:_createTextboxClearTextEvent()
	local t = awidgetevent.AWidgetEvent(self.EVENT_TEXT_BOX_CLEAR_TEXT, self)

	return t
end

function _M.TextBox:_calcScrollBarPageSize()
	return math.floor((self:height() / self._lineHeight) + 0.5)
end

function _M.TextBox:_onSetPos()
	if (nil ~= self._scrollBar) then
		self._scrollBar:setPos(self:width() - SCROLL_BAR_WIDTH, 0)
	end
end

function _M.TextBox:_onSetDim()
	if (nil ~= self._scrollBar) then
		self._scrollBar:setDim(SCROLL_BAR_WIDTH, self:height())
		self._scrollBar:setPos(self:width() - SCROLL_BAR_WIDTH, 0)
		self._scrollBar:setPageSize(self:_calcScrollBarPageSize())
	end
end

function _M.TextBox:_displayLines()
	if (0 == #self._lines) then return end

	for i, v in ipairs(self._lines) do
		-->print('hide line', i, self._lines[i]:getText())
		v:hide()
	end

	local minLine, maxLine

	if self._scrollBar then
		minLine = math.min(#self._lines, self._scrollBar:getTopItem())
		maxLine = math.min(#self._lines, self._scrollBar:getTopItem() + self._scrollBar:getPageSize() - 1)
	else
		minLine = math.min(#self._lines, self._topPos)
		maxLine = math.min(#self._lines, self._topPos + self:_calcScrollBarPageSize() - 1)
	end

	for i = minLine, maxLine do
		-->print('show line', i, self._lines[i]:getText())
		self._lines[i]:show()
		self._lines[i]:setPos(0.5, (i - minLine) * self._lineHeight)
	end
end

function _M.TextBox:_handleScrollPosChange(event)
	self:_displayLines()
end

--> for swipe detection
function _M.TextBox:__handleMouseUp(event)
	self._hold = false
end
function _M.TextBox:__handleMouseDown(event)
	self._hold = true
end
function _M.TextBox:__handleMouseMove(event)
	-->print('handlemousemove', self._hold, event.x, event.y, event.prevX, event.prevY)
	--[[
	event.x
	event.y
	event.prevX
	event.prevY
	]]--
	if self._hold then
		local diffy = (event.prevY - event.y)
		local tmp, height_for_oneline = self._gui:_calcAbsValue(0, self._lineHeight)
		self._diffy = (self._diffy + diffy)
		-->print('total movey = ', self._diffy)
		if math.abs(self._diffy) >= height_for_oneline then
			-->print('movey = ', diffy, height_for_oneline)
			local difflines = diffy / height_for_oneline
			difflines = (difflines < 0) and math.floor(difflines) or math.ceil(difflines)
			-->print('difflines = ', difflines)
			local newPos = self._topPos + difflines
			newPos = math.min(math.max(1, newPos), math.max(1, (#self._lines - self:_calcScrollBarPageSize()) + 1))
			if self._topPos ~= newPos then
				self._topPos = newPos
				self:_displayLines()
			end
		end
	end
end


function _M.TextBox:setLineHeight(height)
	self._lineHeight = height
	if self._scrollBar then
		self._scrollBar:setPageSize(self:_calcScrollBarPageSize())
	end
end

function _M.TextBox:getLineHeight()
	return self._lineHeight
end

function _M.TextBox:setBackgroundImage(image, r, g, b, a, idx, blendSrc, blendDst)
	self:_setImage(self._rootProp, self._BACKGROUND_INDEX, self.BACKGROUND_IMAGES, image, r, g, b, a, idx, blendSrc, blendDst)
	self:_setCurrImages(self._BACKGROUND_INDEX, self.BACKGROUND_IMAGES)

end

function _M.TextBox:getBackgroundImage()
	return self._imageList:getImage(self._BACKGROUND_INDEX, self.BACKGROUND_IMAGES)
end

-- Hack, since MOAITextBox:getStringBounds does not return a proper value (at least, not before
-- its been rendered once)
function _M.TextBox:_calcStringWidth(s)
	return #s * 7.5
end

function _M.TextBox:_calcUTF8StringWidth(s)
	-->print('utf8 strwidth:', s, #s, (#s * 7.5))
	local length = 0
	local ok, r = pcall(util.eachUTF8Char, s, function (text, pos, len)
		if len > 1 then
			length = (length + 15) --> multibyte char
		else
			length = (length + 7.5) --> single byte char
		end
	end)
	if not ok then print(r) end
	return length
end

function _M.TextBox:_addNewLine()
	local line = self._gui:createLabel()
	line:setDim(self:width(), self._lineHeight)
	self._lines[#self._lines + 1] = line
	self:_addWidgetChild(line)
	if self._scrollBar then
		self._scrollBar:setNumItems(self._scrollBar:getNumItems() + 1)
	end
	
	return line
end

function _M.TextBox:_addText(str)
	local maxLineWidth = self._scrollBar and (self:screenWidth() - self._scrollBar:screenWidth()) or self:screenWidth()
	for text in str:gmatch('([^\n]+)') do
		while (#text > 0) do
			local line = self._lines[#self._lines]
			if (nil == line) then
				line = self:_addNewLine()
			end
	
			local curr = line:getText()
			local wordIdx = util.nextCharLengthUtf8(text)
			local s = wordIdx and text:sub(1, wordIdx) or text
			local newWidth = self:_calcUTF8StringWidth(curr .. s)
			-->print('newwidth,maxwidth', curr .. s, newWidth, maxLineWidth)
			if (newWidth > maxLineWidth) then
				if #(line:getText()) <= 0 then
					--> TODO: un-tokenizable, too long string given. need 'smarter' tokenize, which consider other then white space.
					--> now just give string as it is. MOAI sdk will trim out of width characters autometically.
					--> like 
					-->		local a, b = self:devide(s, self:_calcStringWidth(curr))
					-->		line:setText(a)
					-->		line = self:__addNewline()
					-->		line:setText(b)
					line:setText(s)
				else
					--> insert line feed (because no more room for this line)
					line = self:_addNewLine()
					--> last token is too long to fit in given textbox
					local newWidth = self:_calcStringWidth(s)
					print('newwidth2,maxwidth:', newWidth, maxLineWidth)
					if (newWidth > maxLineWidth) then
						--> last token itself too long need to devide in smart way like above
						line:setText(s)
					else
						--> last token itself enough. it processed fine 
						line:setText(s)
					end
				end
			else
				line:setText(curr .. s)
			end
	
			text = wordIdx and text:sub(wordIdx + 1) or ""
		end
	end
end

function _M.TextBox:newLine(num)
	if (nil == num) then num = 1 end

	for i = 1, num do
		self:_addNewLine()
	end
end

function _M.TextBox:_calcParagraphs(text)
	local paragraphs = {}
	local idx = text:find("\n")
	while (nil ~= idx) do
		paragraphs[#paragraphs + 1] = text:sub(1, idx)
		text = text:sub(idx + 1)
		idx = text:find("\n")
	end

	paragraphs[#paragraphs + 1] = text

	return paragraphs
end

function _M.TextBox:addText(text)
	self._fullText = self._fullText .. text

	local paragraphs = self:_calcParagraphs(text)

	for i = 1, #paragraphs - 1 do
		self:_addText(paragraphs[i])
		self:_addNewLine()
	end

	self:_addText(paragraphs[#paragraphs])
	
	if self._topPos and self._options and self._options.showBottom then
		if #self._lines >= (self._topPos + self:_calcScrollBarPageSize()) then
			self._topPos = (#self._lines - self:_calcScrollBarPageSize() + 1)
		end
	end

	self:_displayLines()

	local e = self:_createTextboxAddTextEvent(text)

	return self:_handleEvent(self.EVENT_TEXT_BOX_ADD_TEXT, e)
end

function _M.TextBox:addToFront(text)

end

function _M.TextBox:getText(text)
	return self._fullText
end

function _M.TextBox:removeLine(idx)
	if (idx < 1 or idx > #self._lines) then return end

	local text = self._lines[idx]:getText()
	local f = self._fullText:find(text, 1, true) --> turn off regex search
	if (nil == f) then return end

	self._fullText = self._fullText:sub(1, f - 1) .. self._fullText:sub(f + #text)

	self:_removeWidgetChild(self._lines[idx])

	if self._scrollBar then
		self._scrollBar:setTopItem(1)
		self._scrollBar:setNumItems(self._scrollBar:getNumItems() - 1)
	end

	table.remove(self._lines, idx)
	
	if self._topPos and self._options and self._options.showBottom then
		if #self._lines < (self._topPos + self:_calcScrollBarPageSize()) then
			self._topPos = (#self._lines - self:_calcScrollBarPageSize())
			if self._topPos < 1 then
				self._topPos = 1
			end
		end
	end

	self:_displayLines()
end

function _M.TextBox:clearText()
	while (#self._lines > 0) do
		self:removeLine(1)
	end

	self._fullText = ""

	local e = self:_createTextboxClearTextEvent()

	return self:_handleEvent(self.EVENT_TEXT_BOX_CLEAR_TEXT, e)
end

-- function _M.TextBox:setMaxLines(num)

-- end

-- function _M.TextBox:getMaxLines()
	-- return self._maxLines
-- end

function _M.TextBox:_TextBoxEvents()
	self.EVENT_TEXT_BOX_ADD_TEXT = "EventTextBoxAddText"
	self.EVENT_TEXT_BOX_CLEAR_TEXT = "EventTextBoxClearText"
end

function _M.TextBox:init(gui, options)
	awindow.AWindow.init(self, gui)

	self._type = "TextBox"

	self:_TextBoxEvents()

	self._BACKGROUND_INDEX = self._WIDGET_SPECIFIC_OBJECTS_INDEX
	self.BACKGROUND_IMAGES = self._WIDGET_SPECIFIC_IMAGES

	self._fullText = ""
	self._lineHeight = 0
	self._lines = {}
	-- self._maxLines = 20

	self._options = options
	
	if (not options) or (not options.useSwipe) then
		self._scrollBar = gui:createVertScrollBar()
		self:_addWidgetChild(self._scrollBar)
		self._scrollBar:registerEventHandler(self._scrollBar.EVENT_SCROLL_BAR_POS_CHANGED, self, "_handleScrollPosChange")
	else
		self:registerEventHandler(self.EVENT_MOUSE_UP, self, "__handleMouseUp")
		self:registerEventHandler(self.EVENT_MOUSE_DOWN, self, "__handleMouseDown")
		self:registerEventHandler(self.EVENT_MOUSE_MOVE, self, "__handleMouseMove")
		self._topPos = 1
		self._diffy = 0
	end
end

return _M
