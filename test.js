/**
 * This file is designed to read and process CSV files using Node.js.
 * It fulfills the business requirement of parsing CSV data, extracting information,
 * and performing basic data analysis, such as calculating the average of a numeric column.
 */

const fs = require('fs'); // Import the filesystem module to read files
const Papa = require('papaparse'); // Import the papaparse library to parse CSV files

/**
 * Processes a CSV file to extract data and perform basic analysis.
 * 
 * @param {string} filePath - The path to the CSV file to be processed.
 */
function processCSV(filePath) {
    // Read the entire file content as a UTF-8 string
    const file = fs.readFileSync(filePath, 'utf8');
    
    // Parse the CSV file content with header and dynamic typing enabled
    const parsed = Papa.parse(file, { header: true, dynamicTyping: true });

    const data = parsed.data; // Extract the parsed data from the result
    console.log("📊 Total Rows:", data.length); // Log the total number of rows in the CSV

    const columns = Object.keys(data[0]); // Get the column names from the first row
    console.log("📈 Columns:", columns); // Log the column names

    // Example: Calculate the average of a numeric column
    const numericCol = columns[1]; // Assume the second column is numeric
    const values = data.map(row => row[numericCol]).filter(v => typeof v === "number"); // Extract numeric values
    const avg = values.reduce((a, b) => a + b, 0) / values.length; // Calculate the average

    console.log(`Average of ${numericCol}:`, avg); // Log the average value
}

// Example usage: Uncomment the line below to process a CSV file named 'data.csv'
// processCSV('data.csv');