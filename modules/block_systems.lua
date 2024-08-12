local block_systems = {}

function block_systems.get_two_states_system(x, y, z, state_off, state_on)
    local INDEX_STATE_ON = block.index(state_on)
    local INDEX_STATE_OFF = block.index(state_off)
    local function get_state()
        local currentID = block.get(x, y, z)
        return currentID == INDEX_STATE_ON
    end
    local function set_state(new_state)
        local newID = new_state and INDEX_STATE_ON or INDEX_STATE_OFF
        local currentStates = block.get_states(x, y, z)
        block.set(x, y, z, newID, currentStates)
    end
    return get_state, set_state
end

return block_systems