-- Command to output the player's current position
function outputPosition()
    local x, y, z = getElementPosition(isNoClipEnabled() and getNoClipObject() or localPlayer)
    outputChatBox("Current position: " .. x .. ", " .. y .. ", " .. z .. "")
end
addCommandHandler("pos", outputPosition)