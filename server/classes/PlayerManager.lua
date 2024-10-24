PlayerManager = inherit(Singleton)
preInitializeClass("PlayerManager")

local PLAYER_CLASS = Player

function PlayerManager:constructor()
    self.players = {}
    self.playerSkateboardModelIds = {}

    self:registerEvent("onPlayerResourceStart", root, bind(function(self, r)
        iprintd("PlayerManager: Resource started", r)
        if (r == resource) then
            self:register(source)
        end
    end, self))

    self:registerEvent("onPlayerQuit", root, bind(function(self)
        iprintd("PlayerManager: Player quit", tstr(source))
        self:unregister(source)
    end, self))

    addEvent("onClientSkateboardImported", true)
    self:registerEvent("onClientSkateboardImported", resourceRoot, bind(function(self, id)
       self:onClientSkateboardImported(client, id)
    end, self))

    addEvent("onClientGroundedStatus", true)
    self:registerEvent("onClientGroundedStatus", resourceRoot, bind(function(self, grounded)
        if (not client) then
            return
        end
        self:onClientGroundedStatus(client, grounded)
    end, self))
end

function PlayerManager:onClientGroundedStatus(player, isGrounded)
    if (not self.players[player]) then
        return
    end

    player:setGrounded(isGrounded)
end

function PlayerManager:onClientSkateboardImported(player, skateboardId)
    if (not player) then
        return
    end

    self.playerSkateboardModelIds[player] = skateboardId
    iprintd("PlayerManager: Skateboard imported", player, skateboardId)
end

function PlayerManager:register(player)
    if (not player) or (not isElement(player)) or (not getElementType(player) == "player") then
        return false
    end

    if (self.players[player]) then
        return false
    end

    iprintd("PlayerManager: Registered player", tstr(player))
    self.players[player] = enew(player, PLAYER_CLASS)
end

function PlayerManager:unregister(player)
    player:delete()
    self.players[player] = nil
end

function PlayerManager:count() -- static
    if (not self) then
        self = PlayerManager:getInstance()
    end

    local i = 0
    for _, _ in pairs(self.players) do
        i = i + 1
    end
    return i
end

function PlayerManager:getAll() -- static
    if (not self) then
        self = PlayerManager:getInstance()
    end

    return self.players
end