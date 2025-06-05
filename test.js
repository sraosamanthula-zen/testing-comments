/**
 * This file is responsible for processing CSV files to extract and analyze data.
 * It fulfills the business requirement of reading a CSV file, parsing its contents,
 * and performing basic data analysis such as calculating the average of a numeric column.
 */

const fs = require('fs'); // Import the file system module for reading files
const Papa = require('papaparse'); // Import the PapaParse library for parsing CSV files

/**
 * Processes a CSV file located at the given file path.
 * Parses the file, logs the total number of rows and columns,
 * and calculates the average of a specified numeric column.
 *
 * @param {string} filePath - The path to the CSV file to be processed.
 */
function processCSV(filePath) {
    // Read the CSV file synchronously as a UTF-8 encoded string
    const file = fs.readFileSync(filePath, 'utf8');
    
    // Parse the CSV file with headers and dynamic typing enabled
    const parsed = Papa.parse(file, { header: true, dynamicTyping: true });

    const data = parsed.data; // Extract the parsed data from the result
    console.log("📊 Total Rows:", data.length); // Log the total number of rows

    const columns = Object.keys(data[0]); // Extract column names from the first row
    console.log("📈 Columns:", columns); // Log the column names

    // Example: Calculate the average of a numeric column
    const numericCol = columns[1]; // Assume the second column is numeric for this example
    const values = data.map(row => row[numericCol]).filter(v => typeof v === "number"); // Filter numeric values
    const avg = values.reduce((a, b) => a + b, 0) / values.length; // Calculate the average

    console.log(`Average of ${numericCol}:`, avg); // Log the calculated average
}

// Example usage: Uncomment the line below to process a CSV file named 'data.csv'
// processCSV('data.csv');