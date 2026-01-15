# $domain = "http://localhost:9900/tm"
# $orderId = 1974
# //$orderDetailId = 75000


# $url = $domain + "/orders/$orderId/details"

# $auth 

# $body = @"
# {

#     [
#         {
#             "altBarcode1": "add another new barcode item"
#         }
#     ]
# }
# "@

#Invoke-RestMethod 


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer 8e8c563a68a03bda2c1fce86ffef1261")
$headers.Add("Content-Type", "application/json")

$body = "[
`n    {
`n        `"altBarcode1`": `"add another new barcode item`"
`n    }
`n]
`n"

$response = Invoke-RestMethod 'http://localhost:9900/tm/orders/1974/details/' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json  -Depth 5