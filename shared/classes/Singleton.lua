Singleton = inherit(Class)

function Singleton:new(...)
    return self:getInstance(...)
end

function Singleton:getInstance(...)
    if (not self.__instance) then
        self.__instance = new(self, ...)
    end

    return self.__instance
end
