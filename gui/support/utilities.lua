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

	FILE: utilities.lua
	DESCRIPTION: Just some random stuff
	AUTHOR: Derick Dong
	VERSION: 0.1
	MOAI VERSION: 0.7
	CREATED: 9-9-11

	UPDATED: 4-27-12
	VERSION: 0.2
	MOAI VERSION: v1.0 r3
]]

local _M = {}

function _M.loadFileData(fileName)
	if (false == MOAIFileSystem.checkFileExists(fileName)) then
		return nil
	end

	-- return MOAIFileSystem.loadAndRunLuaFile(fileName)
	return dofile(fileName)
end

function _M.nextCharLengthUtf8(str, ofs)
	local code = str:byte(ofs or 1)
	if code <= 127 then
		return 1
	elseif code >= 0xC2 and code < 0xE0 then
		return 2
	elseif code < 0xF0 then
		return 3
	elseif code < 0xF8 then
		return 4
	elseif code < 0xFC then
		return 5
	else
		assert(false, 'invalid utf8 string lead byte:' .. str:char(1))
	end
end

function _M.eachUTF8Char(text, iter)
	local pos, chlen = 1, false
	local len = #text
	while pos < len do
		chlen = _M.nextCharLengthUtf8(text, pos)
		if iter(text, pos, chlen) then
			return
		end
		pos = (pos + chlen)
	end
end

return _M
