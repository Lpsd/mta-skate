Player = inherit(Class)

MIN_SKATE_SPRINT_INPUT_MS = 1666
MIN_SKATE_JUMP_INPUT_MS = 2000

function Player:constructor()
    self.skateboard = nil
    self.lastInputs = {
        sprint = 0,
        jump = 0
    }
    self.grounded = false

    self._dismountSkateboard = bind(self.dismountSkateboard, self)
    bindKey(self, "enter_exit", "down", self._dismountSkateboard)

    self.hasJumped = false

    self.inputs = {
        forward = {
            key = nil,
            state = nil
        },
        jump = {
            key = nil,
            state = nil
        },
        sprint = {
            key = nil,
            state = nil
        }
    }

    self._onInput = bind(self.onInput, self)
    bindKey(self, "w", "both", self._onInput)
    bindKey(self, "s", "both", self._onInput)
    bindKey(self, "space", "both", self._onInput)
    bindKey(self, "lshift", "both", self._onInput)

    toggleControl(self, "forwards", true)
    toggleControl(self, "backwards", true)

    self._processForwardInput = bind(self.processForwardInput, self)
    self.processForwardInputTimer = setTimer(self._processForwardInput, 0, 0)

    self._processJumpInput = bind(self.processJumpInput, self)
    self.processJumpInputTimer = setTimer(self._processJumpInput, 0, 0)

    -- Sync skateboards
    triggerClientEvent("onClientSkateboardInitialSync", self, Skateboard:getAll(true))

    self:spawn()
end

function Player:destructor()
    self:dismountSkateboard()
    unbindKey(self, "enter_exit", "down", self._onEnterExit)
    killTimer(self.processForwardInputTimer)
end

function Player:setGrounded(bool)
    self.grounded = bool

    if (bool) then
        self.hasJumped = false
    end
end

function Player:isGrounded()
    return self.grounded
end

function Player:onInput(me, key, state)
    if (key == "w") or (key == "s") then
        self.inputs.forward = { key = key, state = state }
    end
    if (key == "space") then
        self.inputs.jump = { key = key, state = state }
    end
    if (key == "lshift") then
        self.inputs.sprint = { key = key, state = state }
    end
end

function Player:isForwardInputActive()
    return self.inputs.forward and self.inputs.forward.state == "down"
end

function Player:getForwardInputDirection()
    if (self.inputs.forward.key == "w") then
        return 1
    elseif (self.inputs.forward.key == "s") then
        return -1
    end

    return 0
end

function Player:isJumpInputActive()
    return self.inputs.jump and self.inputs.jump.state == "down"
end

function Player:getSkateboard()
    return self.skateboard
end

function Player:isSprinting()
    return self.inputs.sprint and self.inputs.sprint.state == "down"
end

function Player:setSkateboard(skateboard)
    self.skateboard = skateboard
    triggerClientEvent(self, "onLocalPlayerSkateboardStatus", self, (self.skateboard) and (instanceof(self.skateboard, Skateboard, true)))
    return true
end

function Player:dismountSkateboard()
    if (self.skateboard) then
        iprintd("Player dismounted skateboard", tstr(self), tstr(self.skateboard))
        self.skateboard:onExit()
    end
end

-- Function to spawn a player at the skatepark with a small random offset
function Player:spawn()
    local offsetX = math.random(-1, 1) * 0.5
    local offsetY = math.random(-1, 1) * 0.5
    local spawnX = SKATEPARK_POS.x + offsetX
    local spawnY = SKATEPARK_POS.y + offsetY
    local spawnZ = SKATEPARK_POS.z

    if spawnPlayer(self, spawnX, spawnY, spawnZ) then
        outputChatBox("Welcome to the skatepark!", self)
        outputServerLog("Player spawned", tstr(self), spawnX, spawnY, spawnZ)

        -- Set the camera target to the player
        setCameraTarget(self, self)

        -- Fade the camera in
        fadeCamera(self, true)
    else
        outputChatBox("Failed to spawn player at the skatepark.", self)
        outputServerLog("Failed to spawn player", tstr(self), spawnX, spawnY, spawnZ)
    end
end

function Player:processForwardInput()
    if (not self.skateboard) or (not self:isGrounded()) or (not self:isForwardInputActive()) then
        return
    end

    local didSprint = false

    if (self:isSprinting()) then
        local now = getTickCount()
        local last = self.lastInputs.sprint

        if (last + MIN_SKATE_SPRINT_INPUT_MS <= now) then
            self.skateboard:forward(self:getForwardInputDirection(), true)
            self.lastInputs.sprint = now
            didSprint = true
            iprintd("Player sprinted", tstr(self))
        end
    end

    if (not didSprint) then
        self.skateboard:forward(self:getForwardInputDirection(), false)
    end
end

function Player:processJumpInput()
    if (not self.skateboard) or (not self:isGrounded()) or (not self:isJumpInputActive()) then
        return
    end

    local now = getTickCount()
    local last = self.lastInputs.jump

    if (last + MIN_SKATE_JUMP_INPUT_MS > now) then
        return
    end

    self.skateboard:jump()
    self.lastInputs.jump = now
end