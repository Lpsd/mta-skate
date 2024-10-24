SyncManager = inherit(Singleton)
preInitializeClass("SyncManager")

SCREEN_WIDTH, SCREEN_HEIGHT = guiGetScreenSize()

function SyncManager:constructor()
    self.skateboards = {}
    self.localPlayerSkateboard = nil

    self:registerEvent("onClientRender", root, bind(self.update, self))
    self:registerEvent("onClientPreRender", root, bind(self.preUpdate, self))

    addEvent("onClientSkateboardCreated", true)
    self:registerEvent("onClientSkateboardCreated", resourceRoot, bind(self.addSkateboard, self))

    addEvent("onClientSkateboardDestroyed", true)
    self:registerEvent("onClientSkateboardDestroyed", resourceRoot, bind(self.removeSkateboard, self))

    addEvent("onClientSkateboardRiderChanged", true)
    self:registerEvent("onClientSkateboardRiderChanged", resourceRoot, bind(self.setSkateboardRider, self))

    addEvent("onClientSkateboardInitialSync", true)
    self:registerEvent("onClientSkateboardInitialSync", resourceRoot, bind(self.onSkateboardInitialSync, self))

    addEvent("onClientSkateAnimationRequest", true)
    self:registerEvent("onClientSkateAnimationRequest", resourceRoot, bind(self.onSkateAnimationRequest, self))

    addEvent("onClientSkateAnimationCancel", true)
    self:registerEvent("onClientSkateAnimationCancel", resourceRoot, bind(self.onSkateAnimationCancel, self))

    setVehicleModelWheelSize(SKATEBOARD_VEHICLE_ID, "all_wheels", 0.15)

    local modes = {getCameraViewMode()}
    self.defaultCameraViewModes = {
        vehicle = modes[1],
        ped = modes[2]
    }

    self.pedAnimTimers = {}

    setElementAlpha(localPlayer, 255)
end

function SyncManager:destructor()
    setElementAlpha(localPlayer, 255)
    setCameraViewMode(self.defaultCameraViewModes.vehicle, self.defaultCameraViewModes.ped)

    for vehicle in pairs(self.skateboards) do
        self:removeSkateboard(vehicle)
    end

    for ped, timer in pairs(self.pedAnimTimers) do
        if (isTimer(timer)) then
            killTimer(timer)
        end
    end
end

function SyncManager:onSkateboardInitialSync(skateboards)
    self:addSkateboards(skateboards)
end

function SyncManager:addSkateboards(skateboards)
    for _, skateboard in ipairs(skateboards) do
        self:addSkateboard(skateboard)
    end
end

function SyncManager:addSkateboard(skateboard)
    if (self.skateboards[skateboard.vehicle]) then
        return
    end

    self.skateboards[skateboard.vehicle] = {
        vehicle = skateboard.vehicle,
        object = nil,
        rider = nil,
        ghostRider = nil,
        ped = nil
    }

    self.skateboards[skateboard.vehicle].object = createObject(SKATEBOARD_MODEL_ID, 0, 0, 0)
    setElementCollisionsEnabled(self.skateboards[skateboard.vehicle].object, false)
end

function SyncManager:removeSkateboard(vehicle)
    if (not self.skateboards[vehicle]) then
        return
    end

    destroyElement(self.skateboards[vehicle].object)

    if (isElement(self.skateboards[vehicle].ped)) then
        destroyElement(self.skateboards[vehicle].ped)
    end

    self.skateboards[vehicle] = nil
end

function SyncManager:setSkateboardRider(vehicle, rider, ghostRider)
    self.skateboards[vehicle].rider = rider
    self.skateboards[vehicle].ghostRider = ghostRider

    if (rider == localPlayer) then
        local localSkateboard = LocalSkateboard:getInstance()

        if (localSkateboard.skateboard) then
            localSkateboard.skateboard.ghostRider = ghostRider
        end
    end
end

function SyncManager:getSkateboardByRider(rider)
    for vehicle, data in pairs(self.skateboards) do
        if (data.rider == rider) then
            return data
        end
    end

    return false
end

function SyncManager:update()
    local camRot = getCamera().rotation

    for vehicle, data in pairs(self.skateboards) do
        local rot = vehicle.rotation

        if (data.rider ~= localPlayer) then
            setElementRotation(data.object, rot.x, rot.y, rot.z)
        end
        
        local up = vehicle.matrix.up * .6
        setElementPosition(data.object, vehicle.position.x + up.x, vehicle.position.y + up.y, vehicle.position.z + up.z)
    end

    if (self.localPlayerSkateboard) then
        setElementRotation(localPlayer, 0, 0, camRot.z)
        setElementRotation(self.localPlayerSkateboard.ped, self.localPlayerSkateboard.vehicle.rotation.x, self.localPlayerSkateboard.vehicle.rotation.y, camRot.z)
        setElementRotation(self.localPlayerSkateboard.object, self.localPlayerSkateboard.vehicle.rotation.x, self.localPlayerSkateboard.vehicle.rotation.y, camRot.z)
        --setElementRotation(self.localPlayerSkateboard.vehicle, localPlayer.rotation.x, localPlayer.rotation.y, camRot.z)
    end
end

function SyncManager:preUpdate()
end

function SyncManager:onSkateAnimationRequest(rider, animName, duration, loop)
    loop = (loop ~= nil) and loop or true
    local skateboard = self:getSkateboardByRider(rider)

    if (not skateboard) then
        return
    end

    local ped = skateboard.ped

    if (not isElement(ped)) then
        return
    end

    local currentAnimBlock, currentAnimName = getPedAnimation(ped)

    if (currentAnimBlock) then
        if (currentAnimBlock == "skateboard.general") then
            if (currentAnimName == "CHOPPA_sprint") and (animName == "CHOPPA_ride") then
                return
            elseif (currentAnimName == "CHOPPA_Left") or (currentAnimName == "CHOPPA_Right") or (currentAnimName == "run_wuzi") then
                return
            elseif (currentAnimName == "CHOPPA_bunnyhop") then
                return
            elseif (currentAnimName == animName) then
                return
            end
        end
    end

    duration = tonumber(duration) or 2000
    setPedAnimation(ped, "skateboard.general", animName, duration, true, false, false)

    if (self.pedAnimTimers[ped]) then
        killTimer(self.pedAnimTimers[ped])
    end

    self.pedAnimTimers[ped] = setTimer(bind(function()
        if (not isElement(ped)) then
            self.pedAnimTimers[ped] = nil
            return
        end

        setPedAnimation(ped, "skateboard.general", "CHOPPA_ride", 2000, true, false, false)
        self.pedAnimTimers[ped] = nil
    end, self), duration, 1)
end

function SyncManager:onSkateAnimationCancel(rider)
    local skateboard = self:getSkateboardByRider(rider)

    if (not skateboard) then
        return
    end

    local ped = skateboard.ped

    if (not isElement(ped)) then
        return
    end

    setPedAnimation(ped, "skateboard.general", "CHOPPA_ride", 2000, true, false, false)
end