// hint: click on the annotation on line 4, and set:
// key = 'b'
// array = ['a', 'b', 'c', 'd', 'e', 'f']

var binarySearch = function(key, array) {
  var low = 0;
  var high = array.length - 1;

  while (low <= high) {
    var mid = Math.floor((low + high) / 2);
    var value = array[mid];

    if (value < key) {
      low = mid + 1;
    }
    else if (value > key) {
      high = mid - 1;
    }
    else {
      return mid;
    }
  }

  return -1;
}

// or uncomment any of these: 
//var resultFound = binarySearch('b', ['a','b','c','d','e','f']);
//var resultNotFound = binarySearch('x', ['a','b','c','d','e','f']);
