# ═══════════════════════════════════════════════════════════════════════════
# TM API ERROR CODE STANDARD - CONFIRMED EXAMPLES
# ═══════════════════════════════════════════════════════════════════════════
# Purpose: Real-world test cases for error codes confirmed in TM API testing
# Scope: All TM API endpoints (/orders, /trips, /userFieldsData, etc.)
# 
# IMPORTANT:
#   📚 For full list of official error codes → error-code-OFFICIAL-REFERENCE.ps1
#   ✅ This file contains only CONFIRMED working examples for TM API
#   ⚠️  If you see 'badRequest' in test results → file bug report (not official)
#
# Generated: 2025-10-13
# Updated: 2025-10-14 (cross-referenced with official documentation)
# API Version: 25.4.78.0
# Test Strategy: Actual working examples extracted from regression testing
# Primary Examples: /orders endpoint (all TM endpoints share same error codes)
# ═══════════════════════════════════════════════════════════════════════════

@(
    # ═══════════════════════════════════════════════════════════════
    # CONFIRMED ERROR CODES (from actual API responses)
    # ═══════════════════════════════════════════════════════════════
    
    # Error Code: noValidFields
    # When: Request body has no valid fields (empty object)
    # Context: Request body validation
    @{
        Name = 'ERROR CODE STANDARD: noValidFields'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'noValidFields'
        Body = @{}
    },
    
    # Error Code: exceedsMaxLength
    # When: String field exceeds maxLength constraint
    # Context: Request body field validation
    @{
        Name = 'ERROR CODE STANDARD: exceedsMaxLength'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'exceedsMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAAA' }  # Max 10, sent 11
    },
    
    # Error Code: invalidDateTime
    # When: Date/time field doesn't match pattern
    # Context: Request body field validation
    @{
        Name = 'ERROR CODE STANDARD: invalidDateTime'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidDateTime'
        Body = @{ pickUpBy = 'InvalidPatternValue'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    
    # Error Code: invalidEnum
    # When: Enum field has value not in allowed list
    # Context: Request body field validation
    @{
        Name = 'ERROR CODE STANDARD: invalidEnum'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ isCsa = 'INVALID_VALUE'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    
    # Error Code: invalidString
    # When: String field receives non-string type
    # Context: Request body field validation
    @{
        Name = 'ERROR CODE STANDARD: invalidString'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Body = @{ pickupDriver2 = 12345 }  # Number instead of string
    },
    
    # Error Code: invalidJsonArray
    # When: Required array field is missing or malformed
    # Context: Request body structure validation
    @{
        Name = 'ERROR CODE STANDARD: invalidJsonArray'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidJsonArray'
        Body = @{ 
            isExclusive = 'False'
            orderId = 583498
            exclusiveOverride = 'False'
            audits = @{ 
                comment = 'Missing reasonCode - should fail validation'
                auditField = 'pickUpBy'
                auditStatus = 'AUDIT'
            }
            pickUpBy = '2025-10-15T10:00:00'
        }
    },
    
    # Error Code: invalidJsonObject
    # When: Malformed JSON structure (e.g., array when object expected)
    # Context: JSON parsing / structure validation
    @{
        Name = 'ERROR CODE STANDARD: invalidJsonObject'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidJsonObject'
        RawBody = '[1, 2, 3]'  # Array instead of object
    },
    
    # ═══════════════════════════════════════════════════════════════
    # ⚠️  UNOFFICIAL ERROR CODES (RED FLAGS)
    # ═══════════════════════════════════════════════════════════════
    
    # Error Code: badRequest ⚠️ RED FLAG
    # When: This appeared in testing but is NOT in official documentation
    # Context: Unknown - needs investigation
    # Status: DO NOT USE as ExpectedErrorCode - this indicates API implementation issue
    # Action: If you get 'badRequest' as ActualErrorCode, file a bug report
    # @{
    #     Name = '⚠️  RED FLAG: badRequest (not official)'
    #     Method = 'PUT'
    #     Url = '/orders/583382?type=INVALID_ENUM_VALUE'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidQueryParameter'  # What it SHOULD return
    #     Body = @{ pickupDriver2 = 'AAAAAAAAAA' }
    #     Comment = 'If this returns badRequest instead, API needs fix'
    # },
    
    # Error Code: invalidQueryParameter
    # When: OData query parameter has invalid syntax
    # Context: Query parameter validation
    @{
        Name = 'ERROR CODE STANDARD: invalidQueryParameter'
        Method = 'PUT'
        Url = '/orders/583382?$select=invalid,,field'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidQueryParameter'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA' }
    }
    
    # ═══════════════════════════════════════════════════════════════
    # ADDITIONAL CONFIRMED ERROR CODES
    # ═══════════════════════════════════════════════════════════════
    
    # Error Code: missingRequiredField
    # When: Required field is missing (applies to BOTH body fields AND query parameters)
    # Context: Request validation
    # Status: CONFIRMED - Used for missing query parameters too!
    @{
        Name = 'ERROR CODE STANDARD: missingRequiredField'
        Method = 'GET'
        Url = '/userFieldsData'
        ExpectedStatus = 400
        ExpectedErrorCode = 'missingRequiredField'
        Body = $null
    }
    
    # ═══════════════════════════════════════════════════════════════
    # UNTESTED ERROR CODES (placeholders - need real examples)
    # ═══════════════════════════════════════════════════════════════
    
    # Error Code: invalidInteger
    # When: Integer field receives non-integer value
    # Context: Request body field validation
    # Status: NOT YET TESTED
    # @{
    #     Name = 'ERROR CODE STANDARD: invalidInteger'
    #     Method = 'PUT'
    #     Url = '/orders/583382'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidInteger'
    #     Body = @{ someIntegerField = 'not_a_number' }
    # },
    
    # Error Code: invalidDouble
    # When: Number field receives non-numeric value
    # Context: Request body field validation
    # Status: NOT YET TESTED
    # @{
    #     Name = 'ERROR CODE STANDARD: invalidDouble'
    #     Method = 'PUT'
    #     Url = '/orders/583382'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidDouble'
    #     Body = @{ someNumberField = 'not_a_number' }
    # },
    
    # Error Code: belowMinValue
    # When: Numeric field is below minimum constraint
    # Context: Request body field validation
    # Status: NOT YET TESTED - Orders API has no min value constraints
    # @{
    #     Name = 'ERROR CODE STANDARD: belowMinValue'
    #     Method = 'PUT'
    #     Url = '/orders/583382'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'belowMinValue'
    #     Body = @{ someNumberField = -1 }  # If min is 0
    # },
    
    # Error Code: exceedsMaxValue
    # When: Numeric field exceeds maximum constraint
    # Context: Request body field validation
    # Status: NOT YET TESTED - Orders API has no max value constraints
    # @{
    #     Name = 'ERROR CODE STANDARD: exceedsMaxValue'
    #     Method = 'PUT'
    #     Url = '/orders/583382'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'exceedsMaxValue'
    #     Body = @{ someNumberField = 999999 }  # If max is 1000
    # },
    
    # NOTE: missingRequiredParameter does NOT exist!
    # The API uses 'missingRequiredField' for BOTH:
    #   - Missing required fields in request body
    #   - Missing required query parameters
    # See the confirmed 'missingRequiredField' example above.
    
    # Error Code: malformedJson
    # When: JSON syntax is invalid (unclosed braces, etc.)
    # Context: JSON parsing
    # Status: NOT YET TESTED - Need to confirm actual error code
    # Note: Might return 'invalidJsonObject' instead
    # @{
    #     Name = 'ERROR CODE STANDARD: malformedJson'
    #     Method = 'PUT'
    #     Url = '/orders/583382'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'malformedJson'
    #     RawBody = '{ "field": "value"'  # Unclosed brace
    # },
    
    # Error Code: invalidMaxLength (PATH PARAMETER)
    # When: Path parameter string exceeds length
    # Context: Path parameter validation
    # Status: NOT YET TESTED - Orders uses integer orderId, not string
    # Note: Postman shows this for path params, might be different API
    # @{
    #     Name = 'ERROR CODE STANDARD: invalidMaxLength (path param)'
    #     Method = 'GET'
    #     Url = '/orders/VERY_LONG_STRING_ID_HERE'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidMaxLength'
    #     Body = $null
    # }
)

# ═══════════════════════════════════════════════════════════════
# USAGE NOTES
# ═══════════════════════════════════════════════════════════════
#
# 1. This standard applies to ALL TM API endpoints:
#    /tm/orders, /tm/trips, /tm/userFieldsData, etc.
# 2. Use these tests as templates for New-ContractTests error code mapping
# 3. Uncomment placeholder tests when real examples are found
# 4. Test runner will skip commented tests automatically
# 5. Create similar files for other APIs:
#    - error-code-standard-finance-api.ps1
#    - error-code-standard-masterdata-api.ps1
#    - error-code-standard-visibility-api.ps1 (if different)
#
# ═══════════════════════════════════════════════════════════════

