local skateboards = {}

Skateboard = inherit(Class)

SKATE_SPEED = 1.33
SKATE_SPRINT_MULTIPLIER = 2.5
SKATE_SPRINT_DURATION = 500
SKATE_BACKWARDS_MULTIPLIER = .5

function Skateboard:constructor(x, y, z)
    self.vehicle = createVehicle(SKATEBOARD_VEHICLE_ID, x, y, z)
    setElementAlpha(self.vehicle, 0)
    self:setupHandling()

    self._onEnter = bind(self.onEnter, self)
    addEventHandler("onVehicleStartEnter", self.vehicle, self._onEnter)

    self.rider = nil
    self.ghostRider = nil
    self.dismounting = false

    self.speed = SKATE_SPEED
    self.sprintMultiplier = SKATE_SPRINT_MULTIPLIER
    self.sprintDuration = SKATE_SPRINT_DURATION
    self.sprintStart = 0
    self.sprintActive = false

    self._update = bind(self.update, self)
    self.updateTimer = setTimer(self._update, 32, 0)

    triggerClientEvent(getElementsByType("player"), "onClientSkateboardCreated", resourceRoot, { vehicle = self.vehicle })
    skateboards[self.vehicle] = self
end

function Skateboard:destructor()
    if (self.rider) and (instanceof(self.rider, Player, true)) then
        toggleControl(self.rider, "forwards", true)
        toggleControl(self.rider, "backwards", true)
    end

    destroyElement(skateboard.vehicle)

    removeEventHandler("onVehicleStartEnter", self.vehicle, self._onEnter)
    killTimer(self.updateTimer)

    if (self.ghostRiderWarpTimer) and (isTimer(self.ghostRiderWarpTimer)) then
        killTimer(self.ghostRiderWarpTimer)
        self.ghostRiderWarpTimer = nil
    end

    triggerClientEvent(getElementsByType("player"), "onClientSkateboardDestroyed", resourceRoot, self.vehicle)
    skateboards[self.vehicle] = nil
end

function Skateboard:setSpeed(speed)
    speed = tonumber(speed)
    if (not speed) then return end
    self.speed = speed
end

function Skateboard:setSprintMultiplier(multiplier)
    multiplier = tonumber(multiplier)
    if (not multiplier) or (multiplier < 1) then return end
    self.sprintMultiplier = multiplier
end

function Skateboard:setupHandling()
    if (self.__handling) then return end

    iprintd(getVehicleHandling(self.vehicle, "handlingFlags"))

    setVehicleHandling(self.vehicle, "mass", 250)
    setVehicleHandling(self.vehicle, "turnMass", 10)
    setVehicleHandling(self.vehicle, "tractionLoss", 1.25)
    setVehicleHandling(self.vehicle, "maxVelocity", 25)
    setVehicleHandling(self.vehicle, "driveType", "rwd")
    setVehicleHandling(self.vehicle,  "modelFlags", VEH_MODEL_FLAGS.DOUBLE_RWHEELS)
    setVehicleHandling(self.vehicle,  "handlingFlags", VEH_HANDLING_FLAGS.NPC_NEUTRAL_HANDL)
    
    local veh = self.vehicle.position
    local forward = -(self.vehicle.matrix.forward * .001)
    local up = (self.vehicle.matrix.up * .1)
    setVehicleHandling(self.vehicle, "centerOfMass", { forward.x + up.x, forward.y + up.y, forward.z + up.z })

    iprintd(getVehicleHandling(self.vehicle, "handlingFlags"))

    self.__handling = true
end

function Skateboard:onEnter(ped)
    cancelEvent()

    if (self.rider) then
        return
    elseif (self.dismounting) then
        self.dismounting = false
        return
    end

    setElementPosition(ped, self.vehicle.position + Vector3(0, 0, .5))
    
    self.ghostRider = createPed(0, self.vehicle.position + Vector3(0, 0, .5))
    setElementAlpha(self.ghostRider, 0)

    self.ghostRiderWarpTimer = setTimer(bind(function()
        if (not isElement(self.ghostRider)) then
            return
        end

        warpPedIntoVehicle(self.ghostRider, self.vehicle)
        self.ghostRiderWarpTimer = nil
    end, self), 1, 0)
    

    self.rider = ped
    triggerClientEvent(getElementsByType("player"), "onClientSkateboardRiderChanged", resourceRoot, self.vehicle, ped, self.ghostRider)

    if (instanceof(ped, Player, true)) then
        ped:setSkateboard(self)
        setCameraTarget(ped, self.vehicle)
        toggleControl(ped, "forwards", false)
        toggleControl(ped, "backwards", false)
        
        iprintd("Player mounted skateboard", tstr(ped), tstr(self))
    end
