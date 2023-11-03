// Power of JSON.stringify replacer parameter

/**
 * The JSON.stringify() method converts a JavaScript object to a JSON string.
The 2nd parameter to JSON.stringify() is a replacer or filter that can be a function or array.
When 2nd parameter is passed as a replacer function, it alters the behavior of the stringification process. 
As a function, it takes two parameters, the key and the value being stringified.
 */


const employee = {
   id: 1,
   name: "Joe",
   salary: 30_000
};
const doubleSalary =  (key, value) => {
   return key === "salary" ? value * 2 : value;
};

const result = JSON.stringify(employee, doubleSalary);
console.log(result); //{"id":1,"name":"Joe","salary":60000}