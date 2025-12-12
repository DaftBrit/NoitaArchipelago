return {
    protocol_version = 2,

    pseudo_hash = function(self, str)
        local hash = 5381

        for i = 1, #str do
            local left_hash = math.floor(hash / (2 ^ 26))
            local right_hash = (hash - left_hash * (2 ^ 26)) * (2 ^ 5)
            hash = ((right_hash + left_hash) + hash) + string.byte(str, i)
        end

        return hash
    end,

    -- Function to generate a pseudo-GUID
    generate_GUID = function(self, extra_random)
        local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
        math.randomseed(self:pseudo_hash(os.time() .. "|" .. extra_random))
        return string.gsub(template, '[xy]', function(c)
            local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
            return string.format('%x', v)
        end)
    end,

    -- general giftbox operations
    open_giftbox = function(self, any_gift, traits)
        assert(type(any_gift) == "boolean")
        if any_gift and traits == nil then
            traits = {}
        end
        assert(type(traits) == "table")

        self.ap:Get({"GiftBoxes;" .. self.ap:get_team_number()}, {
            id = self.id,
            action = "open_giftbox",
            any_gift = any_gift,
            traits = traits
        })
    end,

    close_giftbox = function(self)
        if not self.is_open then
            return
        end
        self.ap:Get({"GiftBoxes;" .. self.ap:get_team_number()}, {
            id = self.id,
            action = "close_giftbox"
        })
    end,

    -- handlers

    set_gift_notification_handler = function(self, func)
        assert(func == nil or type(func) == "function")
        self.gift_notification_handler = func
    end,

    set_gift_handler = function(self, func)
        assert(func == nil or type(func) == "function")
        self.gift_handler = func
    end,

    -- gift transmitters

    start_gift_recovery = function(self, gift_number)
        if not self.is_open then
            return false
        end
        local giftbox_name = "GiftBox;" .. self.ap:get_team_number() .. ";" .. self.ap:get_player_number()
        if gift_number < 0 then
            self.ap:Set(giftbox_name, {}, true, {{"replace", {}}}, {
                giftbox_gathering = self.ap:get_player_number()
            })
        else
            local operations = {}
            for i = 1, gift_number, 1 do
                operations[i] = {"pop", 0}
            end
            self.ap:Set(giftbox_name, {}, true, operations, {
                giftbox_gathering = self.ap:get_player_number()
            })
        end
        return true
    end,

    add_gift_to_giftbox = function(self, gift)
        local giftbox_name = "GiftBox;" .. gift.receiver_team .. ";" .. gift.receiver_number
        gift.receiver_team = nil
        gift.receiver_number = nil

        self.ap:Set(giftbox_name, {}, false, {{"update", {
            [gift.ID] = gift
        }}})
    end,

    start_checking_gift = function(self, gift)
        local motherbox = "GiftBoxes;" .. gift.receiver_team

        self.ap:Get({motherbox}, {
            id = self.id,
            action = "check_gift",
            gift = gift
        })
    end,

    send_gift = function(self, gift)
        assert(type(gift.ItemName) == "string")
        assert(type(gift.ReceiverName) == "string")

        local receiver_name
        if gift.IsRefund then
            assert(type(gift.SenderName) == "string")
            receiver_name = gift.SenderName
        else
            receiver_name = gift.ReceiverName
        end

        for _, player in pairs(self.ap:get_players()) do
            if player.name == receiver_name or player.alias == receiver_name then
                gift.receiver_team = player.team
                gift.receiver_number = player.slot
            end
        end

        if gift.ID == nil then
            gift.ID = self:generate_GUID(self.ap:get_player_number() .. "|" .. gift.ItemName)
        end

        if gift.Amount == nil then
            gift.Amount = 1
        end
        if gift.ItemValue == nil then
            gift.ItemValue = 0
        end

        if gift.SenderName == nil then
            gift.SenderName = self.ap:get_slot()
        end

        if gift.SenderTeam == nil then
            gift.SenderTeam = self.ap:get_team_number()
        end

        if gift.ReceiverTeam == nil then
            gift.ReceiverTeam = gift.receiver_team
        end

        if gift.IsRefund == nil then
            gift.IsRefund = false
        end

        if gift.GiftValue == nil then
            gift.GiftValue = gift.Value * gift.Amount
        end

        if gift.receiver_number == nil then
            if not gift.IsRefund then
                gift.IsRefund = true
                self:send_gift(gift)
            end
        elseif gift.IsRefund then
            self:add_gift_to_giftbox(gift)
        else
            self:start_checking_gift(gift)
        end
    end,

    -- callback functions

    check_gift = function(self, map, extra_data)
        local gift = extra_data.gift
        if map ~= nil then
            local motherbox = map[tostring(gift.receiver_number)]
            if motherbox ~= nil and motherbox.IsOpen then
                local accepts_gift = motherbox.AcceptsAnyGift
                if not accepts_gift then
                    for trait in gift.traits do
                        for accepted_trait in motherbox.DesiredTraits do
                            if trait == accepted_trait then
                                accepts_gift = true
                                break
                            end
                        end

                        if accepts_gift then
                            break
                        end
                    end
                end

                if accepts_gift then
                    self:add_gift_to_giftbox(gift)
                    return
                end
            end
        end
        gift.IsRefund = true
        self:send_gift(gift)
    end,

    check_giftbox_info = function(self, motherbox)
        local player_number = self.ap:get_player_number()
        if motherbox ~= nil then
            if type(motherbox) ~= "table" then
                return false -- motherbox not recognized
            else
                local giftbox_info = motherbox[tostring(player_number)]
                if giftbox_info ~= nil then
                    if type(giftbox_info) ~= "table" then
                        return false -- giftbox not recognized
                    else
                        if giftbox_info.MinimumGiftDataVersion ~= self.protocol_version or
                            giftbox_info.MaximumGiftDataVersion ~= self.protocol_version then
                            return false -- version system not recognized
                        end
                    end
                end
            end
        end
        return true
    end,

    open_ap_giftbox = function(self, motherbox, giftbox_settings)
        if not self:check_giftbox_info(motherbox) then
            self.is_open = false -- Something has gone horribly wrong, this should only happen if the giftbox protocol has updated and is no longer recognized
            return
        end

        if #giftbox_settings.traits == 0 then
            giftbox_settings.traits = self.ap.EMPTY_ARRAY
        end

        local player_number = self.ap:get_player_number()

        self.ap:Set("GiftBoxes;" .. self.ap:get_team_number(), {}, true, {{"update", {
            [player_number] = {
                IsOpen = true,
                AcceptsAnyGift = giftbox_settings.any_gift,
                DesiredTraits = giftbox_settings.traits,
                MinimumGiftDataVersion = self.protocol_version,
                MaximumGiftDataVersion = self.protocol_version
            },
            dummy = true -- This is only to be recognized as an object, not a list
        }}, {"pop", "dummy"}})

        local giftbox_name = "GiftBox;" .. self.ap:get_team_number() .. ";" .. player_number
        self.ap:Get({giftbox_name}, {
            id = self.id,
            action = "initialize_giftbox"
        })
    end,

    initialize_ap_giftbox = function(self, map)
        local giftbox_name = "GiftBox;" .. self.ap:get_team_number() .. ";" .. self.ap:get_player_number()
        local giftbox = map[giftbox_name]
        if type(giftbox) ~= "table" then
            self.is_open = false -- Something weird is happening and I won't touch it
        else
            if giftbox == nil then
                self.ap:Set(giftbox_name, {}, {
                    giftbox_gathering = self.ap:get_player_number()
                })
            end
            self.ap:SetNotify({giftbox_name})
            self.is_open = true
        end
    end,

    close_ap_giftbox = function(self, motherbox)
        self.is_open = false

        if not self:check_giftbox_info(motherbox) then -- just in case to be extra safe
            return
        end

        self.ap:Set("GiftBoxes;" .. self.ap:get_team_number(), {}, true, {{"update", {
            [self.ap:get_player_number()] = {
                IsOpen = false,
                AcceptsAnyGift = false,
                DesiredTraits = self.ap.EMPTY_ARRAY,
                MinimumGiftDataVersion = self.protocol_version,
                MaximumGiftDataVersion = self.protocol_version
            },
            dummy = true -- This is only to be recognized as an object, not a list
        }}, {"pop", "dummy"}})
    end,

    -- ap function overrides

    on_retrieved = function(self, map, keys, extra_data)
        if extra_data.id == self.id then
            if extra_data.action == "check_gift" then
                self:check_gift(map, extra_data)
            elseif extra_data.action == "open_giftbox" then
                self:open_ap_giftbox(map, extra_data)
            elseif extra_data.action == "initialize_giftbox" then
                self:initialize_ap_giftbox(map)
            elseif extra_data.action == "close_giftbox" then
                self:close_ap_giftbox(map)
            end
        elseif self.mod_on_retrieved ~= nil then
            self.mod_on_retrieved(map, keys, extra_data)
        end
    end,

    set_retrieved_handler = function(self, func)
        self.mod_on_retrieved = func
    end,

    on_set_reply = function(self, message)
        local giftbox_name = "GiftBox;" .. self.ap:get_team_number() .. ";" .. self.ap:get_player_number()
        if message.key == giftbox_name then
            if message.giftbox_gathering == self.ap:get_player_number() then
                for _, gift in pairs(message.original_value) do
                    if (self.gift_handler == nil or not self.gift_handler(gift)) and not gift.IsRefund then
                        gift.IsRefund = true
                        self:send_gift(gift)
                    end
                end
            else
                if self.gift_notification_handler ~= nil then
                    self.gift_notification_handler()
                end
            end
        elseif self.mod_set_reply ~= nil then
            self.mod_set_reply(message)
        end
    end,

    set_set_reply_handler = function(self, func)
        self.mod_set_reply = func
    end,

    -- initialization

    init = function(self, ap)
        self.ap = ap
        self.id = self:generate_GUID("")
        self.is_open = false

        ap:set_retrieved_handler(function(map, keys, extra_data)
            self:on_retrieved(map, keys, extra_data)
        end)
        ap.set_retrieved_handler = self.set_retrieved_handler

        ap:set_set_reply_handler(function(message)
            self:on_set_reply(message)
        end)
        ap.set_set_reply_handler = self.set_set_reply_handler
    end
}
