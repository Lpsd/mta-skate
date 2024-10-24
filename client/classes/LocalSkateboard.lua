LocalSkateboard = inherit(Singleton)
preInitializeClass("LocalSkateboard")

function LocalSkateboard:constructor()
    addEvent("onLocalPlayerSkateboardStatus", true)
    self:registerEvent("onLocalPlayerSkateboardStatus", localPlayer, bind(self.onLocalPlayerSkateboardStatus, self))

    self:registerEvent("onClientRender", root, bind(self.update, self))
    self:registerEvent("onClientPreRender", root, bind(self.preUpdate, self))

    self.turn = {
        left = false,
        right = false,
        targetRotation = 15,
        currentRotation = 0,
        duration = 500,
        start = 0,
        startRotation = 0
    }

    local modes = {getCameraViewMode()}
    self.defaultCameraViewModes = {
        vehicle = modes[1],
        ped = modes[2]
    }

    setElementAlpha(localPlayer, 255)
    self.isGrounded = false
end

function LocalSkateboard:destructor()
    setElementAlpha(localPlayer, 255)
    setCameraViewMode(self.defaultCameraViewModes.vehicle, self.defaultCameraViewModes.ped)
end

function LocalSkateboard:onLocalPlayerSkateboardStatus(status)
    local syncManager = SyncManager:getInstance()

    if (status) then
        self.skateboard = syncManager:getSkateboardByRider(localPlayer)

        local ped = createPed(getElementModel(localPlayer), 0, 0, 0)
        syncManager.skateboards[self.skateboard.vehicle].ped = ped

        setCameraViewMode(3)

        setElementCollisionsEnabled(localPlayer, false)
        setElementCollisionsEnabled(ped, false)

        attachElements(localPlayer, self.skateboard.object, 0, 0, 0.425)
        attachElements(ped, self.skateboard.object, 0, 0, 0.425)

        setElementPosition(ped, self.skateboard.vehicle.position.x, self.skateboard.vehicle.position.y, self.skateboard.vehicle.position.z + 0.425)

        setElementAlpha(localPlayer, 0)
        setPedAnimation(ped)
        syncManager:onSkateAnimationRequest(localPlayer, "CHOPPA_ride", 2000, true)
    else
        setCameraViewMode(syncManager.defaultCameraViewModes.ped)

        detachElements(localPlayer, self.skateboard.object)
        detachElements(self.skateboard.ped, self.skateboard.object)

        setElementCollisionsEnabled(localPlayer, true)
        setElementAlpha(localPlayer, 255)

        destroyElement(self.skateboard.ped)

        syncManager.skateboards[self.skateboard.vehicle].ped = nil
        self.skateboard = nil
    end
end

function LocalSkateboard:update()
    local camRot = getCamera().rotation
    local syncManager = SyncManager:getInstance()

    if (self.skateboard) then
        setElementRotation(localPlayer, 0, 0, camRot.z)
        setElementRotation(self.skateboard.ped, self.skateboard.vehicle.rotation.x, self.skateboard.vehicle.rotation.y, camRot.z)
        setElementRotation(self.skateboard.object, self.skateboard.vehicle.rotation.x, self.skateboard.vehicle.rotation.y, camRot.z)
        setElementRotation(self.skateboard.vehicle, self.skateboard.vehicle.rotation.x, self.skateboard.vehicle.rotation.y, camRot.z)
        if (self.skateboard.ghostRider) then
            setPedControlState(self.skateboard.ghostRider, "vehicle_left", false)
            setPedControlState(self.skateboard.ghostRider, "vehicle_right", false)
            setPedControlState(self.skateboard.ghostRider, "vehicle_forward", false)
            setPedControlState(self.skateboard.ghostRider, "vehicle_reverse", false)
            setPedControlState(self.skateboard.ghostRider, "steer_forward", false)
            setPedControlState(self.skateboard.ghostRider, "steer_back", false)
            setPedControlState(self.skateboard.ghostRider, "accelerate", false)
            setPedControlState(self.skateboard.ghostRider, "brake_reverse", false)

            local keyPressed = false

            if (getKeyState("a")) then
                if (not self.turn.left) then
                    self.turn.left = true
                    self.turn.right = false
                    self.turn.start = getTickCount()
                    self.turn.startRotation = self.skateboard.vehicle.rotation.z
                end
                local progress = (getTickCount() - self.turn.start) / self.turn.duration
                local rotation = interpolateBetween(self.turn.currentRotation, 0, 0, self.turn.targetRotation, 0, 0, progress, "InOutQuad")
                local diff = (self.skateboard.vehicle.rotation.z - self.turn.startRotation)
                setElementRotation(self.skateboard.vehicle, self.skateboard.vehicle.rotation.x, self.skateboard.vehicle.rotation.y, diff + self.turn.startRotation + rotation)
                setElementRotation(self.skateboard.object, self.skateboard.vehicle.rotation.x, self.skateboard.vehicle.rotation.y, diff + self.turn.startRotation + rotation)

                setPedControlState(self.skateboard.ghostRider, "vehicle_left", true)

                local animBlock, animName = getPedAnimation(self.skateboard.ped)
                iprintd(animName)
                if (animName ~= "CHOPPA_Right") and (animName ~= "run_wuzi") then
                    setPedAnimation(self.skateboard.ped, "skateboard.general", "CHOPPA_Right", 200, false)
                end

                keyPressed = true
            elseif (getKeyState("d")) then
                if (not self.turn.right) then
                    self.turn.right = true
                    self.turn.left = false
                    self.turn.start = getTickCount()
                    self.turn.startRotation = self.skateboard.vehicle.rotation.z
                end
                local progress = (getTickCount() - self.turn.start) / self.turn.duration
                local rotation = interpolateBetween(self.turn.currentRotation, 0, 0, -self.turn.targetRotation, 0, 0, progress, "InOutQuad")
                local diff = (self.skateboard.vehicle.rotation.z - self.turn.startRotation)
                setElementRotation(self.skateboard.vehicle, self.skateboard.vehicle.rotation.x, self.skateboard.vehicle.rotation.y, diff + self.turn.startRotation + rotation)
                setElementRotation(self.skateboard.object, self.skateboard.vehicle.rotation.x, self.skateboard.vehicle.rotation.y, diff + self.turn.startRotation + rotation)

                setPedControlState(self.skateboard.ghostRider, "vehicle_right", true)

                local animBlock, animName = getPedAnimation(self.skateboard.ped)
                if (animName ~= "CHOPPA_Left") and (animName ~= "run_wuzi") then
                    setPedAnimation(self.skateboard.ped, "skateboard.general", "CHOPPA_Left", 200, false)
                end

                keyPressed = true
            end

            if (getKeyState("w")) then
                if (not self.isGrounded) then
                    setPedControlState(self.skateboard.ghostRider, "steer_forward", true)
                elseif (not getKeyState("shift")) then
                    setPedControlState(self.skateboard.ghostRider, "accelerate", true)
                end

                keyPressed = true
            elseif (getKeyState("s")) and (not self.isGrounded) then
                if (not self.isGrounded) then
                    setPedControlState(self.skateboard.ghostRider, "steer_back", true)
                elseif (not getKeyState("shift")) then
                    setPedControlState(self.skateboard.ghostRider, "brake_reverse", true)
                end

                keyPressed = true
            end

            if (not keyPressed) then
                local animBlock, animName = getPedAnimation(self.skateboard.ped)
                if (animName == "CHOPPA_Left") or (animName == "CHOPPA_Right") or (not animName) then
                    setPedAnimation(self.skateboard.ped, "skateboard.general", "CHOPPA_ride", 100, false)
                end
            end
        end
    end
end

function LocalSkateboard:preUpdate()
    -- Check if player is grounded using processLineOfSight
    local x, y, z = getElementPosition(self.skateboard and self.skateboard.vehicle or localPlayer)
    local hit, hx, hy, hz, hitElement, nx, ny, nz, material, lighting, piece = processLineOfSight(x, y, z, x, y, z - (self.skateboard and .15 or 1.2), true, false, false, false, false, false, true, true, self.skateboard and self.skateboard.vehicle or localPlayer, true, false)
    dxDrawLine3D(x, y, z, x, y, z - (self.skateboard and .2 or 1.1), tocolor(255, 0, 0), 2)
    if (hitElement) then
        if (getElementType(hitElement) == "vehicle") or (getElementType(hitElement) == "player") or (getElementType(hitElement) == "ped") then
            hit = false
        end
    end

    if (hit ~= self.isGrounded) then
        self.isGrounded = hit
        triggerServerEvent("onClientGroundedStatus", resourceRoot, self.isGrounded)
    end

    if (self.skateboard) then
        local rot = self.skateboard.vehicle.rotation
        local vx, vy, vz = round(rot.x, 2), round(rot.y, 2), round(rot.z, 2)
        dxDrawText("Rotation X: " .. vx .. "\nRotation Y: " .. vy .. "\nRotation Z: " .. vz, SCREEN_WIDTH - 200, 0, 0, 0, tocolor(255, 255, 255), 1, "default-bold")
        local up = self.skateboard.vehicle.matrix.up * .6
        setElementPosition(localPlayer, self.skateboard.vehicle.position.x + up.x, self.skateboard.vehicle.position.y + up.y, self.skateboard.vehicle.position.z + up.z)
    end
end