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

Method OnAfterProductionStart() As %Status
{
	Return ..ParseAndRunTestSuites()
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

			/// Generate the Ens.Request message we will be sending into the
			/// production
			Set requestMessage = interaction.MessageRequest.GenerateMessageRequest()

			/// Send the message into the production
			Do ..SendRequest(targetHostName, requestMessage, .responseMessage, 1)

			/// Now validate the response against what we expect
			zw responseMessage
			Set validation = interaction.MessageResponse.ValidateResponse(responseMessage)
			Return:'$$$ISOK(validation) validation
		}
	}

	Quit $$$OK
	#; Do pHost.Mess
	#; Set p = ##class(HS.Local.HSUK.Testing.PDS.ProductionTest).%New("")
	#; Do p.SendRequest(..TargetHostName, messageObj, .response, 1)

	#; Do $$$AssertFailure("TEST")
}

}
