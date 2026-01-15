@(
    @{ Method = 'GET'; Url = '/version'; ExpectedStatus = 200 },
    @{ Method = 'PUT'; Url = '/orders/123'; ExpectedStatus = 400; Body = @{ bad = 'data' } }
)
