Feature: In Orders API, disallow accessorial charge code

	The Orders API should match what the UI does when adding an accessorial charge code to an order. 
	The API should not allow adding an accessorial charge code if it is inactive, a vendor code, or a custom code only. 
	The API should also not allow adding an accessorial charge code if it is disallowed according to the client's settings for the extra charge.


	Background:
		Given a client (e.g. 'TM')
		And a desired accessorial charge that you want to add (e.g. 'FLATMANUAL')

	Rule: Unsuccessful Add Accessorial Scenarios based on Header [ACHARGE_CODE]

		Scenario: Accessorial is Inactive
			Given FLATMANUAL has its "Not Active" flag set to True
				"""
				PUT to /masterData/aChargeCodes/FLATMANUAL
				{
				"notActive":"True"
				}
				"""
			When a request is made to add FLATMANUAL in Orders API
			Then it cannot be applied to the order
			And there is an error
				"""
				{
					"code": "badRequest",
					"description": "aChargeCode(FLATMANUAL) is not valid: either aChargeCode is not valid to be used,
					 or currencyCode does not match the order"
				}
				"""

		# Note: In the UI, the system has this warning
		# "Warning: There are still some active rules on this code, these rules will still be used unless the end date is changed"
		# However, it doesn't appear in UI selection list though and doesn't work with auto-assign ... so what does this warning mean?

		Scenario: Accessoiral is a Vendor Code
			Given FLATMANUAL is a vendor code
				"""
				PUT to /masterData/aChargeCodes/FLATMANUAL
				{
				"vendorCode":"True"
				}
				"""
			When a request is made to add FLATMANUAL in Orders API
			Then it cannot be applied to the order
			And there is an error
				"""
				{
					"code": "badRequest",
					"description": "aChargeCode(FLATMANUAL) is not valid: either aChargeCode is not valid to be used,
					 or currencyCode does not match the order"
				}
				"""

		Scenario: Accessorial is "Custom Code Only"
			Given FLATMANUAL is marked as "Custom Code Only"
				"""
				PUT to /masterData/aChargeCodes/FLATMANUAL
				{
				"customCodeOnly": "True"
				}
				"""
			When a request is made to add FLATMANUAL in Orders API
			Then it cannot be applied to the order
			And there is an error
				"""
				{
					"code": "badRequest",
					"description": "aChargeCode(FLATMANUAL) is not valid: either aChargeCode is not valid to be used,
					 or currencyCode does not match the order"
				}
				"""
	Rule: Unsuccessful Add Accessorial Scenarios based on Substitution [ACHARGE_CODE_SUBSTITUTE_HIST]

		Scenario: Accessorial is Disallowed
			Given FLATMANUAL has its Substitute code set to blank (Disalllowed)
				"""
				PUT to /masterData/clients/TM/aChargeSubstitutes/FLATMANUAL
				{
				"newAChargeId": ""
				}
				"""
			When a request is made to add FLATMANUAL in Orders API
			Then it cannot be applied to the order
			And there is an error
				"""
				{
					"code": "badRequest",
					"description": "aChargeCode(FLATMANUAL) is not valid: either aChargeCode is not valid to be used, 
					or currencyCode does not match the order"
				}
				"""

	Rule: Successful Substitution 

		Scenario: Normal Substitution
			Given FLAT_SUB is marked as 'Custom Code Only' (which enables it to be a substitute code)
				"""
				PUT to /masterData/aChargeCodes/FLAT_SUB
				{
				"customCodeOnly": "True"
				}
				"""
			And FLATMANUAL is set to have substitute code = FLAT_SUB
				"""
				PUT to /masterData/clients/TM/aChargeSubstitutes/FLATMANUAL
				{
				"newAChargeId": "FLAT_SUB"
				}
				"""
			When a request is made to add FLATMANUAL in Orders API
			Then the substitute code FLAT_SUB is applied to the order

		# Note: But the response does not show anything about the substitution !!!


		Scenario: What if substituion code is expired or not active or ...