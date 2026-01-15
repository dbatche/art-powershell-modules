Feature: CloudHub API

A comprehensive set of RESTful services, allowing you to seamlessly integrate with Trimble Transportation Management Systems (TruckMate, Suite, and ICC) in a unified way.

The core enterprise teams are developing a public facing layer for the legacy single tenant APIs. 
This will enable both external vendors and internal products to leverage these APIs via TTC instead of having to connect point to point as we currently do.

The teams, working with product management, are developing endpoints which will be utilized by FDS and TMS Connector.

CloudHub uses Trimble Identity for identification. Trimble Identity provides single-sign-on access for all of Trimble's Online services.

To make use of CloudHub, the following TruckMate API services must be configured with public URLs:

Background:
	Given I have a valid CloudHub API key
	And I have a valid CloudHub API secret


Scenario: Login to Dev 
	Given I have the following URL:	"https://cloud.dev.api.trimblecloud.com/transportation/tte-truckmate/v0/"
	And I have a TID JWT (Trimble Identity JSON Web Token) as a Bearer token in the request
And x-tms-url: Full hostname of the target ART server: https://tde-truckmate.tmwcloud.com/cur