end

function Skateboard:onExit()
    if (self.rider) then
        triggerClientEvent(getElementsByType("player"), "onClientSkateboardRiderChanged", resourceRoot, self.vehicle, nil)

        if (instanceof(self.rider, Player, true)) then
            self.rider:setSkateboard(nil)
            setCameraTarget(self.rider, self.rider)
            toggleControl(self.rider, "forwards", true)
            toggleControl(self.rider, "backwards", true)
        end

        removePedFromVehicle(self.ghostRider)
        destroyElement(self.ghostRider)
        self.ghostRider = nil

        self.rider = nil
        self.dismounting = true
    end
end

function Skateboard:forward(f, sprint)
    if (not self.rider) or (not self.rider:isGrounded()) then
        return
    end

    sprint = (sprint ~= nil) and sprint or false
    f = tonumber(f)
    if (not f) then return end

    local speed = self.speed

    local vx, vy, vz = getElementVelocity(self.vehicle)
    local speedms = (vx^2 + vy^2 + vz^2)^(0.5) * 50

    local moveVector = self.rider.matrix.forward * (f / 10)

    local now = getTickCount()

    if (sprint) then
        self.sprintStart = now
        self.sprintActive = true
    end

    if (self.sprintActive) and (now - self.sprintStart >= self.sprintDuration) then
        self.sprintActive = false
    end

    if (f < 0) then
        triggerClientEvent(getElementsByType("player"), "onClientSkateAnimationRequest", resourceRoot, self.rider, "CHOPPA_Pushes", 2000)
    else
        if (sprint) then
            triggerClientEvent(getElementsByType("player"), "onClientSkateAnimationRequest", resourceRoot, self.rider, "CHOPPA_sprint", 1333, false)
        else
            triggerClientEvent(getElementsByType("player"), "onClientSkateAnimationRequest", resourceRoot, self.rider, "CHOPPA_ride", 2000)
        end
    end
    
    if (self.sprintActive)  and (f > 0) and (not self.rider.hasJumped) then
        speed = speed * self.sprintMultiplier

        -- Apply it after .5 seconds
        setTimer(bind(function()
            if (not self.vehicle) or (not self.rider) or (not self.rider:isGrounded()) then
                triggerClientEvent(getElementsByType("player"), "onClientSkateAnimationCancel", resourceRoot, self.rider)
                return
            end
            local vv = self.vehicle.velocity
            vv.z = 0
            setElementVelocity(self.vehicle, (vv / 3) + (moveVector * speed))
        end, self), 500, 1)
    elseif (f < 0)  then
        speed = speed / 3
        if (speedms < 8) then
            moveVector.z = -0.01
            setElementVelocity(self.vehicle, (moveVector * speed * SKATE_BACKWARDS_MULTIPLIER))
        end
    end
end

function Skateboard:jump()
    if (not self.rider) or (not self.rider:isGrounded()) then return end

    triggerClientEvent(getElementsByType("player"), "onClientSkateAnimationRequest", resourceRoot, self.rider, "CHOPPA_bunnyhop", 250, false)

    -- Apply it after .3 seconds
    setTimer(bind(function()
        if (not self.vehicle) then return end
        local x, y, z = getElementVelocity(self.vehicle)
        local vel = (Vector3(x, y, 0) + Vector3(0, 0, .2) * 1.33)
        setElementVelocity(self.vehicle, vel)
        setTimer(bind(function()
            if (not self.rider) then return end 
            self.rider.hasJumped = true
        end, self), 200, 1)
    end, self), 300, 1)
end

function Skateboard:update()
    if (not self.vehicle) then return end

    if (self.rider) then
        if (self.vehicle.rotation.x > 90) and (self.vehicle.rotation.x < 270) then
            return self:onExit()
        end
        if (self.vehicle.rotation.y > 80) and (self.vehicle.rotation.y < 280) then
            return self:onExit()
        end
    end

    setElementHealth(self.vehicle, 1000)
end

function Skateboard:getAll(sync)
    if (not sync) then
        return skateboards
    end

    local t = {}
    for _, skateboard in pairs(skateboards) do
        t[#t + 1] = { vehicle = skateboard.vehicle, object = skateboard.object }
    end
    return t
end