local mq                      = require('mq')
local ICONS                   = require('mq.Icons')

local parcel_inv              = {}

parcel_inv.sendSources        = {}
parcel_inv.items              = {}
parcel_inv.currentSendItemIdx = 0

parcel_inv.genericSources     = {
    {
        name = "All TS Items",
        filter = function(item)
            return item.Tradeskills()
        end,
    },
    {
        name = "All Collectible Items",
        filter = function(item)
            return item.Collectible()
        end,
    },
}

function parcel_inv:createContainerInventory()
    self.sendSources = self.genericSources

    for i = 23, 34, 1 do
        local slot = mq.TLO.Me.Inventory(i)
        if slot.Container() and slot.Container() > 0 then
            local bagName = string.format("%s (%d)", slot.Name(), slot.ItemSlot())
            table.insert(self.sendSources, { name = bagName, slot = slot, })
        end
    end
end

-- Converts between ItemSlot and /itemnotify pack numbers
function parcel_inv.toPack(slot_number)
    return "pack" .. tostring(slot_number - 22)
end

-- Converts between ItemSlot2 and /itemnotify numbers
function parcel_inv.toBagSlot(slot_number)
    return slot_number + 1
end

function parcel_inv:resetState()
    self.currentSendItemIdx = 0
end

function parcel_inv:getNextItem()
    self.currentSendItemIdx = self.currentSendItemIdx + 1

    if self.currentSendItemIdx > #self.items then
        self.currentSendItemIdx = 0
        return nil
    end

    return self.items[self.currentSendItemIdx]
end

function parcel_inv:getFilteredItems(filterFn)
    self.items = {}
    for i = 23, 34, 1 do
        local slot = mq.TLO.Me.Inventory(i)
        if slot.Container() and slot.Container() > 0 then
            for j = 1, (slot.Container()), 1 do
                if (slot.Item(j)() and not slot.Item(j).NoDrop() and not slot.Item(j).NoRent() and slot.Item(j).Stackable()) and
                    filterFn(slot.Item(j)) then
                    table.insert(self.items, { Item = slot.Item(j), Sent = ICONS.MD_CLOUD_QUEUE, })
                end
            end
        else
            if (slot() and not slot.NoDrop() and not slot.NoRent() and slot.Stackable()) and
                filterFn(slot) then
                table.insert(self.items, { Item = slot, Sent = ICONS.MD_CLOUD_QUEUE, })
            end
        end
    end
end

---@param index number
function parcel_inv:getItems(index)
    local data = self.sendSources[index]

    if not data then return end

    if data.filter ~= nil then
        self:getFilteredItems(data.filter)
    else
        self.items = {}
        local slot = data.slot
        for j = 1, (slot.Container()), 1 do
            if (slot.Item(j)() and not slot.Item(j).NoDrop() and not slot.Item(j).NoRent()) then
                table.insert(self.items, { Item = slot.Item(j), Sent = ICONS.MD_CLOUD_QUEUE, })
            end
        end
    end



    self.currentSendItemIdx = 0
end

return parcel_inv
