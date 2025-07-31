/// 
/// This class is the main class that enables testing of the production.
/// It has native methods to send messages within the production and allows all test cases to run
/// these methods
/// 
Class HS.Local.HSUK.Testing.Spine.ProductionTest Extends %UnitTest.TestProduction
{

/// The production to test, this is determined at Runtime so a default value of "None" is specified
Parameter PRODUCTION As CONFIGVALUE = "None";

/// We do not want to ignore any errors in production
Parameter IGNOREPRODUCTIONERRORS = 0;

Parameter TestSuites As CONFIGVALUE;

Method OnAfterProductionStart() As %Status
{
	Return ..ParseAndRunTestSuites()
}

ClassMethod Run(pProductionName As %String, pTestSuite) As %Status
{
	Set ^UnitTestRoot = "/"

	Write "Running Tests...."

	Set validTests = 0

	/// TODO: Make this work for a list of testSuites rather than just 1
	#; For i=1:1:$LL(pTestSuites) {
	#; 	Write !,!,!
	#; 	Write "Finding test suite " _ i,!,!
	#; 	#dim testSuite As HS.Local.HSUK.Testing.Parser.Tests.TestSuite
	#; 	Set testSuite = $LG(pTestSuites, "")
	#; 	Write "TestSuite contains..."
	#; 	Write testSuite.SourceFile
	#; 	zw testSuite
	#; 	w testSuite.%Extends("ew.ew.ew")
	#; 	W testSuite.%IsA("Test")
	#; 	If ($LG(pTestSuites, i).%IsA("HS.Local.HSUK.Testing.Parser.Tests.TestSuite")) {
	#; 		Set validTests = validTests + 1
	#; 	}
	#; }

	#; If (validTests '= $LL(pTestSuites)) {
	#; 	Throw ##class(%Exception.General).%New("Invalid test suites","-483",,"One or more test suites provided to the Production Tester is invalid. Please ensure all test suites subclass the TestSuite class.")
	#; }

	/// Update the PRODUCTION parameter at runtime
	Set tSC = $System.OBJ.UpdateConfigParam($CLASSNAME(), "PRODUCTION", pProductionName)
	$$$ThrowOnError(tSC)

	Set tSC = $System.OBJ.UpdateConfigParam($CLASSNAME(), "TestSuites", pTestSuite)
	$$$ThrowOnError(tSC)
	// Run the super Run() method
	Do ##super()
}

Method ParseAndRunTestSuites() As %Status
{
	/// TODO:
	/// 	KEY POINT: USE ..LOGERRORS FOR NON-FATAL ERRORS OTHERWISE RETURN AN ERROR
	///				   STATUS CODE IF THE ERROR IS FATAL
	Set ts = ##class(HS.Local.HSUK.Testing.Parser.Parse).Run("")

	Do ..LogMessage("Running test definition file '" _ ts.SourceFile _ "'")
	
	/// Attempt to run all messages within this production
	Set tc = ts
	For i=1:1:ts.TestCases.Size {
		#dim testCase As HS.Local.HSUK.Testing.Parser.Tests.TestCase
		Set testCase = ts.TestCases.GetAt(i)

		/// Validate the TargetHostName
		/// Validate the TargetHostClass within the TestCase

		/// Run the interactions within the TestCase
		Set interactions = testCase.Interactions

		For j=1:1:testCase.Interactions.Size {
			#dim interaction As HS.Local.HSUK.Testing.Parser.Tests.Interaction
			Set interaction = testCase.Interactions.GetAt(j)

			/// Generate the Ens.Request message we will be sending into the
			/// production
			Set requestMessage = interaction.MessageRequest.GenerateMessageRequest()

			/// Send the message into the production
			Do ..SendRequest(testCase.TargetHostName, requestMessage, .responseMessage, 1)

			/// Now validate the response against what we expect
			zw responseMessage
			Do interaction.MessageResponse.ValidateResponse(responseMessage)
		}
	}

	Quit $$$OK
	#; Do pHost.Mess
	#; Set p = ##class(HS.Local.HSUK.Testing.PDS.ProductionTest).%New("")
	#; Do p.SendRequest(..TargetHostName, messageObj, .response, 1)

	#; Do $$$AssertFailure("TEST")
}

}
