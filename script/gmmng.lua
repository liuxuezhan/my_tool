module("gmmng")

function get_parm(self, idx)
    if idx < 1 or tb[idx+1] == nil then
        return 0
    end
    return tonumber(tb[idx+1])
end

function do_public_gm(self, tb)
    local cmd = tb[1] 
    if cmd == "example" then
        local pid = self:get_parm(1)
        local exp = self:get_parm(2)
        local player = getPlayer(pid)
        player:add_exp(exp)
    end
end





