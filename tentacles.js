self.onmessage = function(msg) {
  try {
    var lines = msg.data.split('\n');
    var vars = [], code = '', display = '';

    var varRegex = /\s*var\s*(\w+|\d*)/;

    var i = 0, count = lines.length, line, matches;
    for(; i < count; i++) {
      line = lines[i];
      code += line + ';'

      matches = line.match(varRegex);
      if (matches.length > 1) {
        vars.push(matches[1]);
        display += matches[1] + " = " + (new Function(line + ';return ' + matches[1])());
      }

      display += '\n'
    }

    self.postMessage(display);
  } catch (e) {}
}
