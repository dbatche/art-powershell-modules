# ---------------------------
# TEST: PUT to UserFieldsData
# ---------------------------

# Pre-request:
    # artFinance\Get-APInvoices -Expand userFieldsData -Offset 20  | ft -p *
    $resp1 = artFinance\Get-UserFieldsData -SourceType apInvoices -limit 1 -Select 'sourceId' 
    $updateText = (Get-Date -Format 'yy-MM-dd-hh-mm-ss')
# Request:
    # artFinance\Set-UserFieldsData -SourceType apInvoices -SourceId 17376 -UserField USER1 -UserData (Get-Date) 
    $request = "Set-UserFieldsData -SourceType apInvoices -SourceId $resp1.sourceId -UserField USER1 -UserData $updateText "    #-Verbose -PassThru
    Write-host $request
    #$resp2 = Invoke-Expression $request
    Invoke-Expression $request -OutVariable resp2 | convertto-json
# Post-response
    "TEST: Expected $updateText | Actual $($resp2.userFieldsData.userData)"
    # artFinance\Get-UserFieldsData -SourceType apInvoices -SourceId 17376 | ft
    # artFinance\Get-UserFieldsData -SourceType apInvoices -SourceId $resp1.sourceId| ft