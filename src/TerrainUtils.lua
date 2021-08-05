local VOXEL_SIZE = 4

local Terrain = workspace:FindFirstChildWhichIsA("Terrain")

local TerrainUtils = {}

function TerrainUtils.cellPositionToWorld(pos)
    return pos * VOXEL_SIZE
end

function TerrainUtils.getMaterialAtPosition(pos, preferSolid)
    local minCorner
    local maxCorner

    if preferSolid then
        minCorner = Terrain:WorldToCellPreferSolid(pos)
    else
        minCorner = Terrain:WorldToCell(pos)
    end

    maxCorner = TerrainUtils.cellPositionToWorld(minCorner + Vector3.new(1, 1, 1))
    minCorner = TerrainUtils.cellPositionToWorld(minCorner)

    return Terrain:ReadVoxels(Region3.new(minCorner, maxCorner), VOXEL_SIZE)[1][1][1]
end

return TerrainUtils