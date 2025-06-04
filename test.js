// This JavaScript file is designed to read and process CSV files using the 'fs' and 'papaparse' libraries.
// It fulfills the business requirement of parsing CSV data, extracting column information, and calculating
// the average of a specified numeric column.

const fs = require('fs');
const Papa = require('papaparse');

/**
 * Processes a CSV file to extract data and perform basic analysis.
 * 
 * @param {string} filePath - The path to the CSV file to be processed.
 */
function processCSV(filePath) {
    // Read the file content synchronously as a UTF-8 string
    const file = fs.readFileSync(filePath, 'utf8');
    
    // Parse the CSV content using PapaParse with headers and dynamic typing enabled
    const parsed = Papa.parse(file, { header: true, dynamicTyping: true });

    const data = parsed.data;
    console.log("📊 Total Rows:", data.length);

    // Extract column names from the first row of data
    const columns = Object.keys(data[0]);
    console.log("📈 Columns:", columns);

    // Example: Calculate the average of a numeric column
    const numericCol = columns[1]; // Assumes the second column is numeric
    const values = data.map(row => row[numericCol]).filter(v => typeof v === "number");
    
    // Calculate the average of the numeric values
    const avg = values.reduce((a, b) => a + b, 0) / values.length;

    console.log(`Average of ${numericCol}:`, avg);
}

// Example usage: Uncomment the line below to process a CSV file named 'data.csv'
// processCSV('data.csv');