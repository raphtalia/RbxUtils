local Vector3Utils = {}

function Vector3Utils.clamp(vector: Vector3, min: number, max: number): Vector3
    min = min or Vector3.new(-math.huge, -math.huge, -math.huge)
    max = max or Vector3.new(math.huge, math.huge, math.huge)

    if type(min) == "number" then
        min = Vector3.new(min, min, min)
    end

    if type(max) == "number" then
        max = Vector3.new(max, max, max)
    end

    if typeof(vector) == "Vector3" then
        return Vector3.new(math.clamp(vector.X, min.X, max.X), math.clamp(vector.Y, min.Y, max.Y), math.clamp(vector.Z, min.Z, max.Z))
    else
        return Vector2.new(math.clamp(vector.X, min.X, max.X), math.clamp(vector.Y, min.Y, max.Y))
    end
end

function Vector3Utils.llarToWorld(lat: number, lon: number, alt: number?, rad: number?): Vector3
    -- https://stackoverflow.com/questions/10473852/convert-latitude-and-longitude-to-point-in-3d-space
    alt = alt or 0
    rad = rad or 1

    local ls = math.atan(math.tan(lat))

    local x = rad * math.cos(ls) * math.cos(lon) + alt * math.cos(lat) * math.cos(lon)
    local y = rad * math.cos(ls) * math.sin(lon) + alt * math.cos(lat) * math.sin(lon)
    local z = rad * math.sin(ls) + alt * math.sin(lat)

    return Vector3.new(x, y, z)
end

function Vector3Utils.abs(v: Vector3): Vector3
    return Vector3.new(math.abs(v.X), math.abs(v.Y), math.abs(v.Z))
end

function Vector3Utils.angle(v1: Vector3, v2: Vector3): number
    v1 = v1 or Vector3.new()
    v2 = v2 or Vector3.new()

    return math.acos(v1:Dot(v2) / math.max(v1.Magnitude * v2.Magnitude, 0.00001))
end

function Vector3Utils.reflect(dir: Vector3, normal: Vector3, pos: Vector3?)
    normal = normal.Unit
    pos = pos or Vector3.new()

    return dir - 2 * (dir * normal) * normal + pos
end

return Vector3Utils