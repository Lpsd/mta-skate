function createSkateboard_cmd(player)
    local x, y, z = getElementPosition(player)
    Skateboard:new(x + 1, y + 1, z)
end
addCommandHandler("skate", createSkateboard_cmd)