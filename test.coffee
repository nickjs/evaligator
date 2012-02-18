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
  @monkey.parseThemSourceCodes("var x;\nvar y;")
  equal @hooman.value, "x = undefined\ny = undefined\n"

test "where's my var defs at, part 6", ->
  @monkey.parseThemSourceCodes("var x; var y;")
  equal @hooman.value, "x = undefined\ny = undefined\n"

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
