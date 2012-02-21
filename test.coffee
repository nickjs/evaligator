module "parsing stuffs"

###########################################
#### syntax
###########################################

test "check invalid syntax 1", ->
  monkey = new SourceCodeParser
  entireSyntaxTree = Parser.Parser.parse "while(1)"
  allIsGood = monkey.isSyntaxTreeValid(entireSyntaxTree)
  equal allIsGood, false

test "check invalid syntax 2", ->
  monkey = new SourceCodeParser
  entireSyntaxTree = Parser.Parser.parse "while(i)"
  allIsGood = monkey.isSyntaxTreeValid(entireSyntaxTree)
  equal allIsGood, false

test "check invalid syntax 3", ->
  monkey = new SourceCodeParser
  entireSyntaxTree = Parser.Parser.parse "while(1);"
  allIsGood = monkey.isSyntaxTreeValid(entireSyntaxTree)
  equal allIsGood, true

test "check invalid syntax 4", ->
  monkey = new SourceCodeParser
  entireSyntaxTree = Parser.Parser.parse "for (i = 0; i < 5; )"
  allIsGood = monkey.isSyntaxTreeValid(entireSyntaxTree)
  equal allIsGood, false

test "check invalid syntax 5", ->
  monkey = new SourceCodeParser
  entireSyntaxTree = Parser.Parser.parse "for (var i = 0; i < 5; )"
  allIsGood = monkey.isSyntaxTreeValid(entireSyntaxTree)
  equal allIsGood, false

test "check invalid syntax 6", ->
  monkey = new SourceCodeParser
  entireSyntaxTree = Parser.Parser.parse "for (var i = 0; i < 5; i++)"
  allIsGood = monkey.isSyntaxTreeValid(entireSyntaxTree)
  equal allIsGood, false

test "check invalid syntax 7", ->
  monkey = new SourceCodeParser
  entireSyntaxTree = Parser.Parser.parse "for (var i = 0; i < 5; i++);"
  allIsGood = monkey.isSyntaxTreeValid(entireSyntaxTree)
  equal allIsGood, true

test "check invalid syntax 8", ->
  monkey = new SourceCodeParser
  entireSyntaxTree = Parser.Parser.parse "var var"
  allIsGood = monkey.isSyntaxTreeValid(entireSyntaxTree)
  equal allIsGood, false

test "check invalid syntax 9", ->
  monkey = new SourceCodeParser
  entireSyntaxTree = Parser.Parser.parse "var i = 0"
  allIsGood = monkey.isSyntaxTreeValid(entireSyntaxTree)
  equal allIsGood, true

###########################################
#### var defs
###########################################

test "where's my var defs at, part 1", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var tuna")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "tuna = undefined"

test "where's my var defs at, part 1", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var tuna")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "tuna = undefined"

test "where's my var defs at, part 2", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var tuna = 3")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "tuna = 3"

test "where's my var defs at, part 5", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var tuna;\nvar fish;")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "tuna = undefined\nfish = undefined"

test "where's my var defs at, part 6", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var tuna = 3; var fish;")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "tuna = 3 ; fish = undefined"

test "where's my var defs at, part 7", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var tuna, fish = 3;")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "tuna = undefined ; fish = 3"

test "where's my var defs at, part 8", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var array = [1,3,4]; \nvar count = array.length")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "array = [1, 3, 4]\ncount = 3"

test "where's my var defs at, part 9", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var a; \nvar i = 3;\na = 2 + i;")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "a = undefined\ni = 3\na = 5"

test "where's my var defs at, part 10", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var a; \nvar i = 3;\na = i++;")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "a = undefined\ni = 3\na = 3"

###########################################
#### loops
###########################################

test "for ALL the things, part 1", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("for (var i = 0; i < 3; i++ ) { \n}")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "i = 0 | 1 | 2"

test "for ALL the things, part 2", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var i = 0; \nfor (; i < 3; i++ ) { \n}")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "i = 0\ni = 0 | 1 | 2"


test "for ALL the things, part 3", ->
  monkey = new SourceCodeParser
  longCodeString = "var array = [1,3,'4']; \n"
  longCodeString += "for (var i = 0, count = array.length; i < count; i++) { \n}"
  allIsGood = monkey.parseThemSourceCodes(longCodeString)
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "array = [1, 3, '4']\ni = 0 | 1 | 2 ; count = 3 | 3 | 3"

test "while ALL the things, part 1", ->
  monkey = new SourceCodeParser
  longCodeString = "var i = 0;\n"
  longCodeString += "while (i < 3){ \n"
  longCodeString += "i++; \n }"
  allIsGood = monkey.parseThemSourceCodes(longCodeString)
  longResult = "i = 0\ni = 0 | 1 | 2\ni = 1 | 2 | 3"
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), longResult

test "while ALL the things, part 2", ->
  monkey = new SourceCodeParser
  longCodeString = "var i = 0;\nvar array = [1,3,'4']; \n"
  longCodeString += "while (i < array.length){ \n"
  longCodeString += "i++; \n }"
  allIsGood = monkey.parseThemSourceCodes(longCodeString)
  longResult = "i = 0\narray = [1, 3, '4']\ni = 0 | 1 | 2\ni = 1 | 2 | 3"
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), longResult

###########################################
#### infinite loops
###########################################

###########################################
#### functions
###########################################

test "function definitions part 1", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("function binarySearch(key, array){}")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "key = undefined ; array = undefined"

test "function definitions part 2", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("function binarySearch(){}")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), ""

test "var function definitions part 1", ->
  monkey = new SourceCodeParser
  allIsGood = monkey.parseThemSourceCodes("var f = function f(x, y) { }")
  if(allIsGood)
    monkey.transmogrifier.run()
    equal monkey.displayValue().trim(), "x = undefined ; y = undefined"
