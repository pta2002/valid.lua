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

    describe("when passed with a string", function()
        it("should return a valid filter", function()
            local f = valid("len<3")

            assert.is_nil(f("abc"))
            assert.is_not_nil(f("ab"))
        end)
        
        it("should support multiple filters", function()
            local f = valid("type=string|len<3")

            assert.is_nil(f(2))
            assert.is_nil(f("abc"))
            assert.is_not_nil(f("ab"))
        end)

        it("should support negative numbers", function()
            local f = valid("type=number|val>-3")

            assert.is_not_nil(f(-2))
            assert.is_nil(f(-3))
        end)
    end)
end)

describe("valid.tokens", function()
    local tokens = require("valid").tokens
    it("should return if it's just a flag", function()
        local f, o, v = tokens("abc") 
        assert.equal(f, "abc")
        assert.is_nil(o)
        assert.is_nil(v)
    end)

    it("should return the split tokens", function()
        local f, o, v = tokens("abc<3")
        assert.equal(f, "abc")
        assert.equal(o, "<")
        assert.equal(v, "3")

        local f, o, v = tokens("abc<=3")
        assert.equal(f, "abc")
        assert.equal(o, "<=")
        assert.equal(v, "3")
    end)
end)

describe("valid.makefunction", function()
    it("should return a filter function", function()
        local f = require("valid").makefunction("len<3")
        assert.False(f("abc"))
        assert.True(f("ab"))
    end)
end)