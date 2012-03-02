###########################################
#### PEG parse all yo syntax codes
###########################################

# maps all the vars deffed/used on a line so that they can be eval-ed
winningVariableMap = null

class SourceCodeParser
  displayValue: ->
    winningVariableMap?.displayValue() || ""

  parseThemSourceCodes: (text, useProtection=true) ->
    @variableMap = new VariableMapper


    @transmogrifier = new SourceTransmogrifier text, @variableMap, useProtection
    entireSyntaxTree = Parser.Parser.parse text

    # if this invalid, don't bother parsing anything
    allIsGood = @isSyntaxTreeValid(entireSyntaxTree)
    return false unless allIsGood

    @recursivelyTransmogrifyAllTheThings entireSyntaxTree

    window.ALL_YOUR_PARAMETERS_IS_BELONG_TO_ME?(@variableMap)
    window.ASK_ME_FOR_ALL_MY_PARAMETERS?(@variableMap)

    return true

  isSyntaxTreeValid: (node) ->
    # if the tree isn't valid, one of the immediate children's name will be %start
    if !node
      return true

    if node.name is "%start"
      return false

    children = node.children
    return true unless children

    for childNode in children
      if childNode.name is "%start"
        return false

    return true

  ###########################################
  #### Transmogrify = parse + eval a node
  ###########################################

  recursivelyTransmogrifyAllTheThings: (node) ->
    # invalid nodes are named %start and should tell you to abandon all hope
    return unless node

    parseChildren = @transmogrifyNode node
    return if parseChildren isnt true

    children = node.children
    return unless children

    for childNode in children
      @recursivelyTransmogrifyAllTheThings childNode

  transmogrifyNode: (node) ->
    transmogrifyFunction = @["transmogrify#{node.name}"]
    if transmogrifyFunction then transmogrifyFunction.call(@, node) else true

  assignValue: (lineNumber, identifier, displayLineNumber) ->
    key = if @BLOCK_MODE_GO then 'iterationAssignment' else 'variableAssignment'
    @transmogrifier[key](arguments...)

  ###########################################
  #### Node specific tranmogrifying
  ###########################################

  transmogrifyVariableDeclaration: (node) ->
    # ok here's the thing.
    # for var a,b, we have 2 VariableDeclaration nodes in this node and each has an identifier
    # for var a = b, we have 1 VariableDeclaration node, with two identifiers
    # so for variableDeclaration, we only care about the first identifier.

    # the only other interesting bit here is if we have var f = function (..){}
    # in which case this node also has a FunctionExpression
    possibleFunctionExpression = @getAllNodesOfType node, "FunctionExpression"
    return @transmogrifyFunctionExpression(possibleFunctionExpression[0]) if possibleFunctionExpression?[0]

    identifierNames = @getIdentifierNamesInWholeStatement node
    @assignValue node.lineNumber, identifierNames[0]


  transmogrifyAssignmentExpression: (node) ->
    # same as above
    possibleFunctionExpression = @getAllNodesOfType node, "FunctionExpression"
    return @transmogrifyFunctionExpression(possibleFunctionExpression[0]) if possibleFunctionExpression?[0]

    # AssignmentExpression = LeftHandSideExpression(identifier) + other stuff
    # however in a = i++ and a = b + c, the syntaxNodes for i,b,c are literally identical
    # so fuck yo grammars, we can only display a
    firstLeftHandSideExpression = @getAllNodesOfType(node, "LeftHandSideExpression")
    identifierNames = @getIdentifierNamesInWholeStatement firstLeftHandSideExpression?[0]
    for identifierName in identifierNames || []
      @assignValue node.lineNumber, identifierName
    false

  transmogrifyFunctionExpression: (node) ->
    @transmogrifyFunctionDeclaration node

  transmogrifyFunctionDeclaration: (node) ->
    paramListNode = @getAllNodesOfType node, "FormalParameterList"
    # the formal parameter list contains a list of children, all of which are identifiers
    identifierNames =
      @getIdentifierNamesForNodeList(paramListNode[0].children) if (paramListNode?[0]?.children)

    returnStatementNode = @getAllNodesOfType node, "ReturnStatement"
    returnStatementIdentifier = @getIdentifierNameFromNode returnStatementNode[0] if returnStatementNode?[0]

    # HEY NICK LISTEN LISTEN do something with the return statement here

    for identifierName in identifierNames || []
      @variableMap.variableOnLineNumberWithName node.lineNumber, identifierName, isFunctionParameter: yes

    @transmogrifier.functionDeclaration node.lineNumber
    @recursivelyTransmogrifyAllTheThings @getAllNodesOfType(node, "FunctionBody")[0]

    false

  # what follows is mega gross because for loops are complicated
  transmogrifyForStatement: (node) ->
    # we're looking either in the first  or second ; chunk of the for loop
    if firstExpressionNodes = @getAllNodesOfType(node, "ForFirstExpression")
      # this can have either VariableDeclarationNoIn nodes, or ExpressionNoIn nodes
      # because the grammar is retarded these will have multiple identifiers (like in a = b)
      # so for each of those *NoIn nodes, we only care about the first identifier
      noInitNodes = @getAllNodesOfType(node, "VariableDeclarationNoIn") || @getAllNodesOfType(node, "ExpressionNoIn")
      identifierNames = (@getIdentifierNamesInWholeStatement(n)?[0] for n in noInitNodes)
    else
      secondExpressionNodes = @getAllNodesOfType(node, "Expression")
      identifierNames =
        @getIdentifierNamesInWholeStatement secondExpressionNodes[0] if secondExpressionNodes?[0]

    @transmogrifier.loopDeclaration node.lineNumber
    @BLOCK_MODE_GO = true

    if blockNode = @getAllNodesOfType(node, "Block")?[0]
      blockSource = blockNode.source
      blockLocation = blockNode.range.location
      if needsBlockifying = blockSource.substr(blockLocation, blockNode.range.length).indexOf('\n') is -1
        @transmogrifier.psuedoBlockifyStart blockNode.lineNumber, node.range.location, blockSource

      for identifierName in identifierNames || []
        @assignValue node.lineNumber, identifierName, node.lineNumber

      @transmogrifier.bubbleWrapThisLoop blockNode.lineNumber # prevent infinite loops if needed
      @recursivelyTransmogrifyAllTheThings blockNode if blockNode

      if needsBlockifying
        @transmogrifier.psuedoBlockifyEnd blockNode.lineNumber

    @BLOCK_MODE_GO = false

  transmogrifyWhileStatement: (node) ->
    # WhileStatement = Expression(thing in parans) + Statement(thing in statement)
    # we only care about the identifiers in the expression
    # and more sepcifically, only about the first identifier in the expression
    expressionNode = @getAllNodesOfType(node, "Expression")
    identifierNames = @getIdentifierNameFromNode expressionNode[0] if expressionNode?[0]

    @transmogrifier.loopDeclaration node.lineNumber

    @BLOCK_MODE_GO = true
    @transmogrifier.bubbleWrapThisLoop node.lineNumber # prevent infinite loops if needed
    @assignValue node.lineNumber, identifierNames[0] if expressionNode?[0]
    blockNode = @getAllNodesOfType(node, "Block")?[0]
    @recursivelyTransmogrifyAllTheThings blockNode
    @BLOCK_MODE_GO = false

  transmogrifyDoWhileStatement: (node) ->
    # DoWhileStatement = do + Statement(thing in statement) + while + expression(thing in parans)
    # we only care about the that last expression, the first identifier
    debugger
    expressionNode = @getAllNodesOfType(node, "Expression")
    identifierNames = @getIdentifierNameFromNode expressionNode[0] if expressionNode?[0]

    @transmogrifier.loopDeclaration node.lineNumber

    @BLOCK_MODE_GO = true
    @transmogrifier.bubbleWrapThisLoop node.lineNumber # prevent infinite loops if needed
    @assignValue node.lineNumber, identifierNames[0] if expressionNode?[0]
    blockNode = @getAllNodesOfType(node, "Block")?[0]
    @recursivelyTransmogrifyAllTheThings blockNode
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

  variableOnLineNumberWithName: (lineNumber, identifier, options) ->
    variablesForThisLine = @allTheLines[lineNumber] ||= []
    for variable in variablesForThisLine
      if variable?.identifier is identifier
        break
      else
        variable = null

    variablesForThisLine.push(variable = identifier: identifier, value: undefined, lineNumber: lineNumber) if not variable

    if options
      for key, value of options
        variable[key] = value

    variable

  argumentsForFunction: (lineNumber) -> #
    variablesForThisLine = @allTheLines[lineNumber]
    results = [] # we use our own array instead of the comprehension because coffeescript would also push elements that fail the if
    if variablesForThisLine
      for variable in variablesForThisLine
        if variable?.isFunctionParameter
          results.push variable.value

    results

  allFunctionParameters: ->
    results = []
    for line in @allTheLines
      continue if not line
      thisFunction = null
      for variable in line
        if variable?.isFunctionParameter
          (thisFunction ||= []).push variable

      results.push(thisFunction) if thisFunction
    results


  assignValue: (lineNumber, identifier, value) ->
    variable = @variableOnLineNumberWithName lineNumber, identifier
    variable.value = value

  assignValueIfIdentifierExists: (lineNumber, identifier, value) ->
    if line = @allTheLines[lineNumber]
      for variable in line
        if variable?.identifier is identifier
          @assignValue arguments...
          return true

    false

  iterateValue: (lineNumber, identifier, value) ->
    variable = @variableOnLineNumberWithName lineNumber, identifier
    (variable.iterations ||= []).push value

  makeTheValuePretty: (value) ->
    switch Object.prototype.toString.call(value).slice(8, -1)
      when 'String' then "'#{value}'"
      when 'Boolean' then value.toString().toUpperCase()
      when 'Function' then (functionString = value.toString()).substr(0,functionString.indexOf('{'))
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
          "#{variable.identifier} = #{variable.iterations?.map((value) => @makeTheValuePretty(value)).join(' | ') || @makeTheValuePretty(variable.value)}"
        textForThisLine.join " ; "
    result.join "\n"

