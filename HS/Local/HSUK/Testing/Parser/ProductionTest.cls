/// 
/// This class is the main class that enables testing of the production.
/// It has native methods to send messages within the production and allows all test cases to run
/// these methods
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
	Set ^UnitTestRoot = pFileDirectory

	/// Update runtime parameters
	/// Update the PRODUCTION parameter at runtime
	Set tSC = $System.OBJ.UpdateConfigParam($CLASSNAME(), "PRODUCTION", pProduction)
	$$$ThrowOnError(tSC)

	/// Update the TESTDEFINITIONDIRECTORY at runtime
	Set tSC = $System.OBJ.UpdateConfigParam($CLASSNAME(), "TESTDEFINITIONDIRECTORY", pFileDirectory)
	$$$ThrowOnError(tSC)
	
	// Run the super Run() method
	Do ##super()
}

Method OnBeforeProductionStart() As %Status
{
	Do ##class(APTT.Utils).Log("Running parser on directory '" _ ..#TESTDEFINITIONDIRECTORY _ "'", "Init")
	Try {
		Set totalTests = 0
		Set ..Suites = ##class(APTT.Parser).Parse(..#TESTDEFINITIONDIRECTORY, ..#PRODUCTION, .totalTests)
		Set ..TotalTests = totalTests
	} Catch ex {
		Set tSC = $System.Status.Error("Parsing Error", ex.Data)
		Do ..LogErrors(tSC, "onBeforeProductionStop() while parsing")
		Return tSC
	}

	Quit $$$OK
}

Method OnAfterProductionStart() As %Status
{
	Set sKey = ..Suites.Next("")
	While sKey '= "" {
		Set testSuite = ..Suites.GetAt(sKey)
		Do ..RunOneTestSuite(testSuite)
		Set sKey = ..Suites.Next(sKey)
	}

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

Method RunOneTestSuite(pTestSuite As APTT.Tests.TestSuite) As %Status
{
	/// TODO:
	/// 	KEY POINT: USE ..LOGERRORS FOR NON-FATAL ERRORS OTHERWISE RETURN AN ERROR
	///				   STATUS CODE IF THE ERROR IS FATAL
	Do ..LogMessage("Running test definition file '" _ pTestSuite.SourceFile _ "'")
	
	/// Attempt to run all messages within this production
	Set tc = pTestSuite
	For i=1:1:pTestSuite.TestCases.Size {
		#dim testCase As HS.Local.HSUK.Testing.Parser.Tests.TestCase
		Set testCase = pTestSuite.TestCases.GetAt(i)

		Set targetHostName = testCase.TargetHostName
		Set targetHostClass = testCase.TargetHostClass
		
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
			#dim interaction As HS.Local.HSUK.Testing.Parser.Tests.Interaction
			Set interaction = testCase.Interactions.GetAt(j)

			Set ..RanTests = ..RanTests + 1

			/// Generate the Ens.Request message we will be sending into the
			/// production
			Set requestMessage = interaction.MessageRequest.GenerateMessageRequest()

			/// Send the message into the production
			Do ..SendRequest(targetHostName, requestMessage, .responseMessage, 1)

			/// Now validate the response against what we expect
			Set validation = interaction.MessageResponse.ValidateResponse(responseMessage)
			Return:'$$$ISOK(validation) validation

			Set ..SuccessfulTests = ..SuccessfulTests + 1
		}
	}

	Quit $$$OK
	#; Do pHost.Mess
	#; Set p = ##class(HS.Local.HSUK.Testing.PDS.ProductionTest).%New("")
	#; Do p.SendRequest(..TargetHostName, messageObj, .response, 1)

	#; Do $$$AssertFailure("TEST")
}

}
