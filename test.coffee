module "parsing stuffs",
  setup: ->
    @hooman = HoomanTransmogrifier.sharedInstance()
    @monkey = new SourceCodeParser(@hooman)

test "where's my var defs at, part 1", ->
  @monkey.parseThemSourceCodes("var tuna")
  equal @hooman.value, "tuna = undefined\n"

test "where's my var defs at, part 2", ->
  @monkey.parseThemSourceCodes("var tuna = 3")
  equal @hooman.value, "tuna = undefined\n"

test "where's my var defs at, part 3", ->
  @monkey.parseThemSourceCodes("var var")
  equal @hooman.value, ""

test "where's my var defs at, part 4", ->
  @monkey.parseThemSourceCodes("var")
  equal @hooman.value, ""

test "where's my var defs at, part 5", ->
  @monkey.parseThemSourceCodes("var tuna;\nvar fish;")
  equal @hooman.value, "tuna = undefined\nfish = undefined\n"

test "where's my var defs at, part 6", ->
  @monkey.parseThemSourceCodes("var tuna; var fish;")
  equal @hooman.value, "tuna = undefined\nfish = undefined\n"

test "where's my var defs at, part 7", ->
  @monkey.parseThemSourceCodes("var tuna, fish;")
  equal @hooman.value, "tuna = undefined\nfish = undefined\n"

test "for ALL the things, part 1", ->
  @monkey.parseThemSourceCodes("var a = 0\n for (; a < 3; a++ ) {}")
  equal @hooman.value, "a = undefined\nfor loop detected\n"

  test "while ALL the things, part 1", ->
  @monkey.parseThemSourceCodes("var a = 0\n while (a < 10) {a++}")
  equal @hooman.value, "a = undefined\nfor loop detected\n"

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
