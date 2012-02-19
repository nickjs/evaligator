class SourceCodeParser
  constructor: -> #this assigns params to members

  parseThemSourceCodes: (text) ->
    @variableMap = new VariableMapper
    @transmogrifier = new SourceTransmogrifier text, @variableMap

    entireSyntaxTree = Parser.Parser.parse text
    @traverseSyntaxNode entireSyntaxTree

    @transmogrifier.run()


  ###
    SyntaxNode helper function
  ###

  # given a node, gives you back the variable in it
  getIdentifierNameFromNode: (node) ->
    return node.source.substr(node.range.location, node.range.length)

  # gives you a list of nodes of nodeType
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

  # gives you any variables in this parent
  getIdentifierNamesForStatement: (node) ->
    identifierNameNodes = @getElementsIfAnyOfType node, "Identifier"
    identifierNames = @getNodeNamesFromNodeList(identifierNameNodes) if identifierNameNodes

  # monica is responsible for the copy paste but she is tired and gives zero fucks
  getNodeNamesFromNodeList: (nodeList) ->
    paramNames = []
    for childNode in nodeList
      paramNames.push(@getIdentifierNameFromNode childNode) if childNode.name is "Identifier"

    return paramNames

  getParamNamesInFormalParamList: (node) ->
    children = node.children
    return unless children

    paramNames = []
    for childNode in children
      paramNames.push(@getIdentifierNameFromNode childNode) if childNode.name is "Identifier"

    return paramNames

  transmogrifyNode: (node) ->
    if node.name is "VariableStatement"
      console.log "there's a variable statement"
      identifierNames = @getIdentifierNamesForStatement node
      for identifierName in identifierNames || []
        @transmogrifier.variableAssignment node.lineNumber, identifierName

    # monica also apologizes for the code sins that follow and promises to fix them tomorrow
    else if node.name is "ForStatement"
      console.log "found a for loop"
      # we're looking either in the first  or second ; chunk of the for loop
      firstExpressionNodes = @getElementsIfAnyOfType(node, "ForFirstExpression") || @getElementsIfAnyOfType(node, "Expression")
      expressionNode = firstExpressionNodes?[0]

      identifierNames = @getIdentifierNamesForStatement expressionNode
      for identifierName in identifierNames || []
        @transmogrifier.iterationAssignment node.lineNumber, identifierName

    else if node.name is "WhileStatement"
      console.log "found a while loop"
      identifierNames = @getIdentifierNamesForStatement node
      for identifierName in identifierNames || []
        @transmogrifier.iterationAssignment node.lineNumber, identifierName

    else if node.name is "FunctionDeclaration" or node.name is "FunctionExpression"
      console.log "found a function definition"
      paramListNode = @getElementsIfAnyOfType node, "FormalParameterList"
      if paramListNode
        paramNames = @getParamNamesInFormalParamList paramListNode[0]
        if paramNames
          for paramName in paramNames
            @variableMap.variableOnLineNumberWithName node.lineNumber, paramName

    else if node.name is "AssignmentExpression"
      identifierNames = @getIdentifierNamesForStatement node
      for identifierName in identifierNames || []
        @transmogrifier.variableAssignment node.lineNumber, identifierName

    else
      return true

  traverseSyntaxNode: (node) ->
    parseChildren = @transmogrifyNode node
    return if parseChildren isnt true

    children = node.children
    return unless children

    for childNode in children
      @traverseSyntaxNode childNode

    #else if someNode is 'if'
    # recursively call on the child
    # else if someNode is 'function' -> display the input params and call recursively on child
    #  transmogrifier.functionDeclaration someNode.parameters

  displayValue: ->
    winningVariableMap.displayValue()

winningVariableMap = null

class VariableMapper
  constructor: ->
    @allTheLines = []

  variableOnLineNumberWithName: (lineNumber, identifier) ->
    variablesForThisLine = @allTheLines[lineNumber] ||= []
    for variable in variablesForThisLine
      if variable?.identifier is identifier
        return variable

    variablesForThisLine.push variable = identifier: identifier, value: undefined
    variable

  assignValue: (lineNumber, identifier, value) ->
    variable = @variableOnLineNumberWithName lineNumber, identifier
    variable.value = @makeTheValuePretty(value)

  iterateValue: (lineNumber, identifier, value) ->
    variable = @variableOnLineNumberWithName lineNumber, identifier
    (variable.iterations ||= []).push @makeTheValuePretty(value)

  makeTheValuePretty: (value) ->
    switch Object.prototype.toString.call(value).slice(8, -1)
      when 'String' then "'#{value}'"
      when 'Boolean' then value.toString().toUpperCase()
      when 'Array'
        innerValues = (@makeTheValuePretty(innerValue) for innerValue in value)
        "[#{innerValues.join(', ')}]"
      when 'Object'
        innerValues = ("#{key}: #{@makeTheValuePretty(innerValue)}" for key, innerValue of value)
        "{#{innerValues.join(', ')}}"
      else value

  displayValue: ->
    result = for line in @allTheLines
      if line
        textForThisLine = for variable in line
          "#{variable.identifier} = #{variable.iterations?.join(' | ') || variable.value}"
        textForThisLine.join " ; "
    result.join "\n"

class SourceTransmogrifier
  constructor: (@text, @variableMap) ->
    @source = @text.split /[\n|\r]/
  run: ->
    # console.log @source.join("\n")
    try
      new Function("__VARIABLE_MAP__", "try{#{@source.join("\n")}}catch(e){}")(@variableMap)
      winningVariableMap = @variableMap

  variableAssignment: (lineNumber, variableName) ->
    @source[lineNumber] += ";__VARIABLE_MAP__.assignValue(#{lineNumber},'#{variableName}',#{variableName});"

  iterationAssignment: (lineNumber, variableName) ->
    @source[lineNumber] += ";__VARIABLE_MAP__.iterateValue(#{lineNumber},'#{variableName}',#{variableName});"

# export ALL the things
window.SourceCodeParser = SourceCodeParser
