local PartUtils = {}

function PartUtils.anchor(model: Model): nil
    for _,part in ipairs(PartUtils.getDescendantsOfClass(model, "BasePart")) do
        part.Anchored = true
    end
end

function PartUtils.unanchor(model: Model): nil
    for _,part in ipairs(PartUtils.getDescendantsOfClass(model, "BasePart")) do
        part.Anchored = false
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

function PartUtils.makeMotor6D(part0, part1)
    local motor6D = Instance.new("Motor6D")
    motor6D.Part0 = part0
    motor6D.Part1 = part1
    motor6D.Parent = part0
    return motor6D
end

function PartUtils.getChildrenOfClass(container: Instance, class: string)
    local instances = {}

    for _,instance in ipairs(container:GetChildren()) do
        if instance:IsA(class) then
            table.insert(instances, instance)
        end
    end

    return instances
end

function PartUtils.getDescendantsOfClass(container: Instance, class: string)
    local instances = {}

    for _,instance in ipairs(container:GetDescendants()) do
        if instance:IsA(class) then
            table.insert(instances, instance)
        end
    end

    return instances
end

return PartUtils