//Form table with nested for loop
let myTable = [];
for (let i = 0; i < 3; i++){
   myTable.push([]);
   for (let j = 0; j < 7; j++){
      myTable[i].push(j);
   }
}
console.table(myTable)
