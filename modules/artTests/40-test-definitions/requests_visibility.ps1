@(
    # ---------- Happy-path ----------
    @{ Name='version ok';   Method='GET';  Url='/version';  ExpectedStatus=200 },
    @{ Name='whoami ok';    Method='GET';  Url='/whoami';   ExpectedStatus=200 },

    # ---------- Query-parameter validation ----------
    @{ Name='limit decimal';      Method='GET'; Url='/orders?limit=1.1';   ExpectedStatus=400 },
    @{ Name='limit negative';     Method='GET'; Url='/orders?limit=-5';    ExpectedStatus=400 },
    @{ Name='limit out of bounds';Method='GET'; Url='/orders?limit=99999'; ExpectedStatus=400 },
    @{ Name='offset decimal';     Method='GET'; Url='/orders?offset=1.1';  ExpectedStatus=400 },
    @{ Name='offset negative';    Method='GET'; Url='/orders?offset=-2';   ExpectedStatus=400 },
    @{ Name='offset string';      Method='GET'; Url='/orders?offset=abc';  ExpectedStatus=400 },
    @{ Name='select garbage';     Method='POST'; Url='/shipmentStatus?$select=garbage'; ExpectedStatus=400; Body=@{} },

    # ---------- Body validation ----------
    @{ Name='shipmentStatus tripId too long';
       Method='POST'; Url='/shipmentStatus'; ExpectedStatus=400;
       Body=@{ shipmentStatus=1; tripId=('x'*41) } },

    @{ Name='stopStatus invalid status enum';
       Method='POST'; Url='/stopStatus'; ExpectedStatus=400;
       Body=@{ stopId='123'; statusDate='2025-09-12T10:00:00'; status='invalid'; sequence=1; longitude=45; latitude=45 } }
)
