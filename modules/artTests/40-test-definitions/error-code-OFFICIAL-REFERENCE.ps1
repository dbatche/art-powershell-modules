# ═══════════════════════════════════════════════════════════════════════════
# OFFICIAL TRUCKMATE API ERROR CODE REFERENCE
# ═══════════════════════════════════════════════════════════════════════════
# Source: https://developer.trimble.com/docs/truckmate/errors
# Last Updated: 2025-01-14
#
# PURPOSE:
#   This file documents ALL official TruckMate API error codes from the
#   developer documentation. Use this as a reference when creating tests.
#
# USAGE:
#   - These codes apply to ALL TruckMate APIs (TM, Finance, MasterData)
#   - Create API-specific standard files with actual working examples
#   - When you get an unexpected error code, check this reference first
#
# VALIDATION ORDER (Fail Fast Principle):
#   1. Path Validation
#   2. Authentication & Authorization  
#   3. Query String Validation
#   4. OpenAPI Schema Validation (most contract tests hit here)
#   5. Business Logic & Database Validation
#
# ═══════════════════════════════════════════════════════════════════════════

@(
    # ═══════════════════════════════════════════════════════════════════════════
    # NON-400 STATUS CODES (Infrastructure/System Level)
    # ═══════════════════════════════════════════════════════════════════════════
    
    # Status: 301 | Code: movedPermanently
    # Message: The endpoint has been moved permanently. Please refer to the 
    #          OpenAPI Specification for a list of supported methods and endpoints.
    
    # Status: 401 | Code: unauthorized
    # Message: The supplied authentication credentials are not valid.
    
    # Status: 403 | Code: forbidden
    # Message: The supplied authentication credentials are not sufficient to access 
    #          the resource, or perform the requested operation.
    
    # Status: 404 | Code: resourceNotFound
    # Message: Not found. The server has not found anything matching the Request-URI.
    
    # Status: 405 | Code: methodNotAllowed
    # Message: Method not allowed. Please refer to the OpenAPI Specification for a 
    #          list of supported methods and endpoints.
    
    # Status: 409 | Code: resourceConflict
    # Message: The supplied authentication credentials are not valid.
    
    # Status: 420 | Code: licenseNotAvailable
    # Message: License not available.
    
    # Status: 429 | Code: tooManyRequests
    # Message: Too many requests.
    
    # Status: 500 | Code: serverError
    # Message: Server error.
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 400 STATUS CODES - OPENAPI SCHEMA VALIDATION (Layer 4)
    # ═══════════════════════════════════════════════════════════════════════════
    
    # Error Code: belowMinValue
    # Message: {field} cannot be less than the minimum value of {value}.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending quantity = -5 when min is 0
    # @{
    #     Name = 'OFFICIAL: belowMinValue'
    #     Method = 'PUT'
    #     Url = '/endpoint'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'belowMinValue'
    #     Body = @{ numericField = -1 }  # If min is 0
    # }
    
    # Error Code: exceedsMaxLength
    # Message: {field} is expected to not exceed maximum length of {value} character(s).
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending a 50-char string when maxLength is 10
    # CONFIRMED - See error-code-standard-tm-api.ps1
    
    # Error Code: invalidJsonArray
    # Message: {field} is expected to be a valid JSON array.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending object when array expected, or malformed array syntax
    # CONFIRMED - See error-code-standard-tm-api.ps1
    
    # Error Code: invalidJsonObject
    # Message: {field} is expected to be a valid JSON object.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending array when object expected, or malformed object syntax
    # CONFIRMED - See error-code-standard-tm-api.ps1
    
    # Error Code: noValidFields
    # Message: No valid fields sent with the request. Please refer to the OpenAPI 
    #          Specification for a list of supported fields.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending all invalid field names, or invalid type for path parameter
    # CONFIRMED - See error-code-standard-tm-api.ps1
    
    # Error Code: invalidJsonValue
    # Message: {field} is expected to satisfy one of the following conditions: {oneOf conditions}.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Field defined with oneOf/anyOf schema and value doesn't match any option
    # @{
    #     Name = 'OFFICIAL: invalidJsonValue'
    #     Method = 'POST'
    #     Url = '/endpoint'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidJsonValue'
    #     Body = @{ fieldWithOneOf = 'invalid_option' }
    # }
    
    # Error Code: invalidDateTime
    # Message: {field} is expected to be a valid datetime string (yyyy-MM-ddThh:mm:ss).
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending "2025-13-45" or "not-a-date" for datetime field
    # CONFIRMED - See error-code-standard-tm-api.ps1
    
    # Error Code: invalidDate
    # Message: {field} is expected to be a valid date string (yyyy-MM-dd).
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending "2025-13-45" or "01/14/2025" for date field
    # @{
    #     Name = 'OFFICIAL: invalidDate'
    #     Method = 'PUT'
    #     Url = '/endpoint'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidDate'
    #     Body = @{ dateField = '01/14/2025' }  # Wrong format
    # }
    
    # Error Code: invalidTime
    # Message: {field} is expected to be a valid time string (hh:mm:ss).
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending "25:99:99" or "3:30pm" for time field
    # @{
    #     Name = 'OFFICIAL: invalidTime'
    #     Method = 'PUT'
    #     Url = '/endpoint'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidTime'
    #     Body = @{ timeField = '25:99:99' }  # Invalid time
    # }
    
    # Error Code: invalidPattern
    # Message: {field} does not match the pattern defined in the OpenAPI specification.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Field has regex pattern constraint (e.g., phone number format)
    # @{
    #     Name = 'OFFICIAL: invalidPattern'
    #     Method = 'PUT'
    #     Url = '/endpoint'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidPattern'
    #     Body = @{ patternField = 'invalid-format' }  # Doesn't match pattern
    # }
    
    # Error Code: invalidFormat
    # Message: {field} is expected to be in the valid format.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Generic format violation (e.g., email, uri, uuid formats)
    # @{
    #     Name = 'OFFICIAL: invalidFormat'
    #     Method = 'PUT'
    #     Url = '/endpoint'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidFormat'
    #     Body = @{ emailField = 'not-an-email' }  # Invalid email format
    # }
    
    # Error Code: invalidDouble
    # Message: {field} is expected to be a valid double.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending "not-a-number" for a double/number field
    # @{
    #     Name = 'OFFICIAL: invalidDouble'
    #     Method = 'PUT'
    #     Url = '/endpoint'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidDouble'
    #     Body = @{ doubleField = 'not-a-number' }
    # }
    
    # Error Code: invalidEnum
    # Message: {field} is expected to be a value of {enum values}.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending "INVALID" when enum is ["ACTIVE", "INACTIVE"]
    # CONFIRMED - See error-code-standard-tm-api.ps1
    
    # Error Code: invalidInteger
    # Message: {field} is expected to be a valid integer.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending "not-a-number" for an integer field
    # NOTE: In testing, we got 'noValidFields' instead - context may matter
    # @{
    #     Name = 'OFFICIAL: invalidInteger'
    #     Method = 'PUT'
    #     Url = '/endpoint'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidInteger'
    #     Body = @{ integerField = 'not-a-number' }
    # }
    
    # Error Code: invalidString
    # Message: {field} is expected to be a valid string.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Sending number/boolean when string expected
    # CONFIRMED - See error-code-standard-tm-api.ps1
    
    # Error Code: missingRequiredField
    # Message: {field} is a required field.
    # Layer: 4 - OpenAPI Schema Validation
    # Example scenario: Missing required body field OR required query parameter
    # NOTE: Used for BOTH body fields AND query parameters (no "missingRequiredParameter")
    # CONFIRMED - See error-code-standard-tm-api.ps1
    
    # Error Code: invalidQueryParameter
    # Message: Query parameter {parameter} is not supported for this endpoint.
    # Layer: 3 - Query String Validation
    # Example scenario: Sending ?unsupported=value when endpoint doesn't support it
    # CONFIRMED - See error-code-standard-tm-api.ps1
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 400 STATUS CODES - BUSINESS LOGIC & DATABASE VALIDATION (Layer 5)
    # ═══════════════════════════════════════════════════════════════════════════
    
    # Error Code: invalidDBValue
    # Message: {field} is not a valid {label}.
    # Layer: 5 - Database Value Validation
    # Example scenario: Sending customerId=999 when that ID doesn't exist in database
    # NOTE: Requires SQL lookup - only triggered after OpenAPI validation passes
    # @{
    #     Name = 'OFFICIAL: invalidDBValue'
    #     Method = 'PUT'
    #     Url = '/endpoint'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidDBValue'
    #     Body = @{ customerId = 999999 }  # Non-existent ID
    # }
    
    # Error Code: invalidBusinessLogic
    # Message: This will be unique depending on the business use case, this could be 
    #          related to configuration options or other logic.
    # Layer: 5 - Business Logic Validation
    # Example scenario: Violating business rules (e.g., "Cannot modify cancelled order")
    # NOTE: Requires business rule evaluation - only after OpenAPI & DB validation
    # @{
    #     Name = 'OFFICIAL: invalidBusinessLogic'
    #     Method = 'PUT'
    #     Url = '/orders/583382'
    #     ExpectedStatus = 400
    #     ExpectedErrorCode = 'invalidBusinessLogic'
    #     Body = @{ orderStatus = 'SHIPPED' }  # Violates business rule
    # }
    
    
    # ═══════════════════════════════════════════════════════════════════════════
    # UNOFFICIAL / NON-STANDARD ERROR CODES
    # ═══════════════════════════════════════════════════════════════════════════
    
    # Error Code: badRequest ⚠️ RED FLAG
    # Status: NOT in official documentation
    # Interpretation: This indicates an API implementation issue that needs correction
    # When you see this: File a bug report with the API team
    # DO NOT use this as ExpectedErrorCode in tests - it's a failure indicator
    # 
    # If a test returns 'badRequest' as ActualErrorCode:
    #   → The API should return a more specific error code
    #   → Check which validation layer should have caught this
    #   → Report to API team for proper error code implementation
)

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY STATISTICS
# ═══════════════════════════════════════════════════════════════════════════
# Total Official Error Codes: 28
#   - Non-400 Status Codes: 9
#   - 400 OpenAPI/Query Validation: 17
#   - 400 Business/Database Validation: 2
#
# Confirmed in Testing: 9 (50% of 400 codes)
#   ✓ exceedsMaxLength
#   ✓ invalidJsonArray
#   ✓ invalidJsonObject
#   ✓ noValidFields
#   ✓ invalidDateTime
#   ✓ invalidEnum
#   ✓ invalidString
#   ✓ missingRequiredField
#   ✓ invalidQueryParameter
#
# Need Real Examples: 10
#   • belowMinValue
#   • invalidJsonValue
#   • invalidDate
#   • invalidTime
#   • invalidPattern
#   • invalidFormat
#   • invalidDouble
#   • invalidInteger (tested but got noValidFields)
#   • invalidDBValue
#   • invalidBusinessLogic
# ═══════════════════════════════════════════════════════════════════════════

