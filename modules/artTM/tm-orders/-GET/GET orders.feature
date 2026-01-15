Feature: GET /orders

# Basic user story ... not exactly the OpenAPI
As a Truckmate API user, I would like to retrieve orders, pickup requests (pre-orders), and quotes from the system.

# Acceptance tests

Background: 
Given the "tm" ART service is running 
And there are orders in the system 

Scenario: Get Orders - Success
Scenario: Get Orders - Fail
Scenario: Get Quotes - Success
Scenario: Get Quotes - Fail
Scenario: Get Pre-orders - Success
Scenario: Get Pre-orders - Fail

Scenario: GET Errors (400/401/403/404) ... feature itself
Scenario: Expand ... feature itself ... there are at least 20 existing scenarios in Postman
Scenario: orderBy ... feature itself? .. only 2 exmaples in postman, but could be more (e.g. by different data types)
#Scenario: $filter ... feature itself ... there are at least 20 existing scenarios in Postman
Scenario: $select ... feature itself ... there are at least 20 existing scenarios in Postman
Scenario: search by traceType & traceNumber ... feature itself
Scenario: limit & offset ... feature itself 
Scenario: Authorization - types ... feature itself





