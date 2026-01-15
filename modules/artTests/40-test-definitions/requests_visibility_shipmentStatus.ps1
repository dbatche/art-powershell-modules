# Contract-driven tests for POST /shipmentStatus
# Generated: 2025-10-09 18:18:09
# Schema: PostShipmentStatus
# Required Fields: shipmentStatus, tripId
# Total Properties: 1

@(
    @{
        Name = 'POST - missing required field: shipmentStatus'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 400
        Body = @{ tripId = 'TEST-TRIP-001' }
    },
    @{
        Name = 'POST - missing required field: tripId'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 400
        Body = @{ shipmentStatus = 1 }
    },
    @{
        Name = 'POST - minimal valid request'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 201
        Body = @{ shipmentStatus = 1; tripId = 'TEST-TRIP-001' }
    },
    @{
        Name = 'POST - all fields with valid data'
        Method = 'POST'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/visibility/shipmentStatus'
        ExpectedStatus = 201
        Body = @{ shipmentStatus = 2; tripId = 'TEST-TRIP-002' }
    }
)
