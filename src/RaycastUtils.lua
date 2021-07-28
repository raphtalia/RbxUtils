type RaycastParamsTable = typeof({
    FilterDescendantsInstances = {},
    FilterType = Enum.RaycastFilterType.Blacklist,
    IgnoreWater = false,
    CollisionGroup = "Default",
})

local DEFAULT_PARAMS = RaycastParams.new()

local RaycastUtils = {}

local function filterCollideOnly(instance)
    return instance.CanCollide
end

function RaycastUtils.make(params: RaycastParamsTable): RaycastParams
    local raycastParams = RaycastParams.new()

    if params.IgnoreWater == nil then
        params.IgnoreWater = raycastParams.IgnoreWater
    end

    raycastParams.FilterDescendantsInstances = params.FilterDescendantsInstances or raycastParams.FilterDescendantsInstances
    raycastParams.FilterType = params.FilterType or raycastParams.FilterType
    raycastParams.IgnoreWater = params.IgnoreWater
    raycastParams.CollisionGroup = params.CollisionGroup or raycastParams.CollisionGroup

    return raycastParams
end

-- Clones a new RaycastParams with the same properties
function RaycastUtils.copy(raycastParams: RaycastParams): RaycastParams
    local copyRaycastParams = RaycastParams.new()
    copyRaycastParams.FilterDescendantsInstances = raycastParams.FilterDescendantsInstances
    copyRaycastParams.FilterType = raycastParams.FilterType
    copyRaycastParams.IgnoreWater = raycastParams.IgnoreWater
    copyRaycastParams.CollisionGroup = raycastParams.CollisionGroup

    return copyRaycastParams
end

-- Behaves like the old raycast function
function RaycastUtils.cast(origin: Vector3, dir: Vector3, params: RaycastParams?): RaycastResult
    return workspace:Raycast(origin, dir, params or DEFAULT_PARAMS)
end

-- Returns instance that meets filter requirement
function RaycastUtils.castWithFilter(origin: Vector3, dir: Vector3, filter: any, params: RaycastParams?): RaycastResult
    params = params or DEFAULT_PARAMS
    local originalFilter = params.FilterDescendantsInstances
    local tempFilter = params.FilterDescendantsInstances

    repeat
        local result = workspace:Raycast(origin, dir, params)
        if result then
            if filter(result.Instance) then
                params.FilterDescendantsInstances = originalFilter
                return result
            else
                table.insert(tempFilter, result.Instance)
                params.FilterDescendantsInstances = tempFilter
                origin = result.Position
                dir = dir.Unit * (dir.Magnitude - (origin - result.Position).Magnitude)
            end
        else
            params.FilterDescendantsInstances = originalFilter
            return nil
        end
    until not result
end

-- Cast ignores parts that are CanCollide Off
function RaycastUtils.castCollideOnly(origin: Vector3, dir: Vector3, params: RaycastParams?): RaycastResult
    return RaycastUtils.castWithFilter(
        origin,
        dir,
        filterCollideOnly,
        params
    )
end

return RaycastUtils