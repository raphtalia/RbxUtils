local CFrameUtils = {}

function CFrameUtils.fromOriginDir(origin: Vector3, dir: Vector3, up: Vector3?): CFrame
    if up then
        return CFrame.lookAt(origin, origin + dir, up)
    else
        return CFrame.lookAt(origin, origin + dir)
    end
end

return CFrameUtils