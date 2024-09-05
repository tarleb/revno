--- revno.lua – eager conversion of pandoc AST elements to Lua tables.
---
--- Copyright: © 2024 Albert Krewinkel
--- License: MIT – see LICENSE for details

local pandoc = require 'pandoc'

-- Debugging functions
local registry           = debug.getregistry()
local debug_getmetatable = debug.getmetatable
local debug_setuservalue = debug.setuservalue

--- Get the element type; like pandoc.utils.type, but faster.
local function get_metatable_name (x)
  local mt = debug_getmetatable(x)
  return mt and mt.__name
end

--- Return the tag (e.g., `Str`) or type (e.g. `Meta`) of an element.
local function tag_or_type (x)
  return x.tag or get_metatable_name(x) or type(x)
end

local lazy_th = pandoc.TableHead({})
local lazy_tf = pandoc.TableFoot({})
local lazy_userdata = {
  BlockQuote     = pandoc.BlockQuote{},
  BulletList     = pandoc.BulletList{},
  Cite           = pandoc.Cite({}, {}),
  Code           = pandoc.Code(""),
  CodeBlock      = pandoc.CodeBlock(""),
  DefinitionList = pandoc.DefinitionList{},
  Div            = pandoc.Div{},
  Emph           = pandoc.Emph{},
  Header         = pandoc.Header(0, {}),
  HorizontalRule = pandoc.HorizontalRule(),
  Image          = pandoc.Image({}, ''),
  LineBlock      = pandoc.LineBlock{},
  LineBreak      = pandoc.LineBreak(),
  Link           = pandoc.Link({}, ''),
  Math           = pandoc.Math("DisplayMath", ""),
  Note           = pandoc.Note{},
  OrderedList    = pandoc.OrderedList{},
  Pandoc         = pandoc.Pandoc{},
  Para           = pandoc.Para{},
  Plain          = pandoc.Plain{},
  Quoted         = pandoc.Quoted('SingleQuote', {}),
  RawBlock       = pandoc.RawBlock("placeholder", ""),
  RawInline      = pandoc.RawInline("placeholder", ""),
  SmallCaps      = pandoc.SmallCaps{},
  SoftBreak      = pandoc.SoftBreak(),
  Space          = pandoc.Space(),
  Span           = pandoc.Span{},
  Str            = pandoc.Str "",
  Strikeout      = pandoc.Strikeout{},
  Strong         = pandoc.Strong{},
  Subscript      = pandoc.Subscript{},
  Superscript    = pandoc.Superscript{},
  Table          = pandoc.Table({}, {}, lazy_th, {}, lazy_tf),
  TableHead      = lazy_th,
  TableFoot      = lazy_tf,
  Underline      = pandoc.Underline{},
}

--- Make a strict element lazy (if possible).
local function tolazy (element)
  local tp = type(element)
  if tp ~= 'table' or not element.strict then
    -- already lazy
    return element
  end
  local name = tag_or_type(element)
  local ud = name and lazy_userdata[name]
  if ud then
    local new = {}
    for key, value in pairs(element) do
      new[key] = tolazy(value)
    end
    debug_setuservalue(ud, new, 1)
    local lazy = ud:clone()
    print("Lazy type", tag_or_type(lazy))
    return lazy
  elseif type(element) == 'table' then
    print("no userdata for ", tag_or_type(element))
    local new = {}
    for key, value in pairs(element) do
      new[key] = tolazy(value)
    end
    return setmetatable(new, debug_getmetatable(element))
  else
    -- don't know what to do, let's just return it unchanged
    return element
  end
end

local metamethods = {
  __tojson = true,
  __eq = true,
  __tostring = true,
}

local function make_metatable (name)
  local orig =
    assert(registry[name], "No such metatable in the registry: " .. name)
  local new = {__name = name}
  for key, value in pairs(orig) do
    new[key] = metamethods[key] and
      function(obj, ...)
        print('hello from', key)
        return value(tolazy(obj), ...)
      end
  end
  for methodname, fn in pairs(orig.methods or {}) do
    new[methodname] = function(obj, ...)
      print('hello from', methodname)
      return fn(tolazy(obj), ...)
    end
  end
  new.__name = name -- .. ' (strict)'
  new.__index = new
  new.strict = true
  return new
end

local strict_metatables = {}
local function get_new_metatable (element)
  local name = get_metatable_name(element)
  local mt = name and strict_metatables[name]
  if name and not mt then
    mt = make_metatable(name)
    strict_metatables[name] = mt
  end
  return mt
end

local function tostrict (element)
  local tp = type(element)
  if (tp ~= 'table' and tp ~= 'userdata') or element.strict then
    return element
  end
  local new = {}
  for key, value in pairs(element) do
    -- ignore methods
    if type(value) ~= 'function' then
      new[key] = tostrict(value)
    end
  end
  local mt = get_new_metatable(element)
  return setmetatable(new, mt)
end

local M = {
  tostrict = tostrict,
  tolazy = tolazy,
}

return M
