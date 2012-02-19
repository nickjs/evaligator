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

module "hooman stuffs",
  setup: ->
    @hooman = HoomanTransmogrifier.sharedInstance()

test "print variable declaration", ->
  @hooman.transmogrify "var foo;"
  equal @hooman.value, "foo = undefined"

test "print variable assignment", ->
  @hooman.transmogrify "var foo = 3;"
  equal @hooman.value, "foo = 3"

test "print loop assignments", ->
  @hooman.transmogrify "for (var i = 0; i < 3; i++) {}"
  equal @hooman.value, "i = 0 | 1 | 2"
