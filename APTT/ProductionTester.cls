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

/// We want to perform custom error handling for production errors
Parameter IGNOREPRODUCTIONERRORS = 1;

Property Suites As list Of APTT.Definition.TestSuite;

Property ExpectedErrors As %Integer [ InitialExpression = 0 ];

Property AccountedErrors As %Integer [ InitialExpression = 0 ];

Property CheckedBaseLogID As %Integer [ InitialExpression = -1 ];

Method ColourText(pText As %String, pColour As %String = "black") As %String
{
	Set cCode = $CASE(
		pColour,
		"red":"31",
		"green":"32",
		"black":"30",
		"blue":"34",
		1:"30"
	)

	Return $c(27) _ "[" _ cCode _ "m" _ pText _ $c(27) _ "[m"
}

/// Logs a message in a specific colour
/// supported colours:
/// - red
/// - green
/// - black
/// - blue
/// 
Method LogColourMessage(pText As %String, pColour As %String = "black")
{
	Do ..LogMessage(..ColourText(pText, pColour))
}

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
	
	Write !,"----- Summary -----",!
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

	Return:ok=0 $System.Status.Error(5001, "One or more tests have failed")
	Quit $$$OK
}

Method OnAfterProductionStop() As %Status
{
	Do ..LogColourMessage("Total of " _ ^APTT.TestsPassed _ "/" _ ^APTT.TotalTests _ " tests were successful out of " _ ^APTT.TestsRan _ " tests ran", "green")

	Do $$$AssertEquals(^APTT.TestsPassed, ^APTT.TotalTests)
	Do $$$AssertEquals(^APTT.TestsRan, ^APTT.TotalTests)
	
	If ((^APTT.TestsPassed = ^APTT.TotalTests) && (^APTT.TestsRan = ^APTT.TotalTests)) {
		/// Check all tests passed and all tests ran before setting the ^APTT.Success global, as this global is the
		/// most important global which dictates whether the tests passed or not
		Do ..LogColourMessage("All tests ran and were successful", "green")
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

			Do ..LogColourMessage("---->Loaded", "green")

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
			Set tSC = $System.Status.Error(5001, ex.DisplayString())
			Return tSC
		}
	}
	
	If ..Suites.Size = 0 {
		Do ..LogMessage("No test suites found")
		Return:^APTT.ExpectTests=1 ..Error("Tests were expected, however none were loaded")
	} Else {
		Do ..LogColourMessage("-->" _ ..Suites.Size _ " test suites loaded", "green")
		Do ..LogColourMessage("-->Identified " _ ^APTT.TotalTests _ " tests to run", "green")
	}

	Return $$$OK
}

Method RunOneTestSuite(pTestSuite As APTT.Definition.TestSuite) As %Status [ Private ]
{
	/// TODO:
	/// 	KEY POINT: USE ..LOGERRORS FOR NON-FATAL ERRORS OTHERWISE RETURN AN ERROR
	///				   STATUS CODE IF THE ERROR IS FATAL
	Do ..LogColourMessage("Running test definition file '" _ pTestSuite.SourceFile _ "'", "blue")
	
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
				Do ..LogColourMessage("---->Running interaction named '" _ interaction.Name _ "'", "blue")
			} Else {
				Do ..LogColourMessage("------>Running interaction with index " _ j, "blue")
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
				Do:'$$$ISOK(tSC) ..LogMessage("Errors occurred during interaction, validating errors...")

				/// Perform error handling to ensure all errors in the production are accounted for
				Set tSC = ..CheckInteractionErrors(interaction)
				$$$ThrowOnError(tSC)

				/// Now validate the response against what we expect
				Set validationSC = interaction.MessageResponse.ValidateResponse(responseMessage)
				$$$ThrowOnError(validationSC)

				Do:$$$ISOK(validationSC) $I(^APTT.TestsPassed, 1)
				Do $$$AssertStatusOK(validationSC)
				Do ..LogColourMessage("-------->Response message is valid", "green")
			} Catch ex {
				Set interactionName = "Interaction index " _ j
				Set:interaction.Name'="" interactionName = interaction.Name

				Do ..LogErrors(..Error(..ColourText(ex.DisplayString(), "red")), "File '" _ ##class(%File).GetFilename(pTestSuite.SourceFile) _ "'" _ "->" _ testCase.TargetHostName _ "->" _ interactionName)
				Do $$$AssertFailure("Interaction Test Failed")
			}
		}
	}

	Quit $$$OK
}

/// This method checks the errors since the last check to ensure the errors
/// that were expected from this interaction are accounted for
Method CheckInteractionErrors(pInteraction As APTT.Definition.Interaction) As %Status
{
	Do ..LogColourMessage("Running CheckInteractionErrors()", "blue")
	If (..CheckedBaseLogID = -1) {
		/// If base log ID not initialized, set to production base default
		Set ..CheckedBaseLogID = ..BaseLogId
	}

	Set expectedErrCnt = pInteraction.MessageResponse.ExpectedErrorCount
	Set expectedErrList = pInteraction.MessageResponse.ExpectedErrors

	Set ..ExpectedErrors = ..ExpectedErrors + expectedErrCnt

	Do ..GetEventLog("error","",..CheckedBaseLogID, .Errs, .n)

	Set tSC = $$$OK
	
	/// Loop through all errors
	For i=1:1:n {
		Set logID = Errs(i, "ID")
		Set errText = Errs(i, "Text")

		If logID > ..CheckedBaseLogID {
			Set ..CheckedBaseLogID = logID
		}

		If (expectedErrList.Size > 0) && (i <= expectedErrList.Size) {
			Set expectedErr = expectedErrList.GetAt(i)
			If (errText '[ expectedErr) {
				Do ..LogColourMessage("Expected production error to contain text '" _ expectedErr _ "' but actual error is '" _ errText _ "'", "red")
				Set tSC = $System.Status.Error(5001, ..ColourText("One or more production errors could not be validated -- Please see above", "red"))
			} Else {
				Do ..LogColourMessage("Error " _ i _ " is an expected error and contains the specified text", "green")
			}
		} Else {
			Set ..AccountedErrors = ..AccountedErrors + 1
		}
	}

	/// Increment the base log ID to not overlap errors from the previous interaction
	Set ..CheckedBaseLogID = ..CheckedBaseLogID + 1

	Quit:expectedErrCnt'=n $System.Status.Error(5001,"Expected " _ expectedErrCnt _ " errors but " _ n _ " errors occurred since last interaction")

	Do:$$$ISOK(tSC) ..LogColourMessage("Expected " _ expectedErrCnt _ " errors and detected " _ n _ " errors, test passed", "green")
	Quit tSC
}

Method CheckErrors() As %Status
{
	// Automatically check errors
	Do $$$AssertEquals(..AccountedErrors, ..ExpectedErrors)
	Do ..GetEventLog("error","", ..BaseLogId,,.TotalErrors)

	Quit:(..AccountedErrors'=..ExpectedErrors)||(..AccountedErrors'=TotalErrors) $System.Status.Error(5001, "Not all errors have been accounted for. Expected " _ ..ExpectedErrors _ " errors but actually accounted for " _ ..AccountedErrors _ " errors, there were " _ TotalErrors _ " that occurred in total.")
	Quit $$$OK
}

}
