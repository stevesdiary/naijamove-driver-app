// Check property exists in an object 
const employee = {
   id: 1,
   age: 24,
   name: 'Joan',
   salary: 50000
};

const isSalaryExist = 'salary' in employee;
console.log(isSalaryExist); //true

const isAgeExist = 'age' in employee;
console.log(isAgeExist); //true

const isGenderExist = 'gender' in employee;
console.log(isGenderExist); //false
