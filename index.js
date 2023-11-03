// Avoid delete keyword
// Avoid a delete keyword to remove a property from an object. This way mutates the original object and hence leads to unpredictable behavior and makes debugging difficult.
// A better way to delete a property without mutating the original object is by using the rest operator (...). Use the rest operator (...) to create a new copy without the given property name.
const employee = {
   id : 1,
   name: "john",
   salary: 50000
};

const { salary, ...newEmployee } = employee;
console.log(newEmployee); //{ id: 1, name: 'john' }

// Use of falsy bouncer
const numbersWithFalsyValues = [7, null, 11, 17, false, NaN];

const numbers = numbersWithFalsyValues.filter(Boolean);
console.log(numbers); //[ 7, 11, 17 ]

const namesWithFalsyValues = ["Roy", null, "", undefined, "James"]
const names = namesWithFalsyValues.filter(Boolean);
console.log(names);
