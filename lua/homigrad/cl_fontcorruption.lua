local enabled = CreateClientConVar("hg_fontcorruption", 1, true, false, "Corrupt chat and status message fonts when pain or shock gets close to passing out, on heavy analgesia, or on overdose", 0, 1)

hg.FontCorruption = hg.FontCorruption or {}

local MAX_CORRUPT_CHARS = 7
local PASS_OUT_SHOCK = 30 -- sv_pain.lua: shock above this (times analgesia) starts passing out
local PASS_OUT_PAIN = 80 -- sv_pain.lua: pain above this pushes shock towards 70
local ANALGESIA_START = 1 -- painkillers start distorting text above this
local ANALGESIA_FULL = 1.6 -- full strength at this dose

-- Family names as reported by the font files themselves (content/resources/fonts)
local families = {
	"Panic", -- Panic.ttf
	"Got heroin?", -- Got_Heroin.ttf
	"Antisocial", -- ANTI-SOC.TTF
	"ACID LABEL___", -- ACIDL___.otf
	"DRUNK FONTS", -- DRUNKFONTS-Regular.otf
}

local fontCache = {}
local drawCache = {}
local drawCacheCount = 0

local function EnsureFonts(size)
	local px = math.max(1, math.Round(size or 16))
	local key = tostring(px)

	if fontCache[key] then
		return fontCache[key]
	end

	local fonts = {}

	for i = 1, #families do
		local name = "hg_corrupt_" .. key .. "_" .. i

		surface.CreateFont(name, {
			font = families[i],
			size = px,
			weight = 400,
			antialias = true,
			extended = true,
		})

		fonts[i] = name
	end

	fontCache[key] = fonts

	return fonts
end

function hg.FontCorruption.IsOverdose(org)
	if not org then return false end

	if (org.noradrenaline or 0) > 0.01 then return true end

	local analgesia = math.max(org.analgesia or 0, org.analgesiaAdd or 0)

	return analgesia >= 3.5
end

function hg.FontCorruption.GetSeverity(org)
	if not org then return 0 end

	-- Only extreme pain and shock corrupt text, and only when they are close
	-- to knocking the player out. Thresholds mirror sv_pain.lua:
	--   shock > 30 * analgesiaMul makes consciousness drop (passing out)
	--   pain  > 80 pushes shock towards 70
	local analgesiaMul = (org.analgesia or 0) * 4 + 1
	local shockLimit = PASS_OUT_SHOCK * analgesiaMul
	local shockStart = shockLimit * 0.75 -- ~25% away from passing out
	local shock = 0

	if shockLimit > shockStart then
		shock = math.Clamp(((org.shock or 0) - shockStart) / (shockLimit - shockStart), 0, 1)
	end

	local painStart = PASS_OUT_PAIN * 0.75 -- ~25% away from passing out
	local pain = math.Clamp(((org.pain or 0) - painStart) / (PASS_OUT_PAIN - painStart), 0, 1)

	-- Heavy painkiller/analgesia doses also distort text: starts right above 1,
	-- full strength at 1.6
	local analgesia = math.max(org.analgesia or 0, org.analgesiaAdd or 0)
	local analgesiaSeverity = math.Clamp((analgesia - ANALGESIA_START) / (ANALGESIA_FULL - ANALGESIA_START), 0, 1)

	return math.max(pain, shock, analgesiaSeverity)
end

function hg.FontCorruption.ShouldCorrupt(org)
	if not enabled:GetBool() then return false end
	if hg.FontCorruption.IsOverdose(org) then return true end

	return hg.FontCorruption.GetSeverity(org) > 0.08
end

