# Auwais' Testing Client

## Description
This client is a testing tool to enable test-driven development and validation of productions by allowing you to specify production request/response messages through a JSON schema. This JSON schema is then parsed and all messages are created and replayed through the production and their responses compared with the test definition schema

## Getting Started
To start with you can 

## Usage
### Using as a standalone tool

### Using as part of a CI/CD process

## Bug Fixes
-

## To do
* [Done] Rename "ContainsValidator" to "TextValidator" and update the code as needed, use the examples in the Validators section below
* Ensure namespace and production classes are checked properly
* [Done] Restructure files and use the ATT.* package name
* Finish any "TODOs" within the text documentation
* Document all classes properly
* Clean up dead code
* Ensure all IF conditions are properly paranthesised
* [Done] Move tests to an "example" folder
* Create a "build" folder with the XML export of the first release
* In the getting started steps, show how to import the tool and use it
## Examples

## Validators

## Authors
Auwais Hussain - Sales Engineering UKI

For any queries, bugs or enhancements please get in touch at ahussain@intersystems.com

## Test Definition Schema
### Root - Test Suite
The root of each Test definition file contains the following properties:
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|production&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The class name of the production to run these tests in|
|namespace |string|The namespace containing the production|
|tests|array of Testcases|An array of testcases, each testcase is aimed at a specific business host and contains the request/response messages to replay into that business component|

### Testcase
Each test case is aimed at a specific business component and contains the tests to run for each component
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The name of the business component within the production|
|class|string|The classname of the business component|
|intearctions|array of Interactions|An array of interactions, each interaction contains a request message that will be sent to the business component, and a response message that will be validated|

### Interaction
An interaction is a pair containing a request and response message. The request message will be sent into the business component and the response will be validated. Flexibility of responses is achieved with custom Validators.
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|request&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|Request Message&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The request message to send into the business component|
|response |Response Message|The expected response from the business component|

### Request Message
A request message is a JSON object for a specific Request message class. The message class does <b><u>NOT</u></b> have to be JSON enabled and is created on the fly using it's properties
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|class&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The request message class name|
|properties |object|A key value pair of the properties to set in the request message. Lists/arrays of both primitive data types and serial objects are also supported. In order to represent serial objects, simply set the value to another JSON object. Arrays can be specified by JSON objects in a similar manner, with the key of the JSON object matching the key of the Array. Lists can be specified by using JSON arrays (square bracket notation)|

### Response Message
A response message is a JSON object for a specified Response message class. The message class does <u><b>NOT</b></u> have to be JSON enabled.
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|class&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The response message class name|
|validators |object of Validators|A list of custom validators to use for the response message. Each validator can take custom options to customise it's behaviour|
|properties |object|A key value pair of the properties to set in the response message. Lists/arrays of both primitive data types and serial objects are also supported. If you do not want a specific property to be tested, simply excluse it from this field. By default the values of the response message will be checked to see if they match exactly with the properties in this field|

### Validators
Validators are used to enable custom behaviours when dealing with responses. The default behaviour, if a property does not have a validator specified, is to check that there is an exact match between the test definition file and the response message

The key for each validator in the `validators` property must match a property path within the JSON test definition of the responses properties, this uses dot notation to reference the property and square brackets to reference any array values

For example, given the following class:
```objectscript
Class Demo.MyTestResponse Extends Ens.Response
{

	Property Name As %String;
	Property Age As %Integer;
	Property ContactNumbers As array Of %Integer;
	Property FavouriteColours As list Of %String;

}
```

We can validate the following:
* The `Main` key in the `ContactNumbers` contains `+44`
* The first `FavouriteColours` is `blue`

```json
"validators": {
	"ContactNumbers.Main": {
		"validator": "TextValidator",
		"options": {
			"containsText": "+44"
		}
	},
	"FavouriteColours[0]": {
		"validator": "TextValidator",
		"options": {
			"equals": "blue",
			"caseSensitive": true
		}
	}
}
```
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|validator&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The classname of the validator (excluding the package). You can create a custom validator by creating a class in the `ATT.Validators` package|
|options |object|A key value pair of options to pass into the validator to modify it's behaviour|
