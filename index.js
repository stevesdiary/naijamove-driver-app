// Skip values in array destructuring

/**
 Destructuring means breaking down a complex structure into simpler parts. 
 Array destructuring is a way that allows us to extract an array’s value into new variables.
 Sometimes we don't need some values from the array means we want to skip those values. 
 During the destructuring arrays, if you want to skip some values, use an empty placeholder comma. 
 This is a clean way to skip values.
 */
const scores = [50, 40, 30, 80, 90, ];

const [, , ...restScores] = scores;

console.log(restScores); //[ 30, 80, 90 ]

// Filter with JSON.stringify

/*
The JSON.stringify() method converts a JavaScript object to a JSON string.
The 2nd parameter to JSON.stringify() is a replacer or filter that can be a function or an array.
When 2nd parameter is passed as an array, it works as a filter and includes only those properties in the JSON string which are defined in an array.
*/

const employee = {
   id: 1,
   name: "James",
   address: {
      city: "Lagos",
      state: "Lagos",
      country: "Nigeria"
   }
};
const filters = ["name", "address", "city", "country"];
filterEmployee = JSON.stringify(employee, filters);
console.log(filterEmployee); //{"name":"James","address":{"city":"Lagos","country":"Nigeria"}}