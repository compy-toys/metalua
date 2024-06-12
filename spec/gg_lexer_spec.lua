local describe = require("busted").describe
local assert = require("busted").assert
local it = require("busted").it
local pp = require("metalua.pprint").print
local M = require("metalua.grammar.lexer")

describe("lexer", function()
   local lexer = M.lexer
   describe("newstream", function()
      it("should return a new lexer stream", function()
         assert(lexer:newstream("a"))
      end)
      it("should initialize with sym and alpha fields", function()
         assert.same({}, lexer:newstream("a").sym)
         assert.same({}, lexer:newstream("a").alpha)
      end)
   end)
   describe("add", function()
      local lx = lexer:newstream("try 123 catch 456")
      it("should add a new keyword recongized by the lexer stream", function()
         lx:add({ "catch", "try" })
         assert.same(true, lx.alpha["catch"])
         assert.same(true, lx.alpha["try"])
      end)
      it("should add a new symbol recongized by the lexer stream", function()
         lx:add({ "->", "|>" })
         assert.same({ "->" }, lx.sym["-"])
         assert.same({ "|>" }, lx.sym["|"])
      end)
   end)
   describe("extract", function()
      it("should extact next token and forward the index", function()
         local lx = lexer:newstream("return 123")
         assert.same("return", lx:extract()[1])
         assert.same("Number", lx:extract().tag)
      end)
   end)
   describe("peek", function()
      it("should extact next token without forwarding the index", function()
         local lx = lexer:newstream("return 123")
         assert.same("return", lx:peek()[1])
         assert.same("Number", lx:peek(2).tag)
      end)
   end)
   describe("next", function()
      it("should extact next token without forwarding the index", function()
         local lx = lexer:newstream("return 123")
         assert.same("return", lx:next()[1])
         assert.same("Number", lx:next().tag)
         assert.same("Eof", lx:next().tag)
      end)
   end)
   describe("save & restore", function()
      it("should save the index and peeked and restore", function()
         local lx = lexer:newstream("return 123")
         local saved_state = lx:save()
         assert.same("return", lx:next()[1])
         assert.same(123, lx:peek()[1])
         assert.same("Number", lx:next().tag)
         assert.same("Eof", lx:next().tag)
         lx:restore(saved_state)
         assert.same(1, lx.i)
         assert.same({}, lx.peeked)
      end)
   end)
   describe("sync", function()
      it("Resynchronize: cancel any token in self.peeked, by emptying the list and resetting the indexes", function()
         local lx = lexer:newstream("  return 123")
         assert.same(1, lx.i)
         assert.same(nil, lx.column_offset)
         assert.same(3, lx:next().lineinfo.first.offset)
         local peek1 = lx:peek()
         local peek2 = lx:peek(2)
         assert.same({ peek1, peek2 }, lx.peeked)
         lx:sync()
         assert.same({}, lx.peeked)
         assert.same(10, lx.i) -- move to the begging of 123
      end)
   end)
   describe("kill", function() end)
   describe("clone", function() end)
   describe("takeover", function() end)
   describe("check", function() end)
   describe("is_keyword", function() end)
   describe("lineinfo_left", function() end)
   describe("lineinfo_right", function() end)
end)

describe("position", function()
   it("should return a new position", function()
      assert(M.new_position(1, 1, 1, "hello"))
      local pos = M.new_position(1, 1, 1, "hello")
      assert.same(1, pos.line)
      assert.same(1, pos.column)
      assert.same(1, pos.offset)
      assert.same("hello", pos.source)
   end)
   it("should print the string representation of position", function()
      local pos = M.new_position(1, 1, 1, "hello")
      assert.same("<hello|L1|C1|K1>", tostring(pos))
   end)
end)

describe("position_factory", function()
   local posfact = M.new_position_factory("hello world\n metalua is coollll", "hello.lua")
   it("should return a new position_factory", function()
      assert.same("hello.lua", posfact.src_name)
      assert.same({ 1, 13, 33 }, posfact.line2offset)
      assert.same(32, posfact.max)
   end)
   it("get the position of a given offset", function()
      local pos1 = posfact:get_position(14)
      assert.same("<hello.lua|L2|C2|K14>", tostring(pos1))
      local pos2 = posfact:get_position(2)
      assert.same("<hello.lua|L1|C2|K2>", tostring(pos2))
   end)
end)

describe("lineinfo", function()
   local posfact = M.new_position_factory("--preffix \nhello world\n metalua is coollll--suffix comments", "hello.lua")
   local pos1 = posfact:get_position(11)
   local pos2 = posfact:get_position(1)
   local lineinfo = M.new_lineinfo(pos1, pos2)
   it("represent a node's range in a source file", function()
      assert.same(pos1, lineinfo.first)
      assert.same(pos2, lineinfo.last)
   end)
   it("should print the string representation of position", function()
      assert.same("<hello.lua|L1|C11-1|K11-1>", tostring(lineinfo))
   end)
   -- TODO:
   it("embed information about prefix and suffix comments", function() end)
end)

describe("token", function()
   local posfact = M.new_position_factory("--preffix \nhello world\n metalua is coollll--suffix comments", "hello.lua")
   local pos1 = posfact:get_position(11)
   local pos2 = posfact:get_position(1)
   local lineinfo = M.new_lineinfo(pos1, pos2)
   local token = M.new_token("Op", "add", lineinfo)
   it("should return a new token", function()
      assert.same("Op", token.tag)
      assert.same("add", token[1])
   end)
   it("should print the string representation of position", function()
      assert.same('`Op "add"', tostring(token))
   end)
end)

describe("comments", function()
   local lineinfo = M.new_lineinfo(M.new_position(1, 1, 1, "hello"), M.new_position(1, 7, 7, "hello"))

   local token = M.new_token("Comment", "--hello", lineinfo)
   local comment = M.new_comment({ token })
   it("is a series of comment blocks with associated lineinfo", function()
      assert.same(lineinfo, comment.lineinfo)
   end)
   it("shoud return the text of the comment, as a string.", function()
      assert.same("--hello", comment:text())
   end)
   -- TODO:
   it("should parse multiline comments", function() end)

   it("new_comment_line", function() end)
end)