local function Tokenize(text)
	local tokens = {}
	local pos = 1
	local len = #text

	while pos <= len do
		local first, last = text:find("&[%w#]+;", pos)

		if first == pos then
			tokens[#tokens + 1] = { text = text:sub(first, last), entity = true }
			pos = last + 1
		else
			local ch = utf8.char(utf8.codepoint(text, pos))
			tokens[#tokens + 1] = { text = ch }
			pos = pos + #ch
		end
	end

	return tokens
end

local function SplitMarkup(str)
	local parts = {}
	local pos = 1
	local len = #str

	while pos <= len do
		local first, last = str:find("<[^>]*>", pos)

		if not first then
			parts[#parts + 1] = { text = str:sub(pos) }
			break
		end

		if first > pos then
			parts[#parts + 1] = { text = str:sub(pos, first - 1) }
		end

		parts[#parts + 1] = { tag = str:sub(first, last) }
		pos = last + 1
	end

	return parts
end

local function IsEligible(token)
	return not token.entity and token.text:find("%S") != nil
end

local function GetCorruptCount(org, eligible)
	if #eligible == 0 then
		return nil
	end

	if hg.FontCorruption.IsOverdose(org) then
		return #eligible
	end

	local severity = hg.FontCorruption.GetSeverity(org)

	if severity <= 0.08 then
		return nil
	end

	-- severity decides the ceiling (1..7 letters), then the actual amount is
	-- randomised between 1 and that ceiling
	local maxCount = math.Clamp(math.ceil(severity * MAX_CORRUPT_CHARS), 1, MAX_CORRUPT_CHARS)
	maxCount = math.min(maxCount, #eligible)

	return math.random(1, maxCount)
end

local function ChooseTokens(tokens, org)
	local chosen = {}
	local eligible = {}

	for i = 1, #tokens do
		if IsEligible(tokens[i]) then
			eligible[#eligible + 1] = i
		end
	end

	local count = GetCorruptCount(org, eligible)

	if not count then
		return chosen
	end

	local n = math.min(count, #eligible)

	for _ = 1, n do
		local pick = math.random(#eligible)
		chosen[eligible[pick]] = true
		table.remove(eligible, pick)
	end

	return chosen
end

function hg.FontCorruption.CorruptMarkup(str, org, size)
	if not enabled:GetBool() or not str or str == "" then return str end
	if not hg.FontCorruption.ShouldCorrupt(org) then return str end

	local parts = SplitMarkup(str)
	local tokenized = {}
	local eligible = {}

	for pi = 1, #parts do
		local part = parts[pi]

		if part.text then
			local tokens = Tokenize(part.text)
			tokenized[pi] = tokens

			for ti = 1, #tokens do
				if IsEligible(tokens[ti]) then
					eligible[#eligible + 1] = { pi = pi, ti = ti }
				end
			end
		end
	end

	if #eligible == 0 then return str end

	local chosen = {}
	local count = GetCorruptCount(org, eligible)

	if count then
		local n = math.min(count, #eligible)

		for _ = 1, n do
			local pick = math.random(#eligible)
			local entry = eligible[pick]
			chosen[entry.pi] = chosen[entry.pi] or {}
			chosen[entry.pi][entry.ti] = true
			table.remove(eligible, pick)
		end
	end

	local fonts = EnsureFonts(size)
	-- one font for the whole message, not a different one for every letter
	local corruptFont = fonts[math.random(#fonts)]
	local out = {}

	for pi = 1, #parts do
		local part = parts[pi]

		if part.tag then
			out[#out + 1] = part.tag
		else
			local tokens = tokenized[pi]
			local picked = chosen[pi]

			for ti = 1, #tokens do
				local token = tokens[ti]

				if picked and picked[ti] then
					out[#out + 1] = "<font=" .. corruptFont .. ">" .. token.text .. "</font>"
				else
					out[#out + 1] = token.text
				end
			end
		end
	end

	return table.concat(out)
end

local function BuildDrawData(text, baseFont, org, size)
	local tokens = Tokenize(text)
	local chosen = ChooseTokens(tokens, org)
	local fonts = EnsureFonts(size)
	-- one font for the whole message, not a different one for every letter
	local corruptFont = fonts[math.random(#fonts)]
	local items = {}
	local totalWidth = 0
	local lineHeight = 0

	for i = 1, #tokens do
		local token = tokens[i]
		local font = chosen[i] and corruptFont or baseFont

		surface.SetFont(font)

		local w, h = surface.GetTextSize(token.text)

		items[i] = { text = token.text, font = font, w = w, h = h }
		totalWidth = totalWidth + w

		if h > lineHeight then lineHeight = h end
	end

	return { items = items, totalWidth = totalWidth, lineHeight = lineHeight }
end

function hg.FontCorruption.DrawText(text, baseFont, x, y, color, alignX, alignY, org, size, outlineColor, outlineWidth)
	if not enabled:GetBool() or not text or text == "" or not hg.FontCorruption.ShouldCorrupt(org) then
		return draw.SimpleTextOutlined(text, baseFont, x, y, color, alignX, alignY, outlineWidth or 1.5, outlineColor or color_black)
	end

	local key = text .. "\1" .. tostring(baseFont) .. "\1" .. tostring(size)
	local data = drawCache[key]

	if not data then
		if drawCacheCount > 256 then
			drawCache = {}
			drawCacheCount = 0
		end

		data = BuildDrawData(text, baseFont, org, size)
		drawCache[key] = data
		drawCacheCount = drawCacheCount + 1
	end

	local startX = x
	local startY = y

	if alignX == TEXT_ALIGN_CENTER then
		startX = x - data.totalWidth * 0.5
	elseif alignX == TEXT_ALIGN_RIGHT then
		startX = x - data.totalWidth
	end

	if alignY == TEXT_ALIGN_CENTER then
		startY = y - data.lineHeight * 0.5
	elseif alignY == TEXT_ALIGN_BOTTOM then
		startY = y - data.lineHeight
	end

	outlineWidth = outlineWidth or 1.5
	outlineColor = outlineColor or color_black

	local alpha = color.a or 255
	local cursorX = startX

	for i = 1, #data.items do
		local item = data.items[i]
		local itemY = startY + (data.lineHeight - item.h)

		surface.SetFont(item.font)

		surface.SetTextPos(cursorX + outlineWidth, itemY + outlineWidth)
		surface.SetTextColor(outlineColor.r, outlineColor.g, outlineColor.b, alpha)
		surface.DrawText(item.text)

		surface.SetTextPos(cursorX, itemY)
		surface.SetTextColor(color.r, color.g, color.b, alpha)
		surface.DrawText(item.text)

		cursorX = cursorX + item.w
	end
end

EnsureFonts(ScreenScale(9))
EnsureFonts(ScreenScale(7))

hook.Add("OnScreenSizeChanged", "hg_fontcorruption", function()
	local chatSize = GetConVar("zchat_fontsize")

	EnsureFonts(ScreenScale(9))
	EnsureFonts(ScreenScale(chatSize and chatSize:GetFloat() or 7))
end)
