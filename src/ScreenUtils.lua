local StarterGui = game:GetService("StarterGui")

local RaycastUtils = require(script.Parent.RaycastUtils)

local ScreenUtils = {}

function ScreenUtils.getTargetAtPosition(x: number, y: number, depth: number?, raycastParams: RaycastParams?): RaycastResult?
    local ray = workspace.CurrentCamera:ViewportPointToRay(x, y)

    local result = RaycastUtils.cast(ray.Origin, ray.Direction * (depth or 500), raycastParams)
    if result then
        return result
    end
end

function ScreenUtils.getGuiObjectsAtPosition(x: number, y: number, filter, recursive: boolean?)
    local objects = StarterGui:GetGuiObjectsAtPosition(x, y)

    if filter then
        local filteredObjects = {}

        for _,v1 in pairs(objects) do
            -- Quick search if object is in filter
            if table.find(filter, v1) then
                table.insert(filteredObjects, v1)
                continue
            end

            -- Deep search if object is a descendant
            if recursive then
                for _,v2 in pairs(filter) do
                    if v1 == v2 or v1:IsDescendantOf(v2) then
                        table.insert(filteredObjects, v1)
                    end
                end
            end
        end

        return filteredObjects
    else
        return objects
    end
end

return ScreenUtils