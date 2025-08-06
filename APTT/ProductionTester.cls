/// 
/// Auwais's Production Testing Tool
/// 
/// The main entry point for the APTT utility
/// 
/// This class is the main class that enables testing of the production. It will load all of your
/// test definition files and play back the interactions stored within the JSON file
/// 
/// All messages will automatically be created on the fly, you do not need to
/// extend your request or response messages from the %JSON.Adaptor class
/// 
/// To run this tester:
/// 	- Create a directory with all of your test definition files
/// 	- Run with
/// 		Do ##class(APTT.ProductionTester).Run("/path/to/your/test/definitions/directory", "<your production name>")
/// 
/// @author Auwais Hussain
/// @version 0.6
/// 
Class APTT.ProductionTester Extends %UnitTest.TestProduction
{

/// The production to test, this is determined at Runtime so a default value of "None" is specified
Parameter PRODUCTION As CONFIGVALUE = "None";

/// We do not want to ignore any errors in production
Parameter IGNOREPRODUCTIONERRORS = 0;

Property Suites As list Of APTT.Definition.TestSuite;

ClassMethod Run(pFileDirectory As %String, pProduction As %String, pExpectTests As %Boolean = 0, pExitOSProcess As %Boolean = 0) As %Status
{
	Set dir = ##class(%File).%New(pFileDirectory)
	If ('##class(%File).DirectoryExists(pFileDirectory)) {
		Write "[ERROR]: " _ "Directory '" _ pFileDirectory _ "' does not exist.. exiting"
		Return $System.Status.Error("InitFailed", "Specified directory '" _ pFileDirectory _ "' does not exist")
	}

	Set ^UnitTestRoot = pFileDirectory

	/// Update runtime parameters
	/// Update the PRODUCTION parameter at runtime
	Set tSC = $System.OBJ.UpdateConfigParam($CLASSNAME(), "PRODUCTION", pProduction)
	$$$ThrowOnError(tSC)

	/// Tool specific globals
	Kill ^APTT
	Set ^APTT.TestDefinitionDirectory = pFileDirectory
	Set ^APTT.Runtime = $ZDT($H)
	Set ^APTT.ExpectTests = pExpectTests
	Set ^APTT.Success = 0
	Set ^APTT.TotalTests = 0
	Set ^APTT.TestsPassed = 0
	Set ^APTT.TestsRan = 0
	
	// Run the super Run() method
	/// The tSC returned by the Super.Run() method is unrelated to whether the tests passed or not, so we cannot use it
	/// to reliably determine whether all tests passed or not, which is why we set the globals above.
	Set tSC = ##super()
	
	Write "----- Summary -----",!
	Write "- Total tests: " _ ^APTT.TotalTests,!
	Write "- Tests ran: " _ ^APTT.TestsRan,!
	
	Set percentPassed = 0
	Set:^APTT.TestsRan>0 percentPassed = $NUMBER(((^APTT.TestsPassed / ^APTT.TestsRan) * 100), 0)
	Write "- Tests passed: " _ ^APTT.TestsPassed _ " / " _ ^APTT.TestsRan _ "(" _ percentPassed _ "%)",!

	Do:pExitOSProcess=1 $System.Process.Terminate(,^APTT.Success)
	If ($GET(^APTT.Success, "") = 1) {
		Return $$$OK
	} Else {
		Return ..Error("Tests were not successful")
	}
}

Method OnBeforeProductionStart() As %Status
{
	Set testDefinitionDirectory = $GET(^APTT.TestDefinitionDirectory, "")
	If (testDefinitionDirectory = "") {
		Do $$$AssertFailure("No test definition directory was specified")
	}

	Do ..LogMessage("-->Loading test definition files from directory '" _ testDefinitionDirectory _ "'")
	Set tSC = ..LoadTestDefinitionFiles(testDefinitionDirectory)
	Return:'$$$ISOK(tSC) tSC


	Quit $$$OK
}

Method OnAfterProductionStart() As %Status
{
	Set sKey = ..Suites.Next("")
	Set ok = 1
	While sKey '= "" {
		Set testSuite = ..Suites.GetAt(sKey)
		Set st = ..RunOneTestSuite(testSuite)
		Set:'$$$ISOK(st) ok = 0
		Set sKey = ..Suites.Next(sKey)
	}

	Return:ok=0 $System.Status.Error(6133, "One or more tests have failed")
	Quit $$$OK
}

