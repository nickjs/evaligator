// hint: try adding more elements to the arr array
// or changing the bounds of the for loop

var a = 0;
var b = a;

var arr = ['tuna', 'fish'];
var allTheOddThings = '';

for (var i = 0; i < 2 * arr.length; i++) {
  b += i;
  if (b % 2 != 0) {
    allTheOddThings += b + ', ';
  }
}
