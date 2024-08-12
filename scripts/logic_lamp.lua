local LNET = require('qLogicWires:logic_network')
local block_systems = require('qLogicWires:block_systems')

function on_broken(x, y, z, playerid)
    LNET.remove_net_block(x, y, z)
end

local function update_state(x, y, z, new_state)
    local get_state, set_state = block_systems.get_two_states_system(x, y, z, 'qLogicWires:logic_lamp', 'qLogicWires:logic_lamp_on')
    set_state(new_state)
end

LNET.add_logic_element({
    'qLogicWires:logic_lamp',
    'qLogicWires:logic_lamp_on'
}, false, false, true, update_state)