class SourceTransmogrifier
  transmogrify: (allTheTexts) ->
    # result = Parser.Parser.parse(allTheTexts)
    # console.log result
    @value = allTheTexts

class HoomanTransmogrifier extends SourceTransmogrifier
  ForeverAloneHooman = null
  @foreverAloneHooman: ->
    if not ForeverAloneHooman
      ForeverAloneHooman = new HoomanTransmogrifier

    ForeverAloneHooman

  makeSureAllTheVariablesAreStillAlive: ->
    for prettyVariableName in @allTheVariables
      f

  onEdit: ->

class ScriptaculousTransmogrifier extends SourceTransmogrifier
  EverydayWeScripten = null
  @everydayWeScripten: ->
    if not EverydayWeScripten
      EverydayWeScripten = new ScriptaculousTransmogrifier

    ScriptaculousTransmogrifier


# export ALL the things
window.SourceTransmogrifier = SourceTransmogrifier
window.HoomanTransmogrifier = HoomanTransmogrifier
window.ScriptaculousTransmogrifier = ScriptaculousTransmogrifier
