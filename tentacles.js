self.onmessage = function(msg) {
  var cesspoolOfVariables = {}; // all the introduced variables and their current and previous values
  var result = '';

  var allTheCode = msg.data;
  if (allTheCode){
    var allTheLines = allTheCode.split("\n")

    for (i = 0; i < allTheLines.length; ++i){

      if ( isAVariableDefinition(allTheLines[i]) ){
        // ooey, new variable. let's add it to the map and print it out
        // TODO: what if we redefine a variable?
        var newVar = allTheLines[i].replace(/var/g, " ").split("="); // this line is reliable as fuck
        cesspoolOfVariables[newVar[0].trim()] = {name: newVar[0].trim(), previous: -1, current: newVar[1]}

        result += newVar[0] + " = " + newVar[1];
      }
      else if ( isSomeTypeOfValueChange(allTheLines[i]) ){
        // re-eval the var and reassign it to the map
        var thisVar = cesspoolOfVariables[whichVariableIsBeingChanged(allTheLines[i])];

        if ( thisVar ){
          var wholeContextUpToNow = "";
          for ( var j = 0; j <= i; j++ )
          {
            wholeContextUpToNow += allTheLines[j] + ";\n";

          }



          // first thing: to eval, we need to introduce the variable in the context with the prev. value
          // second thing: if this was added as a tentacle, then the value of this var isn't a number
          // it's the name of a different var. so we need to trace back to the value of that var
          /*var fakeInitializeString = thisVar.name + "=" + thisVar.current + ";";

          if ( isVarATentacle(thisVar.current))
          {
            // add the value of the tentacle to the context
            fakeInitializeString = thisVar.current + "=" + findTentacleValue(thisVar.current)
                      + "; " + fakeInitializeString;
          }
          */

          //var amazingEvalString = wholeConten//fakeInitializeString + allTheLines[i];
          //eval(amazingEvalString);
          //alert(wholeContextUpToNow);
          try {
            eval(wholeContextUpToNow);
            var amazingEvalResult = eval(thisVar.name);

          }
          catch (e) {}



          // reassign it to the map
          thisVar.previous = thisVar.current;
          thisVar.current = amazingEvalResult;
          cesspoolOfVariables[thisVar.name] = thisVar;

          result += thisVar.name + " = " + thisVar.current;
          // TODO: if the original value was a tentacle, should we display ALL of the tentacles?

        }
      }

      result += '\n';
    }
  }

  self.postMessage(result);

  function isAVariableDefinition(codeLine){
    return (codeLine.indexOf("var") != -1);
  }
  function isSomeTypeOfValueChange(codeLine){
    return (codeLine.indexOf("+=") != -1 ||
        codeLine.indexOf("-=") != -1 ||
        codeLine.indexOf("++") != -1 ||
        codeLine.indexOf("--") != -1 ||
        codeLine.indexOf("*=") != -1 ||
        codeLine.indexOf("=") != -1 );
  }
  function whichVariableIsBeingChanged(codeLine){
    // hurrah for hideous code!
    var operators = ['+=', '-=', '++', '--', '*=', '/=', '='];
    var operator, i, cunt = operators.length;

    for (i = 0; i < cunt; i++) {
      operator = operators[i];
      if (codeLine.indexOf(operator) !== -1)
        return codeLine.split(operator)[0].trim()
    }

    return "";
  }

  // dealing with tentacles
  function isVarATentacle(varName){
    try{
      return cesspoolOfVariables[varName.trim()] != null
    }
    catch(err)
    {
      return false;
    }
  }

  function findTentacleValue(varName){
    var varObject = cesspoolOfVariables[varName.trim()];
    if (!varObject)
      return undefined;

    if (!isVarATentacle(varObject.current))
      return varObject.current;
    else
      return findTentacleValue(varObject.current);  // hey there recursion!
  }
}
