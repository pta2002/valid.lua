--
-- valid.lua 0.2
--
-- Copyright (c) 2019, pta2002
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
local valid = {version="0.2"}

valid.ops = {
    ["<="] = function(a,b) return type(a) == "number" and type(b) == "number" and a <= b end,
    [">="] = function (a,b) return type(a) == "number" and type(b) == "number" and a >= b end,
    ["<"]= function (a,b) return type(a) == "number" and type(b) == "number" and a < b end,
    [">"]= function (a,b) return type(a) == "number" and type(b) == "number" and a > b end,
    ["="]= function (a,b) return type(a) == type(b) and a == b end,
    ["~="] = function (a,b) return type(a) == type(b) and a ~= b end
}

valid.filters = {
    len = function (v) 
        if type(v) ~= "number" then
            return #v
        else 
            return -1
        end
    end,
    val = function (v) return v end,
    type = function (v) return type(v) end
}

setmetatable(valid, {
    __call = function(self, t)
        local filter = {}
        local filterfunc

        filterfunc = valid.genfilter(t)
        
        function filter:explain(v)
            local e, n = filterfunc(v)
            if n then return {result=nil, errors=e} end
            return {result=v, errors=e}
        end

        setmetatable(filter, {
            __call=function(self,v)
                return self:explain(v).result
            end
        })
        return filter
    end
})

valid.genfilter = function(v)
    local filters = {}
    local flags = {}

    if type(v) == "function" then
        return v
    elseif type(v) == "string" then
        local f = {}
        -- TODO this needs to handle pipes inside of quotes for patterns
        for substr in (v.."|"):gmatch("([^|]*)|") do
            if substr ~= nil and substr:len() > 0 then
                table.insert(f, substr)
            end
        end

        -- parse filters
        for i,_filter in ipairs(f) do
            filters[_filter] = valid.makefunction(_filter)
        end

        return function(v)
            local errors = {}
            local fail = false

            for name, filter in pairs(filters) do
                if not filter(v) then
                    table.insert(errors, "Failed: " .. name)
                    fail = true
                end
            end

            return errors, fail
        end
    elseif type(v) == "table" then
        if #v == 1 and type(v[1]) ~= nil then
            local listfilter = valid.genfilter(v[1])
            if listfilter then
                return function(v)
                    if type(v) ~= "table" then return {"value has to be a table"}, true end
                    local errors = {}
                    local fail = false
                    for i,item in ipairs(v) do
                        local ferrors, ffail = listfilter(item)
                        for _,error in ipairs(ferrors) do
                            table.insert(errors, tostring(item) .. ": " .. error)
                        end

                        if ffail then fail = true end
                    end

                    return errors, fail
                end
            end
        end

        for k,filter in pairs(v) do
            filters[k] = valid.genfilter(filter)
        end

        return function(v)
            local errors = {}
            local fail = false

            for k,filter in pairs(filters) do
                if v[k] == nil then
                    table.insert(errors, k .. " is required")
                    fail = true
                else
                    local ferrors, ffail = filter(v[k])
                    for _,error in ipairs(ferrors) do
                        table.insert(errors, error)
                    end

                    if ffail then
                        fail = true
                    end
                end
            end

            return errors, fail
        end
    end
end

valid.makefunction = function(_filter)
    local filter, op, value = valid.tokens(_filter)
    if op == nil then
        --table.insert(flags, filter)
    elseif valid.ops[op] ~= nil and valid.filters[filter] ~= nil then
        if string.match(value, "%-?%d+") == value and filter ~= "chars" then
            value = tonumber(value)
        end

        return function(v)
            return valid.ops[op](valid.filters[filter](v), value)
        end
    end
end

valid.tokens = function(filter)
    local f = filter:match("[^=<>]+")
    if f == filter then return f end
    local op = filter:match("[<>]?=?", f:len()+1)
    local value = filter:sub(f:len()+op:len()+1)
    return f, op, value
end

return valid