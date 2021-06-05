type Lerpable = Vector2 | Vector3 | CFrame | Color3

local MathUtils = {}

-- Golden Ratio
MathUtils.phi = (math.sqrt(5) + 1) / 2
-- Golden Angle in radians
MathUtils.ga = math.pi * (3 - math.sqrt(5))

-- @param x: number/vector3/vector2 to round
-- @param accuracy: number to round x to
function MathUtils.round(x: number, accuracy: number): number
    return math.round(x / accuracy) * accuracy
end

function MathUtils.roundCeil(x: number, accuracy: number): number
    return math.ceil(x / accuracy) * accuracy
end

function MathUtils.roundFloor(x: number, accuracy: number): number
    return math.floor(x / accuracy) * accuracy
end

-- Not reccomended to use this if hard-coded values are possible
function MathUtils.factorial(x: number): number
    local output = 1
    for i = 1, x do
        output *= i
    end
    return output
end

function MathUtils.lerp(a: Lerpable, b: Lerpable, c: number): Lerpable
    local typeA, typeB = typeof(a), typeof(b)
    assert(typeA == typeB, ("Type mismatch between %s and %s, same type expected"):format(typeA, typeB))

    if typeA == "Vector2" or typeA == "Vector3" or typeA == "CFrame" then
        return a:Lerp(b, c)
    elseif typeA == "Color3" then
        return Color3.new(
            MathUtils.lerp(a.r, b.r, c),
            MathUtils.lerp(a.g, b.g, c),
            MathUtils.lerp(a.b, b.b, c)
        )
    else
        return a + (b - a) * c
    end
end

function MathUtils.factors(x: number): {number}
    local factors = {}
    local sqrtx = math.sqrt(x)

    for i = 1, sqrtx do
        if x % i == 0 then
            table.insert(factors, i)
            if i ~= sqrtx then
                table.insert(factors, x / i)
            end
        end
    end

    table.sort(factors)

    return factors
end

function MathUtils.isPrime(x: number): boolean
    for i = 2, math.sqrt(x) do
        if x % i == 0 then
            return false
        end
    end
    return true
end

-- Returns the closest number to 'x' from a table of numbers
function MathUtils.snap(x: number, numbers: {number}, snapUp: boolean?)
    local bestMatch = numbers[1]
    local diff = math.abs(x - numbers[1])

    for i = 2, #numbers do
        local v = numbers[i]
        local testDiff = math.abs(x - v)

        if testDiff < diff then
            bestMatch = v
            diff = testDiff
        end
    end

    if snapUp and bestMatch < x then
        return numbers[table.find(numbers, bestMatch) + 1]
    end

    return bestMatch
end

return MathUtils