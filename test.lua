describe("valid", function()
    local valid = require "valid"
    describe("when passed with a function", function()
        it("should pass on the result even if failing", function()
            local f = valid(function(val)
                return {"error"}, false
            end)

            local r = f:explain(2)
            assert.is_not_nil(r.result)
            assert.are.same({"error"}, r.errors)
        end)

        it("shouldn't pass on the result if told not to", function()
            local f = valid(function(val)
                return {"error"}, true
            end)
            
            local r = f:explain(2)
            assert.is_nil(r.result)
            assert.are.same({"error"}, r.errors)
        end)
    end)
end)