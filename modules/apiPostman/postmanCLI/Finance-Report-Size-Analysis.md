# Postman Report Size Analysis

## File Analyzed
**Name**: Finance-Functional-Tests-2025-10-02-09-59-53.json  
**Total Size**: 73.11 MB  
**Total Executions**: 532  
**Sample Size**: 100 executions analyzed

---

## Size Breakdown

| Component | Size (MB) | Percentage | Avg Per Execution |
|-----------|-----------|------------|-------------------|
| **Response Bodies** (stream.data) | 14.44 | 19.8% | 27.79 KB |
| **Response Headers** | 0.26 | 0.4% | 509 bytes |
| **Request Headers** | 0.37 | 0.5% | 735 bytes |
| **Other Metadata** | 4.16 | 5.7% | 8,193 bytes |
| **Meta/Summary** (overhead) | 0.00 | 0% | N/A |
| **JSON Formatting Overhead** | 53.89 | 73.7% | N/A |

---

## Key Findings

### The JSON Byte Array Problem

The massive **53.89 MB of JSON formatting overhead** (73.7% of the file) is caused by storing response bodies as byte arrays in JSON format.

**Why is this so large?**

When Postman/Newman stores response bodies, it converts them to JSON byte arrays like this:

```json
"stream": {
  "type": "Buffer",
  "data": [123, 34, 118, 101, 114, 115, 105, 111, 110, 34, 58, ...]
}
```

Each byte becomes:
- A 1-3 digit number
- A comma separator
- Optional whitespace

**Result**: A 1KB response (~1,024 bytes) becomes approximately **4-5KB** in JSON format!

**Example**:
- Actual response bodies: **14.44 MB**
- Same data in JSON byte array format: **~68 MB** (14.44 + 53.89)
- **Overhead multiplier: ~4.7x**

---

## Breakdown by Component

### Response Bodies: 19.8% (but 94% with JSON overhead)
- Raw data size: 14.44 MB
- With JSON byte array overhead: ~68 MB
- **This is the largest contributor to file size**

### Headers: 0.9% (negligible)
- Request headers: 0.37 MB
- Response headers: 0.26 MB
- Average per request: ~1.2 KB combined
- **Not worth omitting**

### Other Metadata: 5.7%
- Includes test results, assertions, timing, IDs, etc.
- **Essential for analysis - cannot omit**

---

## Recommendations

### 1. Omit Response Bodies (90%+ size reduction)
**Impact**: Reduce file from **73 MB to ~5-6 MB**

Since response bodies consume 94% of the file (with JSON overhead), omitting them provides the biggest benefit.

**Command**:
```bash
newman run collection.json --reporter-json-export output.json --suppress-exit-code
```

**Trade-off**: You lose the ability to extract version information from the `/version` endpoint response.

**Solution**: Run a separate version check before/after your main test run:
```powershell
$version = (Invoke-RestMethod -Uri "https://api.example.com/version").version
```

### 2. Keep Headers (minimal impact)
Headers only consume 0.9% of the file. Omitting them provides negligible benefit and may remove useful debugging information.

**Recommendation**: Keep headers in your reports.

### 3. Use Selective Detailed Reports
**Strategy**:
- **Daily runs**: Omit response bodies (small files, fast processing)
- **Investigation runs**: Keep everything (when you need to debug specific responses)
- **Comparison runs**: Omit response bodies (only test counts matter)

---

## File Size Projections

| Scenario | Estimated Size | Reduction |
|----------|----------------|-----------|
| **Current (full data)** | 73.11 MB | - |
| **Omit response bodies** | ~5-6 MB | 92% |
| **Omit headers only** | ~72 MB | 1% |
| **Omit both** | ~5 MB | 93% |

---

## Conclusion

The overwhelming contributor to file size is the JSON byte array representation of response bodies. For routine test runs where you only need test counts and timing data, omitting response bodies will make files:

- **12x smaller**
- **Faster to read/parse**
- **Faster to transfer/store**

The version information can be captured separately with a single API call, making this trade-off very worthwhile for regular monitoring.

---

**Analysis Date**: October 2, 2025  
**Tool**: `Measure-PostmanReportSize.ps1`

