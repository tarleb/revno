local revno = require 'revno'

describe('module revno', function ()
  it('has a function `tostrict`', function ()
    assert.is_function(revno.tostrict)
  end)
end)
