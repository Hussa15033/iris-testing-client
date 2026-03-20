# Auwais's Production Testing Client

## Description
This client is a testing tool that enables test-driven development and production validation by allowing you to specify production request/response messages in JSON test definition files. These files are then parsed, the messages are created and replayed through the production, and the responses are compared against the test definition schema.

## Author
Auwais Hussain - Sales Engineering UKI

For any queries, bugs or enhancements, please get in touch at ahussain@intersystems.com.

## Installation
Install the project by importing the `dist/latest.xml` file into IRIS:
1. Download the `latest.xml` file
2. From the Management Portal, navigate to `System Explorer > Classes`
3. Click the `Import` button in the top menu
4. Select the downloaded `latest.xml` file
5. Click `Next` and ensure all the classes are selected
6. Click `Import` to finalise the import

## Quickstart
### Recording tests
Once the testing client has been imported, record tests by entering the following commands:
```objectscript
USER>zn "<your-namespace>"
USER>Do ##class(TestingClient.Recorder).Record()
```

Where `<your-namespace>` is the namespace into which the testing client was imported and in which your production resides

When prompted, enter:
1. Your production class name
2. The "target item name" - the name of the production component you wish to test
3. The file in which to save all recorded tests

The tool will then prompt you to select an option: [R] to record new tests or [E] to exit. To record a test, enter `R` and press Enter.

You should then see the following text:

```objectscript
USER>**Please test the component using the management portal..
```

**Note:** Your production should be running and testing should be enabled.

From the Management Portal, open your production by navigating to `Interoperability > Configure > Production`. Click the component you wish to test, then click the `Actions` tab in the right-hand pane then select `Test`. Enter your test request message in the Management Portal and click `Invoke Testing Service`.

Go back to the terminal. Your request message and response will be picked up by the tool. You can enter `A` to accept the test or `R` to reject the test.

You can record as many tests as needed. When you have finished testing, enter `E` to exit the tool. The tests will be saved to the file you specified. If the file fails to save, the tool will output the raw JSON text to the terminal for you to copy and paste.

### Running tests
Run tests via the `TestingClient.ProductionTester` class in the following way:
```objectscript
USER>zn "<your-namespace>"
USER>Do ##class(TestingClient.ProductionTester).Run("<test-directory>", "<production-class>")
```

**\<your-namespace\>**: The namespace the testing tool has been imported into\
**\<test-directory\>**: The directory that holds all the test definition files\
**\<production-class\>**: The name of the production to test

**Note:** The testing client should be imported into the same namespace as the production you are testing. If you wish to import the testing client elsewhere, ensure your namespace has a mapping for the testing client class files.

After running the tests, the following globals are set and can be used to read the statistics from the last test run:
```
^TestingClient.TestDefinitionDirectory		/// The test definition directory
^TestingClient.Runtime						/// The date/time of the run
^TestingClient.ExpectTests 					/// Whether tests were expected in the run
^TestingClient.Success						/// Whether the last run was successful
^TestingClient.TotalTests					/// The total number of tests that were loaded
^TestingClient.TestsPassed					/// The total number of tests that passed
^TestingClient.TestsRan						/// The total number of tests that actually ran
```

For example, to write whether the last run was successful to the terminal:
```objectscript
USER>Write ^TestingClient.Success
```

### Using as part of a CI/CD process
The testing tool can be used as part of an automated testing job in a CI/CD pipeline. When you have finished running tests, the `^TestingClient.Success` variable stores a boolean value indicating whether the tests were successful or not.

You can exit the testing job via the `$System.Process.Terminate` command with a status code indicating success or failure.

For example, if a `0` exit code indicates success and `1` indicates failure in your testing job, you can use the following command to exit the job:
```objectscript
Do $System.Process.Terminate(,'^TestingClient.Success)
```

The `##class(TestingClient.ProductionTester).Run()` command also takes a third optional parameter, `ExpectTests`. This parameter is used to indicate whether you expect tests to run. If this parameter is set to 1, the testing client expects at least one test to be loaded and run.

## Examples
An example of a basic production and test definition file is available in the `example` directory.

## Test Definition Schema
### Root - Test Suite
The root of each test definition file contains the following properties:
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|production&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The class name of the production to run these tests in|
|namespace |string|The namespace containing the production|
|tests|array of test cases|An array of test cases. Each test case is aimed at a specific business component and contains the request/response messages to replay for that component.|

### Test Case
Each test case is aimed at a specific business component and contains the tests to run for that component.
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The name of the business component within the production|
|class|string|The class name of the business component|
|interactions|array of Interactions|An array of interactions. Each interaction contains a request message that will be sent to the business component and a response message that will be validated.|

### Interaction
An interaction is a pair containing a request message and a response message. The request message will be sent into the business component and the response will be validated. Flexibility of responses is achieved with custom validators.
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|request&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|Request Message&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The request message to send into the business component|
|response |Response Message|The expected response from the business component|

### Request Message
A request message is a JSON object for a specific request message class. The class does not have to be JSON-enabled; the message is created at runtime from its properties.
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|class&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The request message class name|
|properties |object|A set of key-value pairs for the properties to set in the request message. Lists/arrays of both primitive data types and serial objects are also supported. To represent serial objects, simply set the value to another JSON object. Arrays can be specified by JSON objects in a similar manner, with the key of the JSON object matching the key of the array. Lists can be specified using JSON arrays (square bracket notation).|

### Response Message
A response message is a JSON object for a specified response message class. The message class does not have to be JSON-enabled.
| Field Name | Type | Description |
| ---------- | ---- | ----------- |
|class&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The response message class name|
|validators |object of Validators|An object containing the custom validators to use for the response message. Each validator can take custom options to customise its behaviour.|
|properties |object|A set of key-value pairs for the properties to set in the response message. Lists/arrays of both primitive data types and serial objects are also supported. If you do not want a specific property to be tested, simply exclude it from this field. By default, the values of the response message are checked to ensure they match the properties in this field exactly.|

### Validators
Validators are used to enable custom behaviours when dealing with responses. If a property does not have a validator specified, the default behaviour is to check for an exact match between the test definition file and the response message.

The key for each validator in the `validators` property must match a property path within the response properties in the JSON test definition. This uses dot notation to reference properties and square brackets to reference array values.

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
* The first item in `FavouriteColours` is `blue`

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
|validator&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|string&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|The class name of the validator (excluding the package). You can create a custom validator by creating a class in the `TestingClient.Definition.Validators` package|
|options |object|A set of key-value pairs of options to pass to the validator to modify its behaviour.|
