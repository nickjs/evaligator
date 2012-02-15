module "hooman stuffs",
  setup: ->
    @hooman = HoomanTransmogrifier.foreverAloneHooman()

test "print variable assignment", ->
  @hooman.transmogrify "var foo = 'bar';"
  equal @hooman.value, "foo = 'bar'"
