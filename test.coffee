module "parsing stuffs",
  setup: ->
    @hooman = HoomanTransmogrifier.sharedInstance()
    @monkey = new SourceCodeParser(@hooman)

test "where's my var defs at, part 1", ->
  @monkey.parseThemSourceCodes("var tuna")
  equal @hooman.displayValue().trim(), "tuna = undefined"

test "where's my var defs at, part 2", ->
  @monkey.parseThemSourceCodes("var tuna = 3")
  equal @hooman.displayValue().trim(), "tuna = undefined"

test "where's my var defs at, part 3", ->
  @monkey.parseThemSourceCodes("var var")
  equal @hooman.displayValue().trim(), ""

test "where's my var defs at, part 4", ->
  @monkey.parseThemSourceCodes("var")
  equal @hooman.displayValue().trim(), ""

test "where's my var defs at, part 5", ->
  @monkey.parseThemSourceCodes("var tuna;\nvar fish;")
  equal @hooman.displayValue().trim(), "tuna = undefined \nfish = undefined"

test "where's my var defs at, part 6", ->
  @monkey.parseThemSourceCodes("var tuna; var fish;")
  equal @hooman.displayValue().trim(), "tuna = undefined fish = undefined"

test "where's my var defs at, part 7", ->
  @monkey.parseThemSourceCodes("var tuna, fish;")
  equal @hooman.displayValue().trim(), "tuna = undefined fish = undefined"

test "for ALL the things, part 1", ->
  @monkey.parseThemSourceCodes("for (; tuna < 3; tuna++ ) {}")
  equal @hooman.displayValue().trim(), "tuna = undefined |"

test "for ALL the things, part 2", ->
  @monkey.parseThemSourceCodes("for (var tuna = 0; tuna < 3; tuna++ ) {}")
  equal @hooman.displayValue().trim(), "tuna = undefined |"

test "for ALL the things, part 3", ->
  @monkey.parseThemSourceCodes("for (;; tuna++ ) {}")
  equal @hooman.displayValue().trim(), "tuna = undefined |"

test "for ALL the things, part 4", ->
  @monkey.parseThemSourceCodes("for (;;) {}")
  equal @hooman.displayValue().trim(), ""

test "while ALL the things, part 1", ->
  @monkey.parseThemSourceCodes("while (tuna < 10) {}")
  equal @hooman.displayValue().trim(), "tuna = undefined |"

test "while ALL the things, part 2", ->
  @monkey.parseThemSourceCodes("while () {}")
  equal @hooman.displayValue().trim(), ""

test "while ALL the things, part 3", ->
  @monkey.parseThemSourceCodes("while (tuna++) {}")
  equal @hooman.displayValue().trim(), "tuna = undefined |"

test "while ALL the things, part 4", ->
  @monkey.parseThemSourceCodes("while (tuna) {}")
  equal @hooman.displayValue().trim(), "tuna = undefined |"

test "while ALL the things, part 5", ->
  @monkey.parseThemSourceCodes("while (tuna = 0) {}")
  equal @hooman.displayValue().trim(), "tuna = undefined |"

test "function definitions part 1", ->
  @monkey.parseThemSourceCodes("function binarySearch(key, array){}")
  equal @hooman.displayValue().trim(), "key = undefined array = undefined"

test "function definitions part 2", ->
  @monkey.parseThemSourceCodes("function binarySearch(){}")
  equal @hooman.displayValue().trim(), ""

test "function definitions part 3", ->
  @monkey.parseThemSourceCodes("function(x, y){}")
  equal @hooman.displayValue().trim(), "x = undefined y = undefined"

test "var AND function definitions part 1", ->
  @monkey.parseThemSourceCodes("var f = function f(x, y) { }")
  equal @hooman.displayValue().trim(), "f = undefined x = undefined y = undefined"   
