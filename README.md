# Auwais' Production Testing Client

## Description
This client is a testing tool to enable test-driven development and validation of productions by allowing you to specify production request/response messages through JSON test definition files. These files are then parsed and all messages are created and replayed through the production and their responses compared with the test definition schema

## Authors
Auwais Hussain - Sales Engineering UKI

For any queries, bugs or enhancements please get in touch at ahussain@intersystems.com

## Installation
Install the project by imported the `dist/latest.xml` file into IRIS
1. Download the `latest.xml` file
2. From with the management portal, navigate to `System Explorer > Classes`
3. Click the `Import` button in the top menu
4. Select the downloaded `latest.xml` file
5. Click `Next` and ensure all the classes are selected
6. Click `Import` to finalise the import

## Quickstart
### Recording tests
Once the testing client has been imported, record tests by entering the following commands:
```objectscript
USER>zn "<your-namespace>"
USER>Do ##class(APTT.Recorder).Record()
```

Where `<your-namespace>` is the namespace the testing client was imported to and where your production is in

When prompted, enter:
1. Your production class name
2. The "target item name", this is the name of the production component you wish to test
3. The file to save all recorded tests to

The tool will then prompt you to select an option - [R] to record new tests or [E] to exit. To record a test, enter "R" and press enter.

You should then see the following text:

```objectscript
USER>**Please test the component using the management portal..
```

**Note:** Your production should be running and testing should be enabled.

From the management portal, open your production by navigating to `Interoperability > Configure > Production`. Click the component you wish to test, and click the `Actions` tab in the right hand pane and click `Test`. Enter your test request message from the management portal and click `Invoke Testing Service`

Go back to the terminal, your request message and response will be picked up by the tool. You can enter "A" to accept the test or "R" to reject the test.

You can record as many tests as needed. When you have finished testing, enter "E" to exit the tool. The tests will be saved to the file you specified. If the file fails to save, the tool will output the raw JSON text into the terminal for you to copy/paste

### Running tests
Run tests via the `APTT.ProductionTester` class in the following way:
```objectscript
USER>zn "<your-namespace>"
USER>Do ##class(APTT.ProductionTester).Run("<test-directory>", "<production-class>")
```

**\<your-namespace\>**: The namespace the testing tool has been imported into\
**\<test-directory\>**: The directory that holds all the test definition files\
**\<production-class\>**: The name of the production to test

**Note**: The testing client should be imported into the same namespace as the production you are testing. If you wish to import the testing client elsewhere, ensure your namespace has a mapping for the testing client class files

After running the tests, the following globals are set and can be used to read the stats of the last test run:
```
^APTT.TestDefinitionDirectory: The test definition directory
^APTT.Runtime: The date/time of the run
^APTT.ExpectTests: Whether tests were expected in the run
^APTT.Success: Whether the last run was successful
^APTT.TotalTests: The total number of tests that were loaded
^APTT.TestsPassed = The total number of tests that passed
^APTT.TestsRan = The total number of tests that actually ran
```

For example, to write the success of the last run to the terminal:
```objectscript
USER>Write ^APTT.Success
```

### Using as part of a CI/CD process
The testing tool can be used as part of an automated testing job in a CI/CD pipeline. When you have finished running tests, the `^APTT.Success` variable stores a boolean value indicating whether the tests were successful or not.

You can exit the testing job via the `$System.Process.Terminate` command with a status code indicating success or failure.

For example if a "0" exit code indicates success and "1" indicates failure in your testing job, you can use the following command to exit the job
```
Do $System.Process.Terminate(,'^APTT.Success)
```

The `##class(APTT.ProductionTester).Run()` command also takes in a 3rd optional parameter "ExpectTests". This parameter is used to indicate whether you expect tests to run. If this parameter is set to 1, the testing client expects atleast 1 test to be loaded and ran

## Examples
An example of a basic production and test definition file is available in the `example` directory.

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
|interactions|array of Interactions|An array of interactions, each interaction contains a request message that will be sent to the business component, and a response message that will be validated|

### Interaction
An interaction is a pair containing a request and response message. The request message will be sent into the business component and the response will be validated. Flexibility of responses is achieved with custom Validators.
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|request&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|Request Message&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The request message to send into the business component|
|response |Response Message|The expected response from the business component|

### Request Message
A request message is a JSON object for a specific Request message class. The message class does <b><u>NOT</u></b> have to be JSON enabled and is created at runtime using it's properties
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
|validator&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The classname of the validator (excluding the package). You can create a custom validator by creating a class in the `APTT.Definition.Validators` package|
|options |object|A key value pair of options to pass into the validator to modify it's behaviour|
