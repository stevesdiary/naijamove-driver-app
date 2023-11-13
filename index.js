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


const loadPokemon = (id, cb) => {
   fetch(`https://pokeapi.co/api/v2/pokemon/${id}`)
   .then(res => res.json())
   .then(data => {
      cb(data)
   })
}

loadPokemon(50, (pokemon)=> {
   console.log(pokemon)
})