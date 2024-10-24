local noclipEnabled = false
local noclipObject = nil
local moveSpeed = .66
local fastSpeedMultiplier = 3
local slowSpeedMultiplier = .33

local hasPositionUpdated = true
local lastPosition = { x = 0, y = 0, z = 0 }
local newPosition = nil

local processInputMs = 0
local processInputTimer = nil

local groundSnappingEnabled = true

local NOCLIP_CHAT_TAG = "#c68ff8[noclip] #ffffff"

-- wasd for movement, space to go up, c to go down
-- lshift to move faster, lctrl to move slower
-- n to toggle noclip mode
-- /speed [number] to change the base speed
-- /snap to toggle ground snapping

function isNoClipEnabled()
    return noclipEnabled
end

function getNoClipObject()
    return noclipObject
end

local function toggleGroundSnapping()
    groundSnappingEnabled = not groundSnappingEnabled
    outputChatBox(NOCLIP_CHAT_TAG .. "Ground snapping is now " .. (groundSnappingEnabled and "enabled" or "disabled") .. ".", 255, 255, 255, true)
end
addCommandHandler("snap", toggleGroundSnapping)

local function changeMoveSpeed(cmd, speed)
    speed = tonumber(speed)
    moveSpeed = speed and math.abs(speed) or moveSpeed
    outputChatBox(NOCLIP_CHAT_TAG .. "Move speed set to " .. moveSpeed .. ".", 255, 255, 255, true)
end
addCommandHandler("speed", changeMoveSpeed)

local function isShiftPressed()
    return getKeyState("lshift")
end

local function isCtrlPressed()
    return getKeyState("lctrl")
end

local function moveNoclipObject(forward, right, up)
    if not noclipObject then return end

    forward = forward or 0
    right = right or 0
    up = up or 0

    local posX, posY, posZ = lastPosition.x, lastPosition.y, lastPosition.z

    if (hasPositionUpdated) then
        posX, posY, posZ = getElementPosition(noclipObject)
        lastPosition.x, lastPosition.y, lastPosition.z = posX, posY, posZ
        hasPositionUpdated = false
    end

    local speed = isShiftPressed() and (moveSpeed * fastSpeedMultiplier) or moveSpeed

    if (isCtrlPressed()) then
        speed = moveSpeed * slowSpeedMultiplier
    end

    local camera = getCamera()
    local moveVector = camera.matrix.right * right + camera.matrix.forward * forward
    posX = posX + moveVector.x * speed
    posY = posY + moveVector.y * speed
    posZ = posZ + up * speed

    newPosition = { x = 0, y = 0, z = 0 }
    newPosition.x, newPosition.y, newPosition.z = posX, posY, posZ
end

local function processInput()
    if not noclipEnabled then return end
    if isMTAWindowActive() then return end

    local forward = 0
    local right = 0
    local up = 0

    if getKeyState("w") then
        forward = 1
    elseif getKeyState("s") then
        forward = -1
    end

    if getKeyState("a") then
        right = -1
    elseif getKeyState("d") then
        right = 1
    end

    if getKeyState("space") then
        up = 1
    elseif getKeyState("c") then
        up = -1
    end

    moveNoclipObject(forward, right, up)
end

local function toggleNoclip()
    noclipEnabled = not noclipEnabled

    if (noclipEnabled) then
        -- Create the invisible object
        local x, y, z = getElementPosition(getLocalPlayer())
        noclipObject = createPed(0, x, y, z)
        setElementAlpha(noclipObject, 0)
        setElementCollisionsEnabled(noclipObject, false)
        setPedVoice(noclipObject, "PED_TYPE_DISABLED", "nil")
        setElementFrozen(noclipObject, true)
        setElementFrozen(localPlayer, true)
        setCameraTarget(noclipObject)

        -- Start the input processing timer
        processInputTimer = setTimer(processInput, processInputMs, 0)
    else
        -- Destroy the object and reset camera
        if (noclipObject) then
            destroyElement(noclipObject)
            noclipObject = nil
        end
        setCameraTarget(getLocalPlayer())
        setElementFrozen(localPlayer, false)

        -- Stop the input processing timer
        if (processInputTimer) and isTimer(processInputTimer) then
            killTimer(processInputTimer)
        end

        processInputTimer = nil
    end
end
bindKey("n", "down", toggleNoclip)

local function processPositionUpdate()
    if (not noclipObject) then return end
    if (not newPosition) then return end

    setElementPosition(noclipObject, newPosition.x, newPosition.y, newPosition.z)
    lastPosition.x, lastPosition.y, lastPosition.z = newPosition.x, newPosition.y, newPosition.z
    
    newPosition = nil
    hasPositionUpdated = true
end
addEventHandler("onClientPreRender", root, processPositionUpdate)

function processGroundSnap()
    if (not noclipObject) then return end
    if (not groundSnappingEnabled) then return end

    local x, y, z = getElementPosition(noclipObject)
    local groundZ = getGroundPosition(x, y, z)

    if (groundZ == 0) then
        setElementPosition(noclipObject, x, y, z + 1)
        return
    end

    if (z - groundZ < .33) then
        setElementPosition(noclipObject, x, y, z + .33)
    end
end
addEventHandler("onClientPreRender", root, processGroundSnap)