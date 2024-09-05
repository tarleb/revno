local revno  = require 'revno'
local pandoc = require 'pandoc'

describe('module revno', function ()
  it('has a function `tolazy`', function ()
    assert.is_function(revno.tolazy)
  end)

  describe('tostrict', function ()
    it('is a function', function ()
      assert.is_function(revno.tostrict)
    end)

    it('converts an Inline value to a Lua table', function ()
      local inline = pandoc.Str("Test")
      local result = revno.tostrict(inline)
      assert.is_table(result)
    end)

    it('carries over the tag', function ()
      local inline = pandoc.Str("Test")
      local result = revno.tostrict(inline)
      assert.equals(inline.tag, result.tag)
    end)

    it('carries over the `text` property of a Str element', function ()
      local inline = pandoc.Str("Test")
      local result = revno.tostrict(inline)
      assert.same(inline.text, result.text)
    end)

    it('creates an object with the same metatable name', function ()
      local inline = pandoc.Emph('hi')
      local result = revno.tostrict(inline)
      assert.equals(pandoc.utils.type(inline), pandoc.utils.type(result))
    end)
  end)
end)
