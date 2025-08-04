/// 
/// Auwais's Production Testing Tool
/// 
/// Main entry point of the APTT utility
/// 
/// 
/// THIS CLASS SHOULD NOT BE USED DIRECTLY.
/// 
/// Instantiate within the context of the UnitTest Manager, define your test definitions as ".json" files within 
/// a test directory
/// 
/// Call the Run method as follows:
/// 	- Do ##class(APTT.Parser).Parse("/path/to/your/test/definitions", productionToTest)
/// 
/// 
/// This will automatically load and run all of your defined tests
/// 
/// @author Auwais Hussain
/// @version 0.8.0
/// 
Class APTT.Parser
{

/// Run the parser for a directory of .JSON test files
/// These files MUST end in ".json" to be picked up by this test utility
/// <property>pFileDirectory</property> - The directory in the file system which holds the .json test definitions
ClassMethod Parse(pFileDirectory As %String, production As %String, Output pTestCount) As %ListOfObjects
{
	Return TestSuites
}

/// 
/// Parses a file using the test definition JSON model
/// 
ClassMethod LoadFileAsTestSuite(pFilepath As %String) As APTT.Tests.TestSuite
{
	If ('##class(%File).Exists(pFilepath)) {
		Throw ##class(%Exception.General).%New("File does not exist",2,,"The test definition file '" _ pFilepath _ "' does not exist")
		Return ""
	}

	Set file = ##class(%File).%New(pFilepath)
	Set tSC = file.Open("R")
	$$$ThrowOnError(tSC)

	Set data = ""

	while ('file.AtEnd) {
		Set data = data _ file.Read(,.tSC)
		$$$ThrowOnError(tSC)
	}

	Do file.Close()

	Set testSuite = ##class(APTT.Tests.TestSuite).%New()
	Set testSuite.SourceFile = pFilepath
	Set tSC = testSuite.%JSONImport(data)
	$$$ThrowOnError(tSC)

	Return testSuite
}

}
