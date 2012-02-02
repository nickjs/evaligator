(function() {
  var EditSession = require('ace/edit_session').EditSession;
  var UndoManager = require('ace/undomanager').UndoManager;
  // var Mode = require('ace/mode/javascript').Mode;
  var Split = require('ace/split').Split;
  var theme = require('ace/theme-twilight');

  var split = new Split(document.getElementById('editor'), theme, 2);
  split.getEditor(1).setReadOnly(true);

  var editor = split.getEditor(0);
  editor.focus();
  // editor.getSession().setMode(Mode)

  window.onresize = function() {
    split.resize();
  }

  editor.getSession().on('change', function(e) {
    var text = editor.getSession().getDocument().getValue();
    var tree = Parser.Parser.parse(text);
    var result = {source: ''};

    walkTheTreeBitches(tree, result);

    split.getEditor(1).getSession().setValue(result.source);
  });

  var nicksPoorlyNamedMap = {
    VariableDeclaration: function(node, source)
    {
      var identifier = findNodesChildWithName(node, 'Identifier');
      source.source += ' ' + identifier + ' = ' + new Function(node.source + ';return ' + identifier + ';')() + '\n';
    },

    ForStatement: function(node, source)
    {

    }
  };

  function walkTheTreeBitches(tree, source)
  {
    var children = tree.children;
    if (!children) return;

    var count = children.length, i, child;
    for (i = 0; i < count; i++)
    {
        child = children[i];
        if (child.name in nicksPoorlyNamedMap)
          nicksPoorlyNamedMap[child.name](child, source);

        walkTheTreeBitches(children[i], source);
    }
  }

  function findNodesChildWithName(node, name)
  {
    var children = node.children, count = children.length, child;
    for (var i = 0; i < count; i++)
    {
      child = children[i];
      if (child.name === name)
        return node.source.substr(child.range.location, child.range.length);
    }
  }

})()
