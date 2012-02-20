module "parsing stuffs"

test "where's my var defs at, part 1", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var tuna")
  equal @monkey.displayValue().trim(), "tuna = undefined"

test "where's my var defs at, part 2", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var tuna = 3")
  equal @monkey.displayValue().trim(), "tuna = 3"

###
test "where's my var defs at, part 3", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var var")
  equal @monkey.displayValue().trim(), ""

test "where's my var defs at, part 4", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var")
  equal @monkey.displayValue().trim(), ""
###

test "where's my var defs at, part 5", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var tuna;\nvar fish;")
  equal @monkey.displayValue().trim(), "tuna = undefined\nfish = undefined"

test "where's my var defs at, part 6", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var tuna = 3; var fish;")
  equal @monkey.displayValue().trim(), "tuna = 3 ; fish = undefined"

test "where's my var defs at, part 7", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var tuna, fish = 3;")
  equal @monkey.displayValue().trim(), "tuna = undefined ; fish = 3"

test "where's my var defs at, part 8", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var array = [1,3,4]; \nvar count = array.length")
  equal @monkey.displayValue().trim(), "array = [1, 3, 4]\ncount = 3"

test "where's my var defs at, part 9", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var a; \nvar i = 3;\na = 2 + i;")
  equal @monkey.displayValue().trim(), "a = undefined\ni = 3\na = 5"

test "where's my var defs at, part 10", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var a; \nvar i = 3;\na = i++;")
  equal @monkey.displayValue().trim(), "a = undefined\ni = 3\na = 3"

test "for ALL the things, part 1", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("for (var i = 0; i < 3; i++ ) { \n}")
  equal @monkey.displayValue().trim(), "i = 0 | 1 | 2"

test "for ALL the things, part 2", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var i = 0; \nfor (; i < 3; i++ ) { \n}")
  equal @monkey.displayValue().trim(), "i = 0\ni = 0 | 1 | 2"

test "for ALL the things, part 3", ->
  @monkey = new SourceCodeParser
  longCodeString = "var array = [1,3,'4']; \n"
  longCodeString += "for (var i = 0, count = array.length; i < count; i++) { \n}"
  @monkey.parseThemSourceCodes(longCodeString)
  equal @monkey.displayValue().trim(), "array = [1, 3, '4']\ni = 0 | 1 | 2 ; count = 3 | 3 | 3"

test "while ALL the things, part 1", ->
  @monkey = new SourceCodeParser
  longCodeString = "var i = 0;\n"
  longCodeString += "while (i < 3){ \n"
  longCodeString += "i++; \n }"
  @monkey.parseThemSourceCodes(longCodeString)
  longResult = "i = 0\ni = 0 | 1 | 2\ni = 1 | 2 | 3"
  equal @monkey.displayValue().trim(), longResult

test "function definitions part 1", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("function binarySearch(key, array){}")
  equal @monkey.displayValue().trim(), "key = undefined ; array = undefined"

test "function definitions part 2", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("function binarySearch(){}")
  equal @monkey.displayValue().trim(), ""

test "var function definitions part 1", ->
  @monkey = new SourceCodeParser
  @monkey.parseThemSourceCodes("var f = function f(x, y) { }")
  equal @monkey.displayValue().trim(), "x = undefined ; y = undefined ; f = function f(x, y) { }"