Method OnAfterProductionStop() As %Status
{
	Do ..LogMessage("Total of " _ ^APTT.TestsPassed _ "/" _ ^APTT.TotalTests _ " tests were successful out of " _ ^APTT.TestsRan _ " tests ran")

	Do $$$AssertEquals(^APTT.TestsPassed, ^APTT.TotalTests)
	Do $$$AssertEquals(^APTT.TestsRan, ^APTT.TotalTests)
	
	If ((^APTT.TestsPassed = ^APTT.TotalTests) && (^APTT.TestsRan = ^APTT.TotalTests)) {
		/// Check all tests passed and all tests ran before setting the ^APTT.Success global, as this global is the
		/// most important global which dictates whether the tests passed or not
		Do ..LogMessage("All tests ran and were successful")
		Set ^APTT.Success = 1
	}


	Quit $$$OK
}

/// Run the parser for a directory of .JSON test files
/// These files MUST end in ".json" to be picked up by this test utility
/// <property>pFileDirectory</property> - The directory in the file system which holds the .json test definitions
Method LoadTestDefinitionFiles(pFileDirectory As %String) As %Status [ Private ]
{
	Set stmt = ##class(%SQL.Statement).%New()
	Set st = stmt.%PrepareClassQuery("%File", "FileSet")
	Return:'$$$ISOK(st) st

	Set rSet = stmt.%Execute(pFileDirectory, "*.json")
	If (rSet.%SQLCODE '= 0) {
		Set tSC = $System.Status.Error("File Query ERROR", "Could not query directory for files: '" _ pFileDirectory _ "'")
		Do ..LogErrors(tSC, "File query failed, SQL CODE=" _ rSet.%SQLCOD _ ", MESSAGE=" _ rSet.%Message)
		Return tSC
	}

	While rSet.%Next() {
		Try {
			Set path = ##class(%File).NormalizeFilename(rSet.%Get("Name"))
			Set filename = ##class(%File).GetFilename(path)
			Do ..LogMessage("---->Loading " _ filename _ "...")
			Set testSuite = ##class(APTT.Parser).LoadFileAsTestSuite(path)

			Do ..LogMessage("---->Loaded")

			/// Throw errors if any of the test definition files have a different target namespace or production
			Throw:testSuite.TargetNamespace'=$NAMESPACE ##class(%Exception.General).%New("Incorrect namespace","-93",,"The namespace specified '" _ testSuite.TargetNamespace _ "' is different to the selected namespace '" _ $NAMESPACE _ "'. Ensure all test definition files have the same target namespace")
			Throw:testSuite.TargetProduction'=..#PRODUCTION ##class(%Exception.General).%New("Incorrect production","-93",,"The production specified '" _ testSuite.TargetProduction _ "' is different to the selected production '" _ ..#PRODUCTION _ "'. Ensure all test definition files have the same target production")

			Do ..Suites.Insert(testSuite)

			/// TODO: Find a more elegant way to obtain a total test count, maybe even move this whole method to the
			/// Count how many test cases there are
			Set tKey = testSuite.TestCases.Next("")
			While tKey '= "" {
				Do $I(^APTT.TotalTests, testSuite.TestCases.GetAt(tKey).Interactions.Size)
				Set tKey = testSuite.TestCases.Next(tKey)
			}
		} Catch ex {
			Set tSC = $System.Status.Error(5030, ex.DisplayString())
			Return tSC
		}
	}
	
	If ..Suites.Size = 0 {
		Do ..LogMessage("No test suites found")
		Return:^APTT.ExpectTests=1 ..Error("Tests were expected, however none were loaded")
	} Else {
		Do ..LogMessage("Identified " _ ..Suites.Size _ " test suites to run")
	}

	Return $$$OK
}

