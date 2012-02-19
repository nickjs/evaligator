class SourceCodeParser
  constructor: (@transmogrifier) -> #this assigns params to members

  parseThemSourceCodes: (text) ->
    entireSyntaxTree = Parser.Parser.parse text
    @transmogrifier.setValueSize((text.split("\n")).length)

    @traverseSyntaxNode entireSyntaxTree

  getElementsIfAnyOfType: (node, nodeType) ->
    return node if node.name is nodeType

    nodeList = []
    
    children = node.children
    return unless children

    for childNode in children
      if childNode.name is nodeType 
        nodeList.push childNode

      else  # if not, are any of the children nodes of this type?        
        possibleChildSourceElementNode = @getElementsIfAnyOfType childNode, nodeType
        if possibleChildSourceElementNode && possibleChildSourceElementNode.length > 0
          nodeList = nodeList.concat possibleChildSourceElementNode

    return nodeList if nodeList?.length
      
  getParamNamesInFormalParamList: (node) -> 
    children = node.children
    return unless children

    paramNames = []
    for childNode in children
      paramNames.push(@getIdentifierNameFromNode childNode) if childNode.name is "Identifier"

    return paramNames

  # monica is responsible for the copy paste but she is tired and gives zero fucks
  getNodeNamesFromNodeList: (nodeList) -> 
    paramNames = []
    for childNode in nodeList
      paramNames.push(@getIdentifierNameFromNode childNode) if childNode.name is "Identifier"

    return paramNames

  getIdentifierNameFromNode: (node) ->
    return node.source.substr(node.range.location, node.range.length) 

  hoomanTransmogrifyNode: (node) ->
    if node.name is "VariableStatement"
      # there may be multiple nodes of this kind on the same line. see var a, b
      identifierNameNodes = @getElementsIfAnyOfType node, "Identifier"
      if identifierNameNodes
        identifierNames = @getNodeNamesFromNodeList identifierNameNodes
        if identifierNames
          @transmogrifier.variableDeclaration identifierNames, node.lineNumber
      
    # monica also apologizes for the code sins that follow and promises to fix them tomorrow  
    else if node.name is "ForStatement"
      debugger
      firstExpressionNodes = @getElementsIfAnyOfType node, "ForFirstExpression"

      # i might not have a first expression, so then let's settle for the first assignment we find
      if (firstExpressionNodes)
        identifierNameNodes = @getElementsIfAnyOfType firstExpressionNodes[0], "Identifier"
      else
        firstAssignmentNodes = @getElementsIfAnyOfType node, "Expression"
        if (firstAssignmentNodes)
          identifierNameNodes = @getElementsIfAnyOfType firstAssignmentNodes[0], "Identifier"

      if identifierNameNodes
        identifierNames = @getNodeNamesFromNodeList identifierNameNodes
        @transmogrifier.loopExpression identifierNames, node.lineNumber
    
    else if node.name is "WhileStatement"
      identifierNameNodes = @getElementsIfAnyOfType node, "Identifier"
      if identifierNameNodes
        identifierNames = @getNodeNamesFromNodeList identifierNameNodes
        @transmogrifier.loopExpression identifierNames, node.lineNumber
            
    else if node.name is "FunctionDeclaration" or node.name is "FunctionExpression"
      paramListNode = @getElementsIfAnyOfType node, "FormalParameterList"

      debugger
      if paramListNode
        paramNames = @getParamNamesInFormalParamList paramListNode[0] 
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

  variableDeclaration: (variableNames, lineNumber) ->
    for varName in variableNames
      @value[lineNumber] += "#{varName} = undefined" + " "

  functionDeclaration: (parameters, lineNumber) ->
    allTheInputParamsToTheFunction = []
    for param in parameters
      allTheInputParamsToTheFunction[param] = undefined
      @value[lineNumber] += "#{param} = #{@allTheInputParamsToTheFunction[param]}" + " "

  loopExpression: (variableNames, lineNumber) ->
    for varName in variableNames
      @value[lineNumber] += "#{varName} = undefined |" + " "
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
