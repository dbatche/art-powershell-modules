$log="ApiAccChg.tap" 
new-item $log -force | out-null

Test-Scenario "Create Accessorial Charge - Minimum number of fields - code & gl account" $log {



Test-Step "Given a valid /masterData ART Server URL and API-key" $log {
	
	$endpoint = "/aChargeCodes"

	#$test02server = "http://van-dev-test02.am.trimblecorp.net:8286/masterData"
	$test02server = "http://van-dev-test02:8286/masterData"
	$localserver = "http://localhost:9950/masterData"

	#$script:url = $test02server + $endpoint
	$script:url = $localserver + $endpoint
	
	write-verbose $url 

}

Test-Step "And API-key encoded in header" $log {
	
	
	$test02apikey = "9ade1b0487df4d67dcdc501eaa317b91"
	$localApikey = "8e8c563a68a03bda2c1fce86ffef1261"

	$script:auth = @{
		#"Authorization" = "Bearer $test02apikey"
		"Authorization" = "Bearer $localApikey"
	}
	
	write-verbose ($auth | convertto-json)

	
}


Test-Step "And a accessorial json request body" $log {

	$randomBankAccount = Get-Random -Maximum 999999

	$newAccPS = [ordered]@{
		"aChargeCodes"= @(
			[ordered]@{
				"aChargeCodeId"= ("AC" + $randomBankAccount)
				"truckmateGlAccount"= "00-4000"
			}
		)
	}

	$script:newAccJson = $newAccPS | ConvertTo-Json

	write-verbose $newAccJson

}

Test-Step "When I Post the request to the /aChargeCodes endpoint" $log {

	$script:response = Invoke-WebRequest -Uri $url -Body $newAccJson -Method Post -ContentType "application/json" -Headers $auth

}

Test-Step "Then the response status code should be correct (201)"  $log {

	Write-verbose "Actual Status Code: $($response.StatusCode)"

	$response.StatusCode -eq '201' 
}

Test-Step "And the system response should be valid JSON" $log {

	Test-Json -Json ($response.content)
	write-verbose ($response.content)

}


Test-Step "And the response should return the accessorial information" $log {

	$script:responsePS = ($response.content | ConvertFrom-Json).aChargeCodes

	write-verbose ($responsePS.aChargeCodeId)
	write-verbose ($responsePS | out-string)

}


Test-Step "And the accessorial information should match the database record" $log {

	$test02DB = "Set-DB2Connection AUTOCUR TMWIN Maddox17"
	$localDB = "Set-DB2Connection ST232 TMWIN Maddox2015"
	
	# Set-DB2Connection $test02DB
	Invoke-expression $localDB

	$script:accDBrecord = Get-AccessorialCode -acodeId ($responsePS.aChargeCodeId) | select-object -first 1
	
	write-verbose ($accDBrecord | out-string)
	#write-verbose ($responsePS.aChargeCodes.aChargeCodeId)
	#write-verbose ($responsePS.aChargeCodes | out-string)

}

Test-Step "And field by field comparison should be ok" $log {

	Write-verbose "$($responsePS.aChargeCodeId) vs $($accDBrecord.ACODE_ID)"
	Write-verbose "$($responsePS.chargeBehavior) vs $($accDBrecord.CODE_TYPE)"
	Write-verbose "$($responsePS.truckmateGlAccount) vs $($accDBrecord.TMW_ACCT_CODE)"
	 
	# etc ... a little painful, as it is not only field names that need mapping, but enum values as well
	# perhaps i need to use the special database view that ART uses.
}

}