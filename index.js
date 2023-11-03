//Pass function arguments as an object
/*
Parameters are part of a function definition. A JavaScript function can have any number of parameters. When we invoke a function and pass some values to that function, these values are called function arguments.
If a function has more than 1 parameter, it is hard to figure out what these arguments mean when the function is called. When you pass the arguments, the order is important.
A better way is to create a function with object (with properties) parameters like in the example. When we pass the argument contained in an object it is pretty
*/

//code
const createProduct = (name, price, category, brandId) => {
   //code to create product
};
createProduct("Product-1", 500, 1, 1);

//Better code

const createProduct =({name, price, categoryId, brandId}) => {
   //code to create product
};
createProduct({
   name: "Product-1",
   price: 500,
   categoryId: 1,
   brandId: 1
})