Engine = inherit(Singleton)
preInitializeClass("Engine")

function Engine:constructor()
    self.skateboard = {
        id = nil,
        txd = nil,
        col = nil, -- note: is actually a dff (vehicle col)
        dff = nil,
        ifp = nil
    }

    self:importSkateboard()
    self:importAnims()
end

function Engine:destructor()
    if (not self.skateboard.id) then
        return
    end

    engineFreeModel(self.skateboard.id)
end

function Engine:importSkateboard()
    self.skateboard.id = engineRequestModel("object")

    self.skateboard.txd = engineLoadTXD("assets/skateboard.txd")
    engineImportTXD(self.skateboard.txd, self.skateboard.id)

    self.skateboard.dff = engineLoadDFF("assets/skateboard.dff")
    engineReplaceModel(self.skateboard.dff, self.skateboard.id)

    self.skateboard.col = engineLoadDFF("assets/skateboard.col")
    --engineReplaceModel(self.skateboard.col, SKATEBOARD_VEHICLE_ID)

    SKATEBOARD_MODEL_ID = self.skateboard.id
    triggerServerEvent("onClientSkateboardImported", resourceRoot, self.skateboard.id)

    iprintd("Skateboard imported", self.skateboard)
end

function Engine:importAnims()
    self.skateboard.ifp = engineLoadIFP("assets/skateboard.ifp", "skateboard.general")
end