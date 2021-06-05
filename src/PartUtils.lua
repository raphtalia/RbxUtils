local PartUtils = {}

function PartUtils.anchor(model: Model): nil
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
end

function PartUtils.unanchor(model: Model): nil
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
        end
    end
end

function PartUtils.weld(main: BasePart, ...): nil
    local parts = {...}

    for _,part in ipairs(parts) do
        if part ~= main then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = main
            weld.Part1 = part
            weld.Parent = part
        end
    end
end

return PartUtils