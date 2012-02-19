class SourceCodeParser
  constructor: -> #this assigns params to members

  parseThemSourceCodes: (text) ->
    #text = "f = function f(x, y) { } ; x = undefined ; y = undefined"
    @variableMap = new VariableMapper
    @transmogrifier = new SourceTransmogrifier text, @variableMap

    entireSyntaxTree = Parser.Parser.parse text
    @recursivelyTransmogrifyAllTheThings entireSyntaxTree

    @transmogrifier.run()




  ###########################################
  #### Transmogrify = parse + eval a node
  ###########################################

  recursivelyTransmogrifyAllTheThings: (node) ->
    parseChildren = @transmogrifyNode node
    return if parseChildren isnt true

    children = node.children
    return unless children

    for childNode in children
      @recursivelyTransmogrifyAllTheThings childNode

  transmogrifyNode: (node) ->
    switch node.name
      when "VariableDeclaration"  then @transmogrifyVariableDeclaration node
      when "FunctionDeclaration"  then @transmogrifyFunctionDeclaration node
      when "FunctionExpression"   then @transmogrifyFunctionDeclaration node
      when "AssignmentExpression" then @transmogrifyAssignmentExpression node
      when "ForStatement"         then @transmogrifyForLoop node
      when "WhileStatement"       then @transmogrifyWhileLoop node
      else                        return true


  ###########################################
  #### Node specific tranmogrifying
  ###########################################

  transmogrifyVariableDeclaration: (node) ->
    # ok here's the thing. 
    # for var a,b, we have 2 VariableDeclaration nodes in this node and each has an identifier
    # for var a = b, we have 1 VariableDeclaration node, with two identifiers
    # so for variableDeclaration, we only care about the first identifier.
    identifierNames = @getIdentifierNamesInWholeStatement node
    @transmogrifier.variableAssignment node.lineNumber, identifierNames[0]

  transmogrifyAssignmentExpression: (node) ->
    identifierNames = @getIdentifierNamesInWholeStatement node
    for identifierName in identifierNames || []
      @transmogrifier.variableAssignment node.lineNumber, identifierName

  transmogrifyFunctionDeclaration: (node) ->
    debugger
    paramListNode = @getAllNodesOfType node, "FormalParameterList"
    # the formal parameter list contains a list of children, all of which are identifiers
    identifierNames = 
      @getIdentifierNamesForNodeList(paramListNode[0].children) if (paramListNode?[0]?.children)
    for identifierName in identifierNames || []
      @variableMap.variableOnLineNumberWithName node.lineNumber, identifierName

  # what follows is mega gross because for loops are complicated
  transmogrifyForLoop: (node) ->
    # we're looking either in the first  or second ; chunk of the for loop
    firstExpressionNodes = @getAllNodesOfType(node, "ForFirstExpression")

    if firstExpressionNodes
      # this can have either VariableDeclarationNoIn nodes, or ExpressionNoIn nodes
      # because the grammar is retarded these will have multiple identifiers (like in a = b)
      # so for each of those *NoIn nodes, we only care about the first identifier
      noInitNodes = @getAllNodesOfType(node, "VariableDeclarationNoIn") || @getAllNodesOfType(node, "ExpressionNoIn")
      identifierNames = (@getIdentifierNamesInWholeStatement(n)?[0] for n in noInitNodes)
    else      
      secondExpressionNodes = @getAllNodesOfType(node, "Expression")
      identifierNames = 
        @getIdentifierNamesInWholeStatement secondExpressionNodes[0] if secondExpressionNodes?[0]
   
    # hurrah! here we have some list of identifiers at last!
    for identifierName in identifierNames || []
      @transmogrifier.iterationAssignment node.lineNumber, identifierName
    




  ###########################################
  #### SyntaxNode helper functions. Hurrah!
  ###########################################

  # given a node, gives you nack its identifier name
  getIdentifierNameFromNode: (node) -> 
    return node.source.substr(node.range.location, node.range.length)

  # gives you any variables in this syntax node (can be a whole for loop etc)
  getIdentifierNamesInWholeStatement: (node) ->
    identifierNameNodes = @getAllNodesOfType node, "Identifier"
    identifierNames = @getIdentifierNamesForNodeList identifierNameNodes if identifierNameNodes

  getIdentifierNamesForNodeList: (nodeList) ->
    paramNames = []
    for childNode in nodeList
      paramNames.push(@getIdentifierNameFromNode childNode) if childNode.name is "Identifier"

    return paramNames

  # gives you a list of nodes of a specific nodeType
  getAllNodesOfType: (node, nodeType) ->
    return node if node.name is nodeType
    nodeList = []

    children = node.children
    return unless children

    # depth first recurse on all the children to collect ALL the things
    for childNode in children
      if childNode.name is nodeType 
        nodeList.push childNode
      else  # if not, are any of the children nodes of this type?
        possibleChildSourceElementNode = @getAllNodesOfType childNode, nodeType
        if possibleChildSourceElementNode && possibleChildSourceElementNode.length > 0
          nodeList = nodeList.concat possibleChildSourceElementNode

    return nodeList if nodeList?.length

  
    


  

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
