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

/// The directory holding our Test Definition files.
Parameter TESTDEFINITIONDIRECTORY As CONFIGVALUE = "None";

/// We do not want to ignore any errors in production
Parameter IGNOREPRODUCTIONERRORS = 0;

Property Suites As list Of APTT.Tests.TestSuite;

Property TotalTests As %Integer [ InitialExpression = 0 ];

Property SuccessfulTests As %Integer [ InitialExpression = 0 ];

Property RanTests As %Integer [ InitialExpression = 0 ];

ClassMethod Run(pFileDirectory, pProduction) As %Status
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

	/// Update the TESTDEFINITIONDIRECTORY at runtime
	Set tSC = $System.OBJ.UpdateConfigParam($CLASSNAME(), "TESTDEFINITIONDIRECTORY", pFileDirectory)
	$$$ThrowOnError(tSC)
	
	// Run the super Run() method
	Set tSC = ##super()
	Quit tSC
}

Method OnBeforeProductionStart() As %Status
{
	Do ..LogMessage("Loading test definition files from directory '" _ ..#TESTDEFINITIONDIRECTORY _ "'")
	Set tSC = ..LoadTestDefinitionFiles(..#TESTDEFINITIONDIRECTORY)
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
Ra
	Do ..LogMessage("Total of " _ ..SuccessfulTests _ "/" _ ..TotalTests _ " tests were successful out of " _ ..RanTests _ " tests ran")

	Do $$$AssertEquals(..SuccessfulTests, ..TotalTests)
	Do $$$AssertEquals(..RanTests, ..TotalTests)

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
			Set testSuite = ##class(APTT.Parser).LoadFileAsTestSuite(path)

			/// Throw errors if any of the test definition files have a different target namespace or production
			Throw:testSuite.TargetNamespace'=$NAMESPACE ##class(%Exception.General).%New("Incorrect namespace","-93",,"The namespace specified '" _ testSuite.TargetNamespace _ "' is different to the selected namespace '" _ $NAMESPACE _ "'. Ensure all test definition files have the same target namespace")
			Throw:testSuite.TargetProduction'=..#PRODUCTION ##class(%Exception.General).%New("Incorrect production","-93",,"The production specified '" _ testSuite.TargetProduction _ "' is different to the selected production '" _ ..#PRODUCTION _ "'. Ensure all test definition files have the same target production")

			Do ..Suites.Insert(testSuite)

			/// TODO: Find a more elegant way to obtain a total test count, maybe even move this whole method to the
			/// Count how many test cases there are
			Set tKey = testSuite.TestCases.Next("")
			While tKey '= "" {
				Set ..TotalTests = ..TotalTests + testSuite.TestCases.GetAt(tKey).Interactions.Size
				Set tKey = testSuite.TestCases.Next(tKey)
			}
		} Catch ex {
			Set tSC = $System.Status.Error(5030, ex.DisplayString())
			Return tSC
		}
	}
	
	If ..Suites.Size = 0 {
		Do ..LogMessage("No test suites found")
	} Else {
		Do ..LogMessage("Identified " _ ..Suites.Size _ " test suites to run")
	}

	Return $$$OK
}

Method RunOneTestSuite(pTestSuite As APTT.Tests.TestSuite) As %Status [ Private ]
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

		Do ..LogMessage("  Running tests for host " _ targetHostName)
		
		/// Attempt to find the target host this test is for
		Set prod = ##class(Ens.Config.Production).%OpenId(..#PRODUCTION,,.tSC)
		$$$ThrowOnError(tSC)

		Set itemFound = ""
		For i=1:1:prod.Items.Count() {
			#dim item As Ens.Config.Item
			Set item = prod.Items.GetAt(i)
			If ((item.Name = targetHostName) && (item.ClassName = targetHostClass)) {
				Set itemFound = item
			}
		}

		If (itemFound = "") {
			Throw ##class(%Exception.General).%New("Item not found", "-193",,"Business host '" _ targetHostName _ "' with class '" _ targetHostClass _ "' not found")
		}

		#dim itemFound As Ens.Config.Item
		If ('itemFound.Enabled) {
			Throw ##class(%Exception.General).%New("Item not enabled", "-15",,"Business host '" _ targetHostName _ "' with class '" _ targetHostClass _ "' has not been enabled within production")
		}

		/// By this point, the Config item is valid, exists within the production and is enabled

		/// Run the interactions within the TestCase
		Set interactions = testCase.Interactions

		For j=1:1:testCase.Interactions.Size {
			Do ..LogMessage("    Running interaction " _ j)
			Set ..RanTests = ..RanTests + 1

			#dim interaction As APTT.Definition.Interaction
			Set interaction = testCase.Interactions.GetAt(j)

			/// Generate the Ens.Request message we will be sending into the
			/// production
			Try {
				Do ..LogMessage("      Generating request message " _ interaction.MessageRequest.ClassName _ "...")
				Set requestMessage = interaction.MessageRequest.GenerateMessageRequest()

				/// Send the message into the production
				Do ..LogMessage("      Sending request to " _ targetHostName)
				Do ..SendRequest(targetHostName, requestMessage, .responseMessage, 1)

				/// Now validate the response against what we expect
				Set validation = interaction.MessageResponse.ValidateResponse(responseMessage)
				Set:$$$ISOK(validation) ..SuccessfulTests = ..SuccessfulTests + 1
				Do ..LogMessage("      Response message is valid")
			} Catch ex {
				Do ..LogMessage("      Error occurred while running tests:" _ ex.DisplayString())
			}
		}
	}

	Quit $$$OK
}

}
