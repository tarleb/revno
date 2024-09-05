local revno = require 'revno'

describe('module revno', function ()
  it('has a function `tostrict`', function ()
    assert.is_function(revno.tostrict)
  end)
  it('has a function `tolazy`', function ()
    assert.is_function(revno.tolazy)
  end)
end)
