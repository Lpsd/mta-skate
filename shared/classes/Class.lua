Class = {}

function Class:new(...)
    return new(self, ...)
end

function Class:delete(...)
    return delete(self, ...)
end

function Class:virtual_constructor()
    self.__events = {}
end

function Class:virtual_destructor()
    self:unregisterEvents()
end

function Class:registerEvent(eventName, attachedTo, handlerFunction, getPropagated, priority)
    if (not eventName) or (not attachedTo) or (not handlerFunction) then
        return false
    end

    if (not self.__events) then
        self.__events = {}
    end

    getPropagated = (getPropagated == nil) and true or getPropagated
    priority = priority or "normal"

    addEventHandler(eventName, attachedTo, handlerFunction, getPropagated, priority)

    return table.insert(
        self.__events,
        {
            eventName = eventName,
            attachedTo = attachedTo,
            handlerFunction = handlerFunction
        }
    )
end

-- ********************************************************************************************************************************** --

function Class:unregisterEvent(eventName, attachedTo, handlerFunction)
    local removed = false
    for i, event in ipairs(self.__events) do
        if
            (event.eventName == eventName) and (event.attachedTo == attachedTo) and
                (event.handlerFunction == handlerFunction)
         then
            removed = removeEventHandler(event.eventName, event.attachedTo, event.handlerFunction)
            break
        end
    end
    return removed
end

function Class:unregisterEvents()
    if (not self.__events) or (self.__unregisterEvents) then
        return false
    end

    for i, event in ipairs(self.__events) do
        removeEventHandler(event.eventName, event.attachedTo, event.handlerFunction)
    end

    self.__unregisterEvents = true
end

-- ********************************************************************************************************************************** --