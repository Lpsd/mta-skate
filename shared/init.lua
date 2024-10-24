__classList = {}

-- Load all of _our_ custom classes (which inherit from Class)
for k, v in pairs(_G) do
    if (type(v) == "table") then
        local mt = getmetatable(v)

        if (mt) and (mt.__super) and (instanceof(v, Class) or instanceof(v, Class, true)) then
            __classList[v] = k
        end
    end
end

-- Initialize autoload classes (usually singletons or managers)
Autoloader:loadClasses()

-- Unload all classes when resource stops
function unloadClasses()
    Autoloader:unloadClasses()
end
addEventHandler(SERVER and "onResourceStop" or "onClientResourceStop", resourceRoot, unloadClasses)