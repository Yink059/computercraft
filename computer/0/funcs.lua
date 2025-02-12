os.loadAPI("vars.lua")

-- filter function
function ignoreNamedChests(name, _)
    if name == vars.DEPOSIT_CHEST or name == vars.WITHDRAWAL_CHEST then
        return false
    else
        return true
    end
end

-- returns a table of name : count values
function getInventory()
    local inventory = {}
    local chests = { peripheral.find("minecraft:chest", ignoreNamedChests) }
    for _, chest in ipairs(chests) do
        for _, item in pairs(chest.list()) do
            if inventory[item.name] then
                inventory[item.name] = inventory[item.name] + item.count
            else
                inventory[item.name] = item.count
            end
        end
    end
    return inventory
end

-- returns bool
function sendToPlayer(itemName, itemCount)
    -- move items to withdrawal chest
    local numMoved = 0 
    local leftToMove = itemCount
    local chests = { peripheral.find("minecraft:chest", ignoreNamedChests) }
    for _, chest in ipairs(chests) do
        if leftToMove > 0 then
            for slot, item in pairs(chest.list()) do
                if leftToMove > 0 then
                    if item.name == itemName then
                        numMoved = numMoved + chest.pushItems(vars.WITHDRAWAL_CHEST, slot, leftToMove)
                        leftToMove = leftToMove - numMoved
                    end
                end
            end
        end
    end
    -- add items to player
    local invMgr = peripheral.wrap(vars.INVENTORY_MANAGER)
    if not invMgr then
        return false
    else
        return invMgr.addItemToPlayer("right", itemCount, nil, itemName) == itemCount
    end
end

-- import from deposit chest, returns bool
function deposit()
    depositChest = peripheral.wrap(vars.DEPOSIT_CHEST)
    local chests = { peripheral.find("minecraft:chest", ignoreNamedChests) }
    for slot, item in pairs(depositChest.list()) do
        local numMoved = 0 
        local leftToMove = item.count
        for _, chest in ipairs(chests) do
            if leftToMove > 0 then
                numMoved = numMoved + depositChest.pushItems(peripheral.getName(chest), slot, leftToMove)
                leftToMove = leftToMove - numMoved
            end
        end
        if leftToMove > 0 then
            print("Inventory is full!")
            return false
        end
    end
    return true
end

-- returns bool
function depositPlayersLastRow()
    -- clear deposit chest first
    if deposit() then
        -- move items from player to deposit chest
        local invMgr = peripheral.wrap(vars.INVENTORY_MANAGER)
        for i=28, 36 do
            invMgr.removeItemFromPlayer("left", 64, i)
        end
        -- deposit from deposit chest
        return deposit()
    else
        return false
    end
end