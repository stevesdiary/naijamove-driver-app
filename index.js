// Callback function
const array = ["Dary", "Sandra", "Wills", "James"]

const myForEach = (arr, cb) => {
   for (let i = 0; i < arr.length; i++) {
      const element = arr[i];
      cb(element)
   }
}

myForEach(array, (name) => {
   console.log(name);
})