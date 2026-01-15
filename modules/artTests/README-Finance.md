# Finance API PowerShell Test Runner

Quick and simple PowerShell-based API testing for the Finance API.

## 🚀 Quick Start

### Basic Usage

```powershell
# Run all apInvoices tests
.\Run-FinanceApiTests.ps1 -Resource apInvoices | Format-Table

# Verbose output
.\Run-FinanceApiTests.ps1 -Resource apInvoices -Verbose

# Different environment
.\Run-FinanceApiTests.ps1 -Resource apInvoices -BaseUrl https://prod.tmwcloud.com/fin/finance -Token your_token
```

### Output Format

```
Result Name                          Method Expected Actual Time    BodyPreview
------ ----                          ------ -------- ------ ----    -----------
✔      GET all apInvoices            GET    200      200    245ms   {"apInvoices":[{"apInvoiceId":2,"vendorId":"VENDOR"...
✔      GET apInvoices - pagination   GET    200      200    189ms   {"apInvoices":[...
✔      Filter - eq (equals)          GET    200      200    234ms   {"apInvoices":[...
✘      limit - negative              GET    400      200    123ms   {"error":"Invalid parameter"...
```

## 📁 Files

- **`Run-FinanceApiTests.ps1`** - Main test runner
- **`requests_finance_apInvoices.ps1`** - apInvoices test definitions
- **`Run-ApiTests-IRM.ps1`** - Generic test runner (original)

## ✍️ Writing Tests

Create a requests file: `requests_finance_[resource].ps1`

### Format

```powershell
@(
    @{ Name = 'Test name'; 
       Method = 'GET'; 
       Url = '/endpoint'; 
       ExpectedStatus = 200 },
    
    @{ Name = 'Test with query params'; 
       Method = 'GET'; 
       Url = '/endpoint?param=value'; 
       ExpectedStatus = 200 },
    
    @{ Name = 'POST test'; 
       Method = 'POST'; 
       Url = '/endpoint'; 
       ExpectedStatus = 201;
       Body = @{
           field1 = 'value1'
           field2 = 100
       } }
)
```

### Test Properties

| Property | Required | Description | Example |
|----------|----------|-------------|---------|
| `Name` | Yes | Test description | `'GET all invoices'` |
| `Method` | Yes | HTTP method | `'GET'`, `'POST'`, `'PUT'`, `'DELETE'` |
| `Url` | Yes | Endpoint path (relative or absolute) | `'/apInvoices'` |
| `ExpectedStatus` | Yes | Expected HTTP status code | `200`, `400`, `404` |
| `Body` | No | Request body (hashtable) | `@{ field = 'value' }` |

## 📊 Test Categories

### Happy Path Tests
```powershell
@{ Name = 'GET all apInvoices'; 
   Method = 'GET'; 
   Url = '/apInvoices'; 
   ExpectedStatus = 200 }
```

### Validation Tests
```powershell
@{ Name = 'limit - negative'; 
   Method = 'GET'; 
   Url = '/apInvoices?limit=-10'; 
   ExpectedStatus = 400 }
```

### Filter Tests (OData)
```powershell
@{ Name = 'Filter - equals'; 
   Method = 'GET'; 
   Url = '/apInvoices?$filter=vendorId eq ''VENDOR'''; 
   ExpectedStatus = 200 }
```

### POST Tests
```powershell
@{ Name = 'Create invoice'; 
   Method = 'POST'; 
   Url = '/apInvoices'; 
   ExpectedStatus = 201;
   Body = @{
       vendorId = 'VENDOR'
       vendorBillAmount = 100.00
   } }
```

## 🎯 Examples

### Run Tests and Filter Results

```powershell
# Show only failures
.\Run-FinanceApiTests.ps1 -Resource apInvoices | Where-Object { $_.Result -eq '✘' } | Format-Table

# Show only validation tests
.\Run-FinanceApiTests.ps1 -Resource apInvoices | Where-Object { $_.Name -like '*validation*' } | Format-Table

# Export to CSV
.\Run-FinanceApiTests.ps1 -Resource apInvoices | Export-Csv results.csv -NoTypeInformation

# Export to HTML
.\Run-FinanceApiTests.ps1 -Resource apInvoices | ConvertTo-Html | Out-File results.html
```

### Pipe to Different Formats

```powershell
# Table view (default)
.\Run-FinanceApiTests.ps1 -Resource apInvoices | Format-Table

# List view (more detail)
.\Run-FinanceApiTests.ps1 -Resource apInvoices | Format-List

# Grid view (interactive)
.\Run-FinanceApiTests.ps1 -Resource apInvoices | Out-GridView

# JSON output
.\Run-FinanceApiTests.ps1 -Resource apInvoices | ConvertTo-Json | Out-File results.json
```

## 🔧 Advanced Usage

### Custom Token

```powershell
$myToken = 'your_bearer_token_here'
.\Run-FinanceApiTests.ps1 -Resource apInvoices -Token $myToken
```

### Different Environment

```powershell
# Development
.\Run-FinanceApiTests.ps1 -Resource apInvoices -BaseUrl https://dev.tmwcloud.com/fin/finance

# Staging
.\Run-FinanceApiTests.ps1 -Resource apInvoices -BaseUrl https://stage.tmwcloud.com/fin/finance

# Production
.\Run-FinanceApiTests.ps1 -Resource apInvoices -BaseUrl https://prod.tmwcloud.com/fin/finance
```

### Custom Requests File

```powershell
.\Run-FinanceApiTests.ps1 -Resource apInvoices -RequestsFile .\my_custom_tests.ps1
```

## 📈 Comparison: PowerShell vs JavaScript Frameworks

| Feature | PowerShell | Vitest/Playwright |
|---------|-----------|-------------------|
| **Setup Time** | ⚡ Instant | ~2 minutes |
| **Learning Curve** | Easy | Medium |
| **Speed** | ~15s | ~4-10s |
| **Verbosity** | Medium | Low |
| **CI/CD Integration** | Good | Excellent |
| **Watch Mode** | ❌ No | ✅ Yes (Vitest) |
| **Rich Reporting** | Basic | Advanced |
| **Debugging** | PowerShell ISE | VS Code |
| **Platform** | Windows only | Cross-platform |
| **Best For** | Quick checks | Full test suites |

## 💡 When to Use PowerShell Tests

✅ **Good for:**
- Quick smoke tests
- Manual testing during development
- Simple validation tests
- Windows-only environments
- Rapid prototyping of tests
- One-off test scenarios

❌ **Not ideal for:**
- Complex test scenarios
- CI/CD pipelines (prefer JS frameworks)
- Cross-platform requirements
- Advanced assertions
- Test-driven development (no watch mode)

## 🔄 Migration to JavaScript

Your PowerShell tests can be easily converted to Vitest/Playwright:

**PowerShell:**
```powershell
@{ Name = 'GET all apInvoices'; 
   Method = 'GET'; 
   Url = '/apInvoices'; 
   ExpectedStatus = 200 }
```

**Vitest:**
```javascript
test('GET all apInvoices', async () => {
  const client = createAuthenticatedClient();
  const response = await client.get('/apInvoices');
  expect(response.status).toBe(200);
});
```

## 🤝 Best Practice: Use Both!

1. **PowerShell** - Quick manual testing
2. **Vitest/Playwright** - Automated CI/CD testing

They complement each other perfectly:
- Use PowerShell for quick checks during development
- Use JavaScript frameworks for comprehensive automated testing

## 📚 Related Files

- JavaScript version: `C:\git\truckmate\tests\api-vitest\`
- Playwright version: `C:\git\truckmate\tests\api\`
- Original runner: `.\Run-ApiTests-IRM.ps1`

