# Contract-driven tests for POST /shipmentStatus
# Generated: 2025-10-10 09:53:09
# Schema: PostShipmentStatus
# Required Fields: shipmentStatus, tripId
# Total Properties: 2

@(
    @{
        Name = 'POST - missing required field: shipmentStatus'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 400
        Body = @{ tripId = 'AAAAAAAAAA' }
    },
    @{
        Name = 'POST - missing required field: tripId'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 400
        Body = @{ shipmentStatus = 1 }
    },
    @{
        Name = 'POST - exceeds maxLength: tripId'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 400
        Body = @{ shipmentStatus = 1; tripId = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }
    },
    @{
        Name = 'POST - invalid type (string for number): shipmentStatus'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 400
        Body = @{ shipmentStatus = 'not-a-number'; tripId = 'AAAAAAAAAA' }
    },
    @{
        Name = 'POST - invalid type (number for string): tripId'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 400
        Body = @{ shipmentStatus = 1; tripId = 12345 }
    },
    @{
        Name = 'POST - minimal valid request'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 201
        Body = @{ shipmentStatus = 1; tripId = 'AAAAAAAAAA' }
    },
    @{
        Name = 'POST - all fields with valid data'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 201
        Body = @{ shipmentStatus = 1; tripId = 'AAAAAAAAAA' }
    }
)
