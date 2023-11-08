/**
Manipulating objects with loops can also be done with another variation of
the for loop, the 'for in loop'. The 'for in loop' is somewhat similar to the
'for of loop'. Again here, we need to specify a temporary name, also
referred to as a key, to store each property name in.
 */

let car = {
   model: "Camry",
   make: "Toyota",
   year: 2013,
   color: "Navy Blue"
};
for (let prop in car){
   console.log(car[prop]);
}