class SourceTransmogrifier
  maxProtectedIterations = 10

  constructor: (@text, @variableMap, @useProtection) ->
    @source = @text.split /[\n|\r]/
    @functionMap = []
    @numLoopsWrapped = 0

  run: ->
    @numLoopsWrapped = 0
    compiledSource =
      """
        __INF_LOOP_BUBBLE_WRAP__ = [];
        try{
          #{@source.join("\n")}
        } finally {
          try {
            for(var _i = 0, _count = __FUNCTION_MAP__.length, _f; _i < _count && (_f = __FUNCTION_MAP__[_i] || true); _i++)
                if (typeof _f === 'function')
                  _f.apply(null, __VARIABLE_MAP__.argumentsForFunction(_i));
          } catch (e) {}
        }
      """

    if window.DEBUG_THE_EVALIGATOR
      document.getElementById('transmogrifier-debug-output').innerText = compiledSource
    try
      new Function("__VARIABLE_MAP__", "__FUNCTION_MAP__", compiledSource)(@variableMap, @functionMap)
      winningVariableMap = @variableMap

  psuedoBlockifyStart: (lineNumber) ->
    index = @source[lineNumber].indexOf('{')
    console.log index
    @source[lineNumber] = "#{@source[lineNumber].substr(0, index - 1)}\n{/* AUTO BRACKET */#{@source[lineNumber].substr(index)}\n"

  psuedoBlockifyEnd: (lineNumber) ->
    @source[lineNumber] += "\n/* END AUTO BRACKET */}"

  variableAssignment: (lineNumber, variableName, displayLineNumber=lineNumber) ->
    @source[lineNumber] += ";\n__VARIABLE_MAP__.assignValue(#{lineNumber},'#{variableName}',#{variableName});"

  loopDeclaration: (lineNumber) ->
    if @useProtection
      @source[lineNumber] = ";__INF_LOOP_BUBBLE_WRAP__[#{@numLoopsWrapped}] = 0; " + @source[lineNumber]


  bubbleWrapThisLoop: (lineNumber) ->
    if @useProtection
      @source[lineNumber] += "if (++(__INF_LOOP_BUBBLE_WRAP__[#{@numLoopsWrapped}]) > #{maxProtectedIterations}){ break; }"
      ++@numLoopsWrapped  # we've protected this loop, ready for the next one!

  iterationAssignment: (lineNumber, variableName, displayLineNumber=lineNumber) ->
    @source[lineNumber] += ";\n__VARIABLE_MAP__.iterateValue(#{displayLineNumber},'#{variableName}',#{variableName});"

  functionDeclaration: (lineNumber) ->
    line = @source[lineNumber]
    index = line.indexOf 'function'
    @source[lineNumber] = line.substr(0, index) + " __FUNCTION_MAP__[#{lineNumber}] = " + line.substr(index)

# export ALL the things
window.SourceCodeParser = SourceCodeParser
window.SourceTransmogrifier = SourceTransmogrifier
window.VariableMapper = VariableMapper
