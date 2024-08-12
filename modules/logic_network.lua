local LNET = {}

local logic_nets = {}   -- Список обнаруженных/сгенерированных сетей
local net_blocks = {} -- таблица какая сеть принадлежит блоку по координатам [x][y][z]
local output_funcs = {} -- таблица функций включения/отключения для output блоков по их id

local neighbors = {
    { -1,  0,  0},
    { 0,  0,  1},
    { 1,  0,  0},
    { 0,  0, -1},
}

local wires = {}
local inputs = {}
local outputs = {}

local LogicNet = {}
local NetBlock = {}

local function is_wire(name)
    return wires[name] or false
end

local function is_input_element(name)
    return inputs[name] or false
end

local function is_output_element(name)
    return outputs[name] or false
end
local function is_logic_element(name)
    return is_wire(name) or is_input_element(name) or is_output_element(name)
end

local function check_block(x, y, z)
    return net_blocks[x] and net_blocks[x][y] and net_blocks[x][y][z]
end

function get_coords_string(x, y, z)
    return 'x: ' .. tostring(x) .. ' y: ' .. tostring(y) .. ' z: ' .. tostring(z)
end

local function printNet()
    print()
    local line = string.rep('=', 30)
    local line2 = string.rep('-', 30)
    print(line)
    print('Сетей ' .. #logic_nets)
    print(line)
    for i, net in ipairs(logic_nets) do
        print('Проводов : ' .. #net.wires)
        print('Входов : ' .. #net.input_blocks)
        print('Выходов : ' .. #net.output_blocks)
        for j, net_block in ipairs(net.wires) do
            local x, y, z = net_block.x, net_block.y, net_block.z
            local id = block.get(x, y, z)
            print('Сеть: ' .. i .. get_coords_string(x, y, z) .. ' провод: ' .. block.name(id))
        end
        for j, net_block in ipairs(net.input_blocks) do
            local x, y, z = net_block.x, net_block.y, net_block.z
            local id = block.get(x, y, z)
            print('Сеть: ' .. i .. get_coords_string(x, y, z) .. ' вход: ' .. block.name(id))
        end
        for j, net_block in ipairs(net.output_blocks) do
            local x, y, z = net_block.x, net_block.y, net_block.z
            local id = block.get(x, y, z)
            print('Сеть: ' .. i .. get_coords_string(x, y, z) .. ' выход: ' .. block.name(id))
        end
    end
    print(line)
    local text = ''
    local count = 0
    for x, _ in pairs(net_blocks) do
        for y, _ in pairs(net_blocks[x]) do
            for z, value in pairs(net_blocks[x][y]) do
                text = text .. get_coords_string(x, y, z) .. ' value: ' .. tostring(value) .. '\n'
                count = count + 1
            end
        end
    end
    print('Блоки сети ' .. count)
    print(line)
    print(text)
    print(line)
    print()
end




function LogicNet.new()
    local self = setmetatable({}, {__index = LogicNet})
    self.wires = {}
    self.input_blocks = {}
    self.output_blocks = {}
    table.insert(logic_nets, self)
    self.state = wires[1] and wires[1].output_state or false
    return self
end

function LogicNet:remove()
    for i, net in ipairs(logic_nets) do
        if net == self then
            table.remove(logic_nets, i)
            return
        end
    end    
end

function LogicNet:union(other_net)
    for _, wire in ipairs(other_net.wires) do
        table.insert(self.wires, wire)
    end
    for _, input_block in ipairs(other_net.input_blocks) do
        table.insert(self.input_blocks, input_block)
    end
    for _, output_block in ipairs(other_net.output_blocks) do
        table.insert(self.output_blocks, output_block)
    end
    other_net:remove()
end

function LogicNet:add_net_block(net_block)
    if net_block.is_wire then
        table.insert(self.wires, net_block)
    end
    if net_block.is_input then
        table.insert(self.input_blocks, net_block)
        local new_block = false
        for _, net in ipairs(net_block.input_nets) do
            if net == self then
                new_block = true
            end
        end
        if new_block then
            table.insert(net_block.output_nets, net_block)
        end
    end
    if net_block.is_output then
        table.insert(self.output_blocks, net_block)
        local new_block = false
        for _, net in ipairs(net_block.input_nets) do
            if net == self then
                new_block = true
            end
        end
        if new_block then
            table.insert(net_block.input_nets, net_block)
        end
    end
end

function LogicNet:remove_block(net_block)
    if net_block.is_wire then
        for i, block in ipairs(self.wires) do
            if block == net_block then
                table.remove(self.wires, i)
                break
            end
        end
    end
    if net_block.is_input then
        for i, block in ipairs(self.input_blocks) do
            if block == net_block then
                table.remove(self.input_blocks, i)
                break
            end
        end
    end
    if net_block.is_output then
        for i, block in ipairs(self.output_blocks) do
            if block == net_block then
                table.remove(self.output_blocks, i)
                break
            end
        end
    end
    if #self.wires == 0 and #self.input_blocks == 0 and #self.output_blocks == 0 then
        self:remove()
    end
end

function LogicNet:set_state(new_state)
    if self.state == new_state then
        return
    end
    self.state = new_state
    for _, block in ipairs(self.output_blocks) do
        block:set_state(new_state)
    end
end

function LogicNet.get_net(x, y, z, default_net)
    local net_block = NetBlock.get_block(x, y, z, default_net)
    if not net_block then
        return false
    end
    return net_block:get_net()
end





function NetBlock.new(x, y, z, default_net)
    local self = setmetatable({}, {__index = NetBlock})
    local id = block.get(x, y, z)
    local name = block.name(id)
    self.x = x
    self.y = y
    self.z = z
    self.is_wire = is_wire(name)
    self.is_input = is_input_element(name)
    self.is_output = is_output_element(name)
    self.output_state = false
    self.input_nets = {}
    self.output_nets = {}
    self.net = self.is_wire and (default_net or LogicNet.new())
    if self.net then
        self.net:add_net_block(self)
    end
    return self
end

function NetBlock:remove()
    self:set_state(false)
    local x, y, z = self.x, self.y, self.z
    for _, net in ipairs(self.input_nets) do
        net:remove_block(self)
    end
    for _, net in ipairs(self.output_nets) do
        net:remove_block(self)
    end
    if not net_blocks[x] or not net_blocks[x][y] or not net_blocks[x][y][z] then
        return
    end
    net_blocks[x][y][z] = nil
    if #net_blocks[x][y] == 0 then
        net_blocks[x][y] = nil
    end
    if #net_blocks[x] == 0 then
        net_blocks[x] = nil
    end
end

function NetBlock:add_net(net, is_output)
    local nets = is_output and self.output_nets or self.input_nets
    for _, logic_net in ipairs(nets) do
        if logic_net == net then
            return
        end
    end
    table.insert(nets, net)
end

function NetBlock:check_connect_block()
    if self.is_wire then
        for _, block in ipairs(self.net.wires) do
            if block == self then
                return true
            end
        end
    end
    if self.is_input then
        for _, block in ipairs(self.net.input_blocks) do
            if block == self then
                return true
            end
        end
    end
    if self.is_output then
        for _, block in ipairs(self.net.output_blocks) do
            if block == self then
                return true
            end
        end
    end
end

function NetBlock:scan_nets()
    for _, coords in ipairs(neighbors) do
        local x = self.x + coords[1]
        local y = self.y + coords[2]
        local z = self.z + coords[3]
        if check_block(x, y, z) and NetBlock:check_connect_block() then
            return
        end
        local id = block.get(x, y, z)
        local name = block.name(id)
        if is_logic_element(name) then
            if self.is_input then
                if is_wire(name) then
                    local net = LogicNet.get_net(x, y, z)
                    if net then
                        self:add_net(net, true)
                    end
                end
            elseif self.is_wire then
                if is_wire(name) then
                    local net = LogicNet.get_net(x, y, z, self.net)
                    -- if net then-- TODO дописать для разных сетей
                    --     self.net:union(net)
                    -- end
                else
                    local net_block = NetBlock.get_block(x, y, z)
                    if not net_block then
                        break
                    end
                    self.net:add_net_block(net_block)
                end
            end
        end
    end
end

function NetBlock:get_net()
    if self.is_wire then
        return self.net
    end
    return false
end

function NetBlock:set_state(new_state)
    if self.output_state == new_state then
        return
    end
    self.output_state = new_state
    self:scan_nets()
    if self.is_input then
        for _, net in ipairs(self.output_nets) do
            net:set_state(new_state)
        end
    elseif self.is_output then
        local x, y, z = self.x, self.y, self.z
        local id = block.get(x, y, z)
        local name = block.name(id)
        local func = output_funcs[name]
        if func then
            func(x, y, z, new_state)
        end
    end
end

function NetBlock.get_block(x, y, z, default_net, is_deleted)
    local id = block.get(x, y, z)
    local name = block.name(id)
    if not is_deleted and not is_logic_element(name) then
        return false
    end
    if not net_blocks[x] then net_blocks[x] = {} end
    if not net_blocks[x][y] then net_blocks[x][y] = {} end
    if not net_blocks[x][y][z] then
        net_blocks[x][y][z] = NetBlock.new(x, y, z, default_net)
        net_blocks[x][y][z]:scan_nets()
    end
    return net_blocks[x][y][z]
end





LNET.neighbors = neighbors
LNET.is_logic_element = is_logic_element

function LNET.remove_net_block(x, y, z)
    local net_block = NetBlock.get_block(x, y, z, nil, true)
    if not net_block then
        return
    end
    net_block:remove()
end

function LNET.set_output_state(x, y, z, new_state)-- TODO проверить другие источники сигнала. Использовать для удаления inputs. Вызывают только источники сигнала
    local net_block = NetBlock.get_block(x, y, z)
    if not net_block then
        return
    end
    net_block:set_state(new_state)
    printNet()
end

function LNET.add_logic_element(names, is_wire, is_input, is_output, update_state_func)
    for _, name in ipairs(names) do
        if is_wire then
            wires[name] = true
        end
        if is_input then
            inputs[name] = true
        end
        if is_output then
            outputs[name] = true
            output_funcs[name] = update_state_func
        end
    end
end

return LNET