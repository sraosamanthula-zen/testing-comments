/**
 * This JavaScript file provides functionality to process CSV files using the PapaParse library.
 * It reads a CSV file, parses its contents, logs the number of rows and column names, 
 * and calculates the average of a specified numeric column. This can be used for data analysis 
 * or reporting purposes where quick insights from CSV data are required.
 */

const fs = require('fs'); // Import the filesystem module to read files
const Papa = require('papaparse'); // Import PapaParse for parsing CSV files

/**
 * Processes a CSV file and logs information about its contents.
 * 
 * @param {string} filePath - The path to the CSV file to be processed.
 */
function processCSV(filePath) {
    // Read the CSV file synchronously as a UTF-8 string
    const file = fs.readFileSync(filePath, 'utf8');
    
    // Parse the CSV file using PapaParse with header and dynamic typing enabled
    const parsed = Papa.parse(file, { header: true, dynamicTyping: true });

    // Extract parsed data
    const data = parsed.data;
    console.log("📊 Total Rows:", data.length); // Log the total number of rows

    // Extract column names from the first row of data
    const columns = Object.keys(data[0]);
    console.log("📈 Columns:", columns); // Log the column names

    // Example: Calculate the average of a numeric column
    const numericCol = columns[1]; // Assume the second column is numeric
    const values = data.map(row => row[numericCol]).filter(v => typeof v === "number"); // Filter numeric values
    const avg = values.reduce((a, b) => a + b, 0) / values.length; // Calculate average

    console.log(`Average of ${numericCol}:`, avg); // Log the average
}

// Example: processCSV('data.csv'); // Uncomment to process a file named 'data.csv' using the function above.