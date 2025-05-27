const fs = require('fs');
const Papa = require('papaparse');

function processCSV(filePath) {
    const file = fs.readFileSync(filePath, 'utf8');
    const parsed = Papa.parse(file, { header: true, dynamicTyping: true });

    const data = parsed.data;
    console.log("📊 Total Rows:", data.length);

    const columns = Object.keys(data[0]);
    console.log("📈 Columns:", columns);

    // Example: average of a numeric column
    const numericCol = columns[1];
    const values = data.map(row => row[numericCol]).filter(v => typeof v === "number");
    const avg = values.reduce((a, b) => a + b, 0) / values.length;

    console.log(`Average of ${numericCol}:`, avg);
}

// Example: processCSV('data.csv');
