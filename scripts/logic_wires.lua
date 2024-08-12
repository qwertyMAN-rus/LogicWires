local LNET = require('qLogicWires:logic_network')
local neighbors = LNET.neighbors
local is_logic_element = LNET.is_logic_element

local wire_models = {
    [-2] = 'qLogicWires:logic_wire',
    [0] = 'qLogicWires:logic_wire_empty',
    [1] = 'qLogicWires:logic_wire_one_side',
    [2] = 'qLogicWires:logic_wire_two_side',
    [3] = 'qLogicWires:logic_wire_three_side',
    [4] = 'qLogicWires:logic_wire_four_side',
}

local function btonumber(value)
    return value and 1 or 0
end

local function get_model_by_sides(sides)
    local name = wire_models[sides]
    local id = block.index(name)
    return id, name
end

local function get_number_of_neighbors(x, y, z)
    local sides = {}
    local n = 0
    for _, coords in ipairs(neighbors) do
        local x = x + coords[1]
        local y = y + coords[2]
        local z = z + coords[3]
        local id = block.get(x, y, z)
        local name = block.name(id)
        local isElement = is_logic_element(name)
        table.insert(sides, isElement)
        if isElement then
            n = n + 1
        end
    end
    return n, sides
end

local function get_two_sides_angle(sides)
    local old_value
    local output = 1
    for index, value in ipairs(sides) do
        if old_value == false and value == true then
            output = index
            break
        end
        old_value = value
    end
    return output % 4
end

local function update_model(x, y, z)
    local neighbors, sides = get_number_of_neighbors(x, y, z)
    local old_id = block.get(x, y, z)
    local old_rotation = block.get_states(x, y, z)
    local id = get_model_by_sides(neighbors)
    
    local rotation = 0
    if neighbors == 1 then
        rotation = btonumber(sides[1]) + btonumber(sides[2])*2 + btonumber(sides[3])*3
    elseif neighbors == 3 then
        rotation = btonumber(not sides[4]) + btonumber(not sides[1])*2 + btonumber(not sides[2])*3
    elseif neighbors == 2 then
        if sides[1] == sides[3] then
            id = get_model_by_sides(-2)
            if sides[1] then
                rotation = 1
            end
        else
            rotation = get_two_sides_angle(sides)
        end
    end
    if id ~= old_id or rotation ~= old_rotation then
        block.set(x, y, z, id, rotation)
    end
end

function on_broken(x, y, z, playerid)
    LNET.remove_net_block(x, y, z)
end

function on_placed(x, y, z, playerid)
    update_model(x, y, z)
end

function on_update(x, y, z)
    update_model(x, y, z)
end

LNET.add_logic_element({
    'qLogicWires:logic_wire',
    'qLogicWires:logic_wire_empty',
    'qLogicWires:logic_wire_one_side',
    'qLogicWires:logic_wire_two_side',
    'qLogicWires:logic_wire_three_side',
    'qLogicWires:logic_wire_four_side'
}, true)