###########################################
#### PEG parse all yo syntax codes
###########################################

# maps all the vars deffed/used on a line so that they can be eval-ed
winningVariableMap = null

class SourceCodeParser

  displayValue: ->
    winningVariableMap.displayValue()

  parseThemSourceCodes: (text) ->
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
    importantNodeNames = ["VariableDeclaration", "AssignmentExpression",
                          "FunctionDeclaration", "FunctionExpression",
                          "ForStatement", "WhileStatement",
                          "IfStatement"]

    if node.name in importantNodeNames
      @["transmogrify#{node.name}"](node)
    else
      true

  assignValue: (lineNumber, identifier) ->
    key = if @BLOCK_MODE_GO then 'iterationAssignment' else 'variableAssignment'
    @transmogrifier[key](lineNumber, identifier)

  ###########################################
  #### Node specific tranmogrifying
  ###########################################

  transmogrifyVariableDeclaration: (node) ->
     # ok here's the thing.
    # for var a,b, we have 2 VariableDeclaration nodes in this node and each has an identifier
    # for var a = b, we have 1 VariableDeclaration node, with two identifiers
    # so for variableDeclaration, we only care about the first identifier.
    identifierNames = @getIdentifierNamesInWholeStatement node
    @assignValue node.lineNumber, identifierNames[0]

    # the only other interesting bit here is if we have var f = function (..){}
    # in which case this node also has a FunctionExpression
    possibleFunctionExpression = @getAllNodesOfType node, "FunctionExpression"
    @transmogrifyFunctionDeclaration(possibleFunctionExpression[0]) if possibleFunctionExpression?[0]

   
  transmogrifyAssignmentExpression: (node) ->
    # AssignmentExpression = LeftHandSideExpression(identifier) + other stuff
    # however in a = i++ and a = b + c, the syntaxNodes for i,b,c are literally identical
    # so fuck yo grammars, we can only display a
    firstLeftHandSideExpression = @getAllNodesOfType(node, "LeftHandSideExpression")
    identifierNames = @getIdentifierNamesInWholeStatement firstLeftHandSideExpression?[0]
    for identifierName in identifierNames || []
      @assignValue node.lineNumber, identifierName
    false

  transmogrifyFunctionDeclaration: (node) ->
    paramListNode = @getAllNodesOfType node, "FormalParameterList"
    # the formal parameter list contains a list of children, all of which are identifiers
    identifierNames =
      @getIdentifierNamesForNodeList(paramListNode[0].children) if (paramListNode?[0]?.children)

    for identifierName in identifierNames || []
      @variableMap.variableOnLineNumberWithName node.lineNumber, identifierName
    false

  # what follows is mega gross because for loops are complicated
  transmogrifyForStatement: (node) ->
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

    @BLOCK_MODE_GO = true
    for identifierName in identifierNames || []
      @assignValue node.lineNumber, identifierName

    @recursivelyTransmogrifyAllTheThings @getAllNodesOfType(node, "Block")?[0]
    @BLOCK_MODE_GO = false

  transmogrifyWhileStatement: (node) ->
    # WhileStatement = Expression(thing in parans) + Statement(thing in statement)
    # we only care about the identifiers in the expression
    expressionNode = @getAllNodesOfType(node, "Expression")
    identifierNames = @getIdentifierNamesInWholeStatement expressionNode?[0]

    @BLOCK_MODE_GO = true
    for identifierName in identifierNames || []
      @assignValue node.lineNumber, identifierName

    @recursivelyTransmogrifyAllTheThings @getAllNodesOfType(node, "Block")?[0]
    @BLOCK_MODE_GO = false

  transmogrifyIfStatement: (node) ->
    for blockNode in @getAllNodesOfType(node, "Block")
      @recursivelyTransmogrifyAllTheThings blockNode
    false


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



###########################################
#### Maps and eval all yo variables
###########################################

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
