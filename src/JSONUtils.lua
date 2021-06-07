local TYPE_MARKER = "_T"

local HttpService = game:GetService("HttpService")

local Colors = require(script.Parent.ColorUtils)

local JSON = {}

function JSON.serialize(tab)
    for i,v in pairs(tab) do
        local type = typeof(v)

        if type == "table" then
            tab[i] = {
                TYPE_MARKER,
                0,
                JSON.serialize(v),
            }
        elseif type == "Vector2" then
            tab[i] = {
                TYPE_MARKER,
                1,
                v.X,
                v.Y,
            }
        elseif type == "Vector3" then
            tab[i] = {
                TYPE_MARKER,
                2,
                v.X,
                v.Y,
                v.Z,
            }
        elseif type == "CFrame" then
            -- This could be optimized to ignore orientation if there is none
            tab[i] = {
                TYPE_MARKER,
                3,
                v:GetComponents(),
            }
        elseif type == "Color3" then
            tab[i] = {
                TYPE_MARKER,
                4,
                Colors.color3ToHex(v),
            }
        elseif type == "BrickColor" then
            tab[i] = {
                TYPE_MARKER,
                5,
                v.Number,
            }
        elseif type == "ColorSequence" then
            tab[i] = {
                TYPE_MARKER,
                6,
                JSON.serialize(v.Keypoints),
            }
        elseif type == "ColorSequenceKeypoint" then
            tab[i] = {
                TYPE_MARKER,
                7,
                v.Time,
                Colors.color3ToHex(v.Value),
            }
        elseif type == "NumberRange" then
            tab[i] = {
                TYPE_MARKER,
                8,
                v.Min,
                v.Max,
            }
        elseif type == "NumberSequence" then
            tab[i] = {
                TYPE_MARKER,
                9,
                JSON.serialize(v.Keypoints),
            }
        elseif type == "NumberSequenceKeypoint" then
            -- This could be optimized to ignore envlope if it is 0
            tab[i] = {
                TYPE_MARKER,
                10,
                v.Time,
                v.Value,
                v.Envelope,
            }
        elseif type == "UDim" then
            tab[i] = {
                TYPE_MARKER,
                11,
                v.Scale,
                v.Offset,
            }
        elseif type == "UDim2" then
            tab[i] = {
                TYPE_MARKER,
                12,
                v.X.Scale,
                v.X.Offset,
                v.Y.Scale,
                v.Y.Offset,
            }
        end
    end
    return HttpService:JSONEncode(tab)
end

function JSON.deserialize(tab)
    tab = HttpService:JSONDecode(tab)
    for i,v in pairs(tab) do
        if type(v) == "table" and v[1] == TYPE_MARKER then
            local type = v[2]
            v = {select(3, unpack(v))}
            v = #v == 1 and v[1] or v

            if type == 0 then -- table
                tab[i] = JSON.deserialize(v)
            elseif type == 1 then -- Vector2
                tab[i] = Vector2.new(v[1], v[2])
            elseif type == 2 then -- Vector3
                tab[i] = Vector3.new(v[1], v[2], v[3])
            elseif type == 3 then -- CFrame
                tab[i] = CFrame.new(v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9], v[10], v[11], v[12])
            elseif type == 4 then -- Color3
                tab[i] = Colors.color3FromHex(v)
            elseif type == 5 then -- BrickColor
                tab[i] = BrickColor.new(v)
            elseif type == 6 then -- ColorSequence
                tab[i] = ColorSequence.new(JSON.deserialize(v))
            elseif type == 7 then -- ColorSequenceKeypoint
                tab[i] = ColorSequenceKeypoint.new(v[1], Colors.color3FromHex(v[2]))
            elseif type == 8 then -- NumberRange
                tab[i] = NumberRange.new(v[1], v[2])
            elseif type == 9 then -- NumberSequence
                tab[i] = NumberSequence.new(JSON.deserialize(v))
            elseif type == 10 then -- NumberSequenceKeypoint
                tab[i] = NumberSequenceKeypoint.new(v[1], v[2], v[3])
            elseif type == 11 then -- UDim
                tab[i] = UDim.new(v[1], v[2])
            elseif type == 12 then -- UDim2
                tab[i] = UDim2.new(v[1], v[2], v[3], v[4])
            end
        end
    end
    return tab
end

function JSON.isJSON(str)
    local success = pcall(JSON.deserialize, str)
    return success
end

return JSON