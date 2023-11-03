//Use Array.some to check occurrence in array
/*
If we want to check only occurrence means value exist or not then use Array.some instead of Array.find.
The some() method checks if any array items pass a test implemented by the provided function. If the function returns true, some() returns true and stops.
The some() method does not change the original array.
*/
const assets = [
   {id: 1, title: "V-1", type: "video"},
   {id: 2, title: "V-2", type: "video"},
   {id: 3, title: "A-3", type: "audio"}
];

const hasVideoAsset = assets.some(asset => asset.type === "video");
console.log(hasVideoAsset); //true