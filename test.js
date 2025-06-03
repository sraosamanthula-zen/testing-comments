/**
 * This JavaScript file is designed to process CSV files using the 'papaparse' library.
 * It reads a CSV file, parses its contents, and performs basic data analysis such as calculating the average of a numeric column.
 * This functionality is useful for applications that need to extract and analyze structured data from CSV files.
 */

const fs = require('fs'); // Import the file system module to read files
const Papa = require('papaparse'); // Import the papaparse library for parsing CSV files

/**
 * Processes a CSV file, extracts its data, and performs basic analysis.
 * @param {string} filePath - The path to the CSV file to be processed.
 */
function processCSV(filePath) {
    // Read the CSV file synchronously as a UTF-8 encoded string
    const file = fs.readFileSync(filePath, 'utf8');
    
    // Parse the CSV file content with headers and dynamic typing enabled
    const parsed = Papa.parse(file, { header: true, dynamicTyping: true });

    const data = parsed.data; // Extract the parsed data
    console.log("📊 Total Rows:", data.length); // Log the total number of rows

    const columns = Object.keys(data[0]); // Extract column names from the first row
    console.log("📈 Columns:", columns); // Log the column names

    // Example: Calculate the average of a numeric column
    const numericCol = columns[1]; // Assume the second column is numeric
    const values = data.map(row => row[numericCol]).filter(v => typeof v === "number"); // Filter numeric values
    const avg = values.reduce((a, b) => a + b, 0) / values.length; // Calculate the average

    console.log(`Average of ${numericCol}:`, avg); // Log the calculated average
}

// Example usage: Uncomment to process a CSV file
// processCSV('data.csv');