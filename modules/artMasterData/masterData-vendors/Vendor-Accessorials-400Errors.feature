Feature: Vendor Accessorial - 400 errors

	Scenario: vendorCodeDoesNotCalculate
		Then "description":"Vendor does not calculate with this Charge Behaviour declaredValueFlat."

	Scenario: nonVendorDoesNotCalculate
		Then "description":"This Charge Behavior passToInterliner only applies to Vendor Codes(vendorCode=True) or Interliner Charges(interlinerCharges=True)"


	Scenario: unavailableFieldForChargeBehavior
		Then "description":"rangeField can only be used when chargeBehavior is rangedCalculation or rangedFlatCharge or rangedPercentage."





