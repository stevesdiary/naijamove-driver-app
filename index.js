/**
 Generators
 * JavaScript also has a feature called generator functions.
These are similar, but without the promises.
When you define a function with function* (placing an asterisk after the
word function), it becomes a generator. When you call a generator, it returns
an iterator
 */
function* powers(n) {
   for (let current = n; ; current *= n) {
     yield current;
   }
 }
 
 for (let power of powers(3)) {
   if (power > 50) break;
   console.log(power);
 }