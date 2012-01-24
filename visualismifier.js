(function() {
  var EditSession = require('ace/edit_session').EditSession;
  var UndoManager = require('ace/undomanager').UndoManager;
  // var Mode = require('ace/mode/javascript').Mode;
  var Split = require('ace/split').Split;
  var theme = require('ace/theme-twilight');

  var worker = new Worker('tentacles.js');
  var split = new Split(document.getElementById('editor'), theme, 2);
  split.getEditor(1).setReadOnly(true);

  var editor = split.getEditor(0);
  editor.focus();
  // editor.getSession().setMode(Mode)

  editor.getSession().on('change', function(e) {
    var text = editor.getSession().getDocument().getValue();
    worker.postMessage(text);
  });

  worker.onmessage = function(msg) {
    split.getEditor(1).getSession().setValue(msg.data);
  }

  window.onresize = function() {
    split.resize();
  }

})()
