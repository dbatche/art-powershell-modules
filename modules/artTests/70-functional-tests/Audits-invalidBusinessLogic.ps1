# TEST 1 - audit field must be in body request
:>set-order -orderId 591315  -Updates @{pickUpBy='2021-07-07';audits=@(@{auditField='deliverBy';auditStatus='ADMIN';reasonCode='TEST';comment='Trying'})} -verbose
VERBOSE: PUT https://tde-truckmate.tmwcloud.com/cur/tm/orders/591315
VERBOSE: Body: {"pickUpBy":"2021-07-07","audits":[{"reasonCode":"TEST","auditField":"deliverBy","auditStatus":"ADMIN","comment":"Trying"}]}
VERBOSE: Performing the operation "Update order" on target "591315".
VERBOSE: Requested HTTP/1.1 PUT with 124-byte payload
VERBOSE: Received HTTP/1.1 440-byte response of content type application/json
Set-Order: API Returned an error

{
  "type": "https://developer.trimble.com/docs/truckmate/errors",
  "title": "Validation error(s) found. Please refer to the errors array for details.",
  "status": 400,
  "errors": [
    {
      "code": "invalidBusinessLogic",
      "description": "pickUpBy requires audits entry when auditing is enabled",
      "type": "https://developer.trimble.com/docs/truckmate/errors#:~:text=invalidBusinessLogic",
      "title": "pickUpBy requires audits entry when auditing is enabled"
    }
  ]
}

# TEST 2 - bad auditStatus code (not enabled as audit)
:>set-order -orderId 591315  -Updates @{pickUpBy='2021-07-07';audits=@(@{auditField='pickUpBy';auditStatus='ADMIN';reasonCode='TEST';comment='Trying'})} -verbose
VERBOSE: PUT https://tde-truckmate.tmwcloud.com/cur/tm/orders/591315
VERBOSE: Body: {"pickUpBy":"2021-07-07","audits":[{"reasonCode":"TEST","auditField":"pickUpBy","auditStatus":"ADMIN","comment":"Trying"}]}
VERBOSE: Performing the operation "Update order" on target "591315".
VERBOSE: Requested HTTP/1.1 PUT with 123-byte payload
VERBOSE: Received HTTP/1.1 446-byte response of content type application/json
Set-Order: API Returned an error

{
  "type": "https://developer.trimble.com/docs/truckmate/errors",
  "title": "Validation error(s) found. Please refer to the errors array for details.",
  "status": 400,
  "errors": [
    {
      "code": "invalidBusinessLogic",
      "description": "auditStatus is not a valid TruckMate Audit Status. [ADMIN]",
      "type": "https://developer.trimble.com/docs/truckmate/errors#:~:text=invalidBusinessLogic",
      "title": "auditStatus is not a valid TruckMate Audit Status. [ADMIN]"
    }
  ]
}


# TEST 3 - bad reasonCode
:>set-order -orderId 591315  -Updates @{pickUpBy='2021-07-07';audits=@(@{auditField='pickUpBy';auditStatus='ADMIN';reasonCode='TEST';comment='Trying'})} -verbose
VERBOSE: PUT https://tde-truckmate.tmwcloud.com/cur/tm/orders/591315
VERBOSE: Body: {"pickUpBy":"2021-07-07","audits":[{"reasonCode":"TEST","auditField":"pickUpBy","auditStatus":"ADMIN","comment":"Trying"}]}
VERBOSE: Performing the operation "Update order" on target "591315".
VERBOSE: Requested HTTP/1.1 PUT with 123-byte payload
VERBOSE: Received HTTP/1.1 440-byte response of content type application/json
Set-Order: API Returned an error

{
  "type": "https://developer.trimble.com/docs/truckmate/errors",
  "title": "Validation error(s) found. Please refer to the errors array for details.",
  "status": 400,
  "errors": [
    {
      "code": "invalidBusinessLogic",
      "description": "reasonCode is not a valid TruckMate Reason Code. [TEST]",
      "type": "https://developer.trimble.com/docs/truckmate/errors#:~:text=invalidBusinessLogic",
      "title": "reasonCode is not a valid TruckMate Reason Code. [TEST]"
    }
  ]
}


# TEST 4 SUCCESS (valid audit and reason code)
set-order -orderId 591315  -Updates @{pickUpBy='2021-07-07';audits=@(@{auditField='pickUpBy';auditStatus='ADMIN';reasonCode='SF1';comment='Trying'})} -verbose
