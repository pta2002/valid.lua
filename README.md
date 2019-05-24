# valid.lua
A simple validation library for lua

## Usage
```lua
local valid = require "valid"
print(valid.version)
-- 0.2

-- Supports any standard type
-- Numbers
filter = valid("type=number|val<=2")
filter(2)
-- 2
filter(3)
-- nil

-- It can also return a list of failed conditions
filter:explain(3)
-- {result=nil, errors={"Failed: val<=2"}}
filter:explain(2)
-- {result=2, errors={}}

-- Tables
filter = valid({
    -- Required fields, whole filter will fail if one of them is nil
    username="type=string|len>4|len<16",
    password="type=string|len>8",
    -- Nesting!
    posts={
        title="type=string|len<50",
        body="type=string",
    }
})
filter:explain({
    username="abcde",
    posts={}
})
-- {result=nil, errors={"password is required", "title is required", "body is required"}}

-- Lists
filter = valid({"type=number|val<3"})
filter:explain({1,2,3,4})
-- {result=nil. errors={"3: Failed: val<3", "4: Failed: val<3"}}

-- You can also specify a function to act as a validator instead of a stirng if
-- you wish for more flexibility
filter = valid(function (val)
    local errs = {}
    if type(val) ~= "string" then table.insert(errs, "value has to be a string") end
    -- Second return value is whether to return nil or not
    return errs, false
end)
filter:explain(2)
-- {result=2, errors={"value has to be a string"}}
```

# LICENSE
This library is MIT licensed. This means you can essentially use it however you
want. See `LICENSE` for more details.