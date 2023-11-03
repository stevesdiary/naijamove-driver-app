// Use includes to check for multiple criteria

const rgbColors = ["red", "green", "blue"];
const isRGBColor = (color) => {
   return rgbColors.includes(color);
};


//Remove duplicate from an array

const numbers = [1, 2, 4, 5, 2, 4, 9, 4, 11];
const colors = [ "red", "pink", "red", "blue", "black", "pink"];

const uniqueNumbers = [ ...new Set(numbers) ];
const uniqueColors = [...new Set(colors)];

console.log(uniqueColors, uniqueNumbers)