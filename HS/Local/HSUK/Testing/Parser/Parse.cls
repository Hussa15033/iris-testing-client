Class HS.Local.HSUK.Testing.Parser.Parse
{

/// Run the parser for a directory of .JSON test files
/// These files MUST end in ".json" to be picked up by this test utility
/// <property>pFileDirectory</property> - The directory in the file system which holds the .json test definitions
ClassMethod Run(pFileDirectory As %String) As HS.Local.HSUK.Testing.Parser.Tests.TestSuite
{
	Set pFilename = "C:\Users\ahussain\Desktop\NHS Interfaces\testing-client\fixtures.json"
	Set testSuite = ..ParseFile(pFilename)
	Return testSuite
	#; Do testSuite.RunTests()
}

ClassMethod ParseJSON(pJSON As %String)
{
	// Each JSON file contains a test suite with potentiatially multiple test cases
	// Test cases focus on 1 single component and runs and tests many interactions
}

ClassMethod ParseFile(pFilepath As %String) As HS.Local.HSUK.Testing.Parser.Tests.TestSuite
{
	If ('##class(%File).Exists(pFilepath)) {
		Write "Test"
		Throw ##class(%Exception.General).%New("File does not exist",2,,"The test definition file '" _ pFilepath _ "' does not exist")
		Return 0
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

	Set testSuite = ##class(HS.Local.HSUK.Testing.Parser.Tests.TestSuite).%New()
	Set testSuite.SourceFile = pFilepath
	Set tSC = testSuite.%JSONImport(data)

	$$$ThrowOnError(tSC)

	Return testSuite
}

}
