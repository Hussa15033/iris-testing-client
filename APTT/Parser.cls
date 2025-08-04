/// 
/// A Parser utility for loading test definition .JSON files
/// 
/// @author Auwais Hussain
/// @version 04.08.2025
/// 
Class APTT.Parser
{

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
