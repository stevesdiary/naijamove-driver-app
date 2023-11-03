// Conditionally add property to object using spread operator

const includeSalary = true;
const employee = { 
   id: 1, 
   name: "John",
   ...(includeSalary && {salary: 50000 })
};
console.table(employee)