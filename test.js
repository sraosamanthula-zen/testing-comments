// This JavaScript file is designed to process CSV files using the 'papaparse' library.
// It reads a CSV file, parses its content, and performs basic data analysis such as calculating
// the average of a numeric column. This functionality is useful for quickly analyzing CSV data
// in a Node.js environment.

const fs = require('fs');
const Papa = require('papaparse');

/**
 * Processes a CSV file to parse its content and perform basic data analysis.
 * 
 * @param {string} filePath - The path to the CSV file to be processed.
 */
function processCSV(filePath) {
    // Read the CSV file synchronously and store its content as a string
    const file = fs.readFileSync(filePath, 'utf8');
    
    // Parse the CSV content using PapaParse with headers and dynamic typing enabled
    const parsed = Papa.parse(file, { header: true, dynamicTyping: true });

    const data = parsed.data;
    console.log("📊 Total Rows:", data.length); // Log the total number of rows in the CSV

    const columns = Object.keys(data[0]); // Extract column names from the first row
    console.log("📈 Columns:", columns); // Log the column names

    // Example: Calculate the average of a numeric column
    const numericCol = columns[1]; // Assume the second column is numeric for demonstration
    const values = data.map(row => row[numericCol]).filter(v => typeof v === "number"); // Filter numeric values
    const avg = values.reduce((a, b) => a + b, 0) / values.length; // Calculate the average

    console.log(`Average of ${numericCol}:`, avg); // Log the average of the numeric column
}

// Example usage of the processCSV function
// processCSV('data.csv');