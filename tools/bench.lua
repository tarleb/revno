local revno  = require 'revno'
local pandoc = require 'pandoc'

local function measure(fn, name)
  name = name or 'unknown operation'
  local starttime, stoptime
  starttime = os.clock()
  local result = fn()
  stoptime = os.clock()
  print('Runtime', name, string.format("%f", stoptime - starttime) )
  return result
end

function Pandoc (doc)
  local orig = doc:clone()
  local sdoc = measure(
    function () return revno.tostrict(doc) end,
    'revno.tostrict'
  )
  local ldoc = measure(
    function () return revno.tolazy(sdoc) end,
    'revno.tolazy'
  )

  -- Quick sanity check
  assert(orig == ldoc, "the document did not roundtrip correctly")

  -- Return an empty doc
  return pandoc.Pandoc{}
end
