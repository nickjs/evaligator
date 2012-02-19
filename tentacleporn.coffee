class SourceCodeParser
  constructor: -> #this assigns params to members

  parseThemSourceCodes: (text) ->
    @variableMap = new VariableMapper
    @transmogrifier = new SourceTransmogrifier text, @variableMap

    entireSyntaxTree = Parser.Parser.parse text
    @traverseSyntaxNode entireSyntaxTree

    @transmogrifier.run()

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

  transmogrifyNode: (node) ->
    if node.name is "VariableStatement"
      identifierNameNode = @getElementIfAnyOfType node, "IdentifierName"
      identifierName = @getIdentifierNameFromNode identifierNameNode
      console.log "there's a variable statement for: #{identifierName}"

      @variableMap.variableOnLineNumberWithName node.lineNumber, identifierName
      @transmogrifier.variableAssignment node.lineNumber, identifierName

    else if node.name is "IterationStatement"
      console.log "found a loop statement"
      identifierNameNode = @getElementIfAnyOfType node, "IdentifierName"
      if identifierNameNode
        identifierName = @getIdentifierNameFromNode identifierNameNode
        @variableMap.variableOnLineNumberWithName node.lineNumber, identifierName
        # @transmogrifier.variableAssignment node.lineNumber, identifierName

    else if node.name is "FunctionDeclaration"
      console.log "found a function definition"
      paramListNode = @getElementIfAnyOfType node, "FormalParameterList"
      if paramListNode
        paramNames = @getParamsInParamList paramListNode
        if paramNames
          for paramName in paramNames
            @variableMap.variableOnLineNumberWithName node.lineNumber, paramName

    else if node.name is "AssignmentExpression"
      identifierNameNode = @getElementIfAnyOfType node, "IdentifierName"
      identifierName = @getIdentifierNameFromNode identifierNameNode

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
    @variableMap.displayValue()

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
    variable.value = value

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

  variableAssignment: (lineNumber, variableName) ->
    @source[lineNumber] += ";__VARIABLE_MAP__.assignValue(#{lineNumber},'#{variableName}',#{variableName});"

# export ALL the things
window.SourceCodeParser = SourceCodeParser
