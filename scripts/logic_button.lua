local LNET = require('qLogicWires:logic_network')
local block_systems = require('qLogicWires:block_systems')

function on_broken(x, y, z, playerid)
    LNET.remove_net_block(x, y, z)
end

function on_interact(x, y, z, playerid)
    local get_state, set_state = block_systems.get_two_states_system(x, y, z, 'qLogicWires:logic_button', 'qLogicWires:logic_button_on')
    local new_state = not get_state()
    set_state(new_state)
    LNET.set_output_state(x, y, z, new_state)
    return true
end

LNET.add_logic_element({
    'qLogicWires:logic_button',
    'qLogicWires:logic_button_on'
}, false, true)