Feature: Delete Client Id 

Scenario: Disallow Delete 
Given client '123' is not valid to delete #for some reason
When DELETE /masterData/clients/123
Then the API should call validateClientBeforeDelete
And the API should return a 400 error if the client is not valid to delete