Method RunOneTestSuite(pTestSuite As APTT.Definition.TestSuite) As %Status [ Private ]
{
	/// TODO:
	/// 	KEY POINT: USE ..LOGERRORS FOR NON-FATAL ERRORS OTHERWISE RETURN AN ERROR
	///				   STATUS CODE IF THE ERROR IS FATAL
	Do ..LogMessage("Running test definition file '" _ pTestSuite.SourceFile _ "'")
	
	/// Attempt to run all messages within this production
	Set tc = pTestSuite
	For i=1:1:pTestSuite.TestCases.Size {
		#dim testCase As APTT.Definition.TestCase
		Set testCase = pTestSuite.TestCases.GetAt(i)
		
		Set targetHostName = testCase.TargetHostName
		Set targetHostClass = testCase.TargetHostClass

		Do ..LogMessage("-->Starting tests for host '" _ targetHostName _ "'")
		
		/// Attempt to find the target host this test is for
		Set prod = ##class(Ens.Config.Production).%OpenId(..#PRODUCTION,,.tSC)
		Do $$$AssertStatusOK(tSC)

		Set itemFound = ""
		For i=1:1:prod.Items.Count() {
			#dim item As Ens.Config.Item
			Set item = prod.Items.GetAt(i)
			If ((item.Name = targetHostName) && (item.ClassName = targetHostClass)) {
				Set itemFound = item
			}
		}

		If (itemFound = "") {
			Throw ##class(%Exception.General).%New("Item not found", "-193",,"Business host named '" _ targetHostName _ "' with class '" _ targetHostClass _ "' not found")
		}

		#dim itemFound As Ens.Config.Item
		If ('itemFound.Enabled) {
			Throw ##class(%Exception.General).%New("Item not enabled", "-15",,"Business host '" _ targetHostName _ "' with class '" _ targetHostClass _ "' has not been enabled within production")
		}

		Do $$$AssertNotEquals(itemFound, "")
		Do $$$AssertTrue(itemFound.Enabled)
		/// By this point, the Config item is valid, exists within the production and is enabled

		/// Run the interactions within the TestCase
		Set interactions = testCase.Interactions

		For j=1:1:testCase.Interactions.Size {
			#dim interaction As APTT.Definition.Interaction
			Set interaction = testCase.Interactions.GetAt(j)

			If (interaction.Name '= "") {
				Do ..LogMessage("---->Running interaction named '" _ interaction.Name _ "'")
			} Else {
				Do ..LogMessage("------>Running interaction with index " _ j)
			}

			Do $I(^APTT.TestsRan, 1)

			/// Generate the Ens.Request message we will be sending into the
			/// production
			Try {
				Do ..LogMessage("-------->Generating request message " _ interaction.MessageRequest.ClassName _ "...")
				Set requestMessage = interaction.MessageRequest.GenerateMessageRequest()

				/// Send the message into the production
				Do ..LogMessage("-------->Sending request to " _ targetHostName)
				Set tSC = ..SendRequest(targetHostName, requestMessage, .responseMessage, 1)
				Do $$$AssertStatusOK(tSC)

				/// Now validate the response against what we expect
				Set validationSC = interaction.MessageResponse.ValidateResponse(responseMessage)
				Do:$$$ISOK(validationSC) $I(^APTT.TestsPassed, 1)
				Do $$$AssertStatusOK(validationSC)
				Do ..LogMessage("-------->Response message is valid")
			} Catch ex {
				Do ..LogErrors(..Error(ex.DisplayString()), pTestSuite.SourceFile _ "->" _ testCase.TargetHostName _ "->" _ "Interaction index " _ j)
				Do $$$AssertFailure("Test Failed")
			}
		}
	}

	Quit $$$OK
}

}
