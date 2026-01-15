Feature: GET /orders $filter

# Basic user story ... n
As a Truckmate API user, I would like to add a filter to my GET request in order to minimize unnecessary results 

# Acceptance tests

Background: 
Given the "tm" ART service is running 
And there are orders in the system 

# Tests should cover datatypes (int, string, date, boolean,enums), data values (null, small, large), 
# logic operators (AND, OR, NOT), comparison operators (eq, in, ne, gt, lt, ge, le)
# sub resources such as details/barcodes/altBarcode1
Scenario: $filter=orderId eq {{POSTED_orderId}}
Scenario: $filter=user2 eq 'yellow Chair'
Scenario: $filter=user1 eq 'fruit and roots'
Scenario: $filter=billNumber eq {{temp_billNumber}}
Scenario: $filter=status in ('ENTRY','AVAIL', 'ASSGN', 'PICKD', 'DELVD','COMPLETED','APPRVD', 'BILLD')
Scenario: $filter=status eq CANCL
Scenario: $filter=updatedTimestamp gt 2022-08-01
Scenario: $filter=serviceLevel eq 'REGULAR' AND not startZone IN (BCVAN,ABCAL)
Scenario: $filter=(traceNumbers/traceType eq 'B' )
Scenario: $filter=details/barcodes/altBarcode1 eq {{altBarcode}}
Scenario: $filter=pickUpDriver ne null
Scenario: $filter=interliners/orderInterlinerId gt {{resourceId}}
Scenario: $filter=details/barcodes/altBarcode1 ne null
Scenario: $filter=billToCode in ('TM', 'INTERMODAL')





