module "parsing stuffs",
  setup: ->
    @hooman = HoomanTransmogrifier.sharedInstance()
    @monkey = new SourceCodeParser(@hooman)

test "where's my var defs at, part 1", ->
  result = @monkey.parseThemSourceCodes("var tuna")
  equal result, "tuna"
test "where's my var defs at, part 2", ->
  result = @monkey.parseThemSourceCodes("var tuna = 3")
  equal result, "tuna"
test "where's my var defs at, part 3", ->
  result = @monkey.parseThemSourceCodes("var var")
  equal result, null
test "where's my var defs at, part 4", ->
  result = @monkey.parseThemSourceCodes("var")
  equal result, null




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
