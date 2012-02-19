class SourceCodeParser
  constructor: (@transmogrifier) -> #this assigns params to members

  parseThemSourceCodes: (text) ->
    entireSyntaxTree = Parser.Parser.parse text
    @transmogrifier.setValueSize((text.split("\n")).length)

    @traverseSyntaxNode entireSyntaxTree

  getElementIfAnyOfType: (node, nodeType) ->
      return node if node.name is nodeType

      children = node.children
      return unless children

      for childNode in children
        # is this node of this type?
        return childNode if childNode.name is nodeType

        # if not, are any of the children nodes of this type?
        possibleChildSourceElementNode = @getElementIfAnyOfType childNode, nodeType
        return possibleChildSourceElementNode if possibleChildSourceElementNode   # hurrah

  getParamsInParamList: (node) -> 
    children = node.children
    return unless children

    paramNames = []
    for childNode in children
      paramNames.push(@getIdentifierNameFromNode childNode) if childNode.name is "Identifier"

    return paramNames


  getIdentifierNameFromNode: (node) ->
    return node.source.substr(node.range.location, node.range.length) 

  hoomanTransmogrifyNode: (node) ->
    if node.name is "VariableStatement"
      console.log "there's a variable statement for: #{identifierName}"
      identifierNameNode = @getElementIfAnyOfType node, "IdentifierName"
      identifierName = @getIdentifierNameFromNode identifierNameNode

      @transmogrifier.variableDeclaration identifierName, node.lineNumber
      
    else if node.name is "IterationStatement"
      console.log "found a loop statement"
      identifierNameNode = @getElementIfAnyOfType node, "IdentifierName"
      if identifierNameNode
        identifierName = @getIdentifierNameFromNode identifierNameNode
        @transmogrifier.loopExpression identifierName, node.lineNumber
        
    else if node.name is "FunctionDeclaration"
      console.log "found a function definition" 
      paramListNode = @getElementIfAnyOfType node, "FormalParameterList"
      if paramListNode
        debugger
        paramNames = @getParamsInParamList paramListNode
        if paramNames
          @transmogrifier.functionDeclaration paramNames, node.lineNumber
     
  traverseSyntaxNode: (node) ->
    @hoomanTransmogrifyNode node;

    children = node.children
    return unless children

    for childNode in children
      @traverseSyntaxNode childNode

    #else if someNode is 'if'
    # recursively call on the child
    # else if someNode is 'function' -> display the input params and call recursively on child
    #  transmogrifier.functionDeclaration someNode.parameters


class SourceTransmogrifier
  constructor: ->
    @value = []
    @allTheInputParamsToTheFunction = {}

  transmogrify: (allTheTexts) ->
    new SourceCodeParser @, allTheTexts

# decides what the editor should display, but doesn't evaluate
class HoomanTransmogrifier extends SourceTransmogrifier
  # this is also singleton. heyooo
  singletonInstance = null

  @sharedInstance: ->
    if not singletonInstance
      singletonInstance = new @ # monica: this means this

    singletonInstance   # monica: this means "return singletonInstance"

  takeForgetMeNow: ->
    @value = []

  setValueSize: (numLines) ->
    @value = []
    @value.push "" for i in [1..numLines]


  displayValue: ->
    apple = @value.join("\n")
    return apple

  variableDeclaration: (theNameOfTheVariable, lineNumber) ->
    # just in case two things happen on the same line:
    @value[lineNumber] += "#{theNameOfTheVariable} = undefined" + " "

  functionDeclaration: (parameters, lineNumber) ->
    allTheInputParamsToTheFunction = []
    for param in parameters
      allTheInputParamsToTheFunction[param] = undefined
      @value[lineNumber] += "#{param} = #{@allTheInputParamsToTheFunction[param]}" + " "

  loopExpression: (theNameOfTheVariable, lineNumber) ->
    @value[lineNumber] += "#{theNameOfTheVariable} = undefined | " + " "
# var i = 0;                    i = 0
# for (; i < 10; i++)           i = 0 | 1 | 2 | 3 | 4
# {
#   someThing = array[i];           someThing = 'a' | 'b' | 'c'
# }
# while (i < 5)           i = 0 | 1 | 2 | 3 | 4
# {
#   someThing = array[i];           someThing = 'a' | 'b' | 'c'
# }

  ifExpression: ->
# if ( a > 0 )   # display on the correct branch
#  a = 5                       a = 5
# or
# if ( a > 0 )
#  a = 5
# else
#  a = -5                      a = -5


  # this defines a function:
  makeSureAllTheVariablesAreStillAlive: ->
    for prettyVariableName in @allTheVariables
      'f'

  onEdit: ->


# actually evaluates all the things
class EvaluatingTransmogrifier extends SourceTransmogrifier
  # this is a singleton. heyooo
  singletonInstance = null

  @sharedInstance: ->
    if not singletonInstance
      singletonInstance = new @

    singletonInstance


# export ALL the things
window.HoomanTransmogrifier = HoomanTransmogrifier
window.EvaluatingTransmogrifier = EvaluatingTransmogrifier
window.SourceCodeParser = SourceCodeParser
