local ColorUtils = {}

-- ExtraContent/LuaPackages/AppTempCommon
function ColorUtils.rgbFromHex(hexColor)
	assert(hexColor >= 0 and hexColor <= 0xffffff, "RgbFromHex: Out of range")

	local b = hexColor % 256
	hexColor = (hexColor - b) / 256
	local g = hexColor % 256
	hexColor = (hexColor - g) / 256
	local r = hexColor

	return r, g, b
end

function ColorUtils.color3FromHex(hexColor)
	return Color3.fromRGB(ColorUtils.rgbFromHex(hexColor))
end

function ColorUtils.color3ToHex(color)
    return math.floor(color.R * 255) *256^2 + math.floor(color.G * 255) * 256 + math.floor(color.B * 255)
end

function ColorUtils.add(color0, color1)
    if type(color1) == "number" then
        color1 = Color3.new(color1, color1, color1)
    end

    return Color3.new(
        math.min(color0.R + color1.R, 1),
        math.min(color0.G + color1.G, 1),
        math.min(color0.B + color1.B, 1)
    )
end

function ColorUtils.multiply(color0, color1)
    if type(color1) == "number" then
        color1 = Color3.new(color1, color1, color1)
    end

    return Color3.new(
        math.min(color0.R * color1.R, 1),
        math.min(color0.G * color1.G, 1),
        math.min(color0.B * color1.B, 1)
    )
end

function ColorUtils.pow(color0, color1)
    if type(color1) == "number" then
        color1 = Color3.new(color1, color1, color1)
    end

    return Color3.new(
        math.min(color0.R ^ color1.R, 1),
        math.min(color0.G ^ color1.G, 1),
        math.min(color0.B ^ color1.B, 1)
    )
end

return ColorUtils