/// 
/// Auwais's Production Testing Tool
/// 
/// Main entry point of the APTT utility
/// To use this utility, define your test definitions as ".json" files within 
/// a test directory
/// 
/// Call the Run method as follows:
/// 	- Do ##class(APTT.Parser).Run("/path/to/your/test/definitions")
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
ClassMethod Run(pFileDirectory As %String) As %Status
{
	Do ##class(APTT.Utils).Log("Initialising parser...", "Init")

	Set dir = ##class(%File).%New(pFileDirectory)
	If ('##class(%File).DirectoryExists(pFileDirectory)) {
		Do ##class(APTT.Utils).Log("Directory '" _ pFileDirectory _ "' does not exist.. exiting", "Init")
		Return $System.Status.Error("InitFailed", "Specified directory '" _ pFileDirectory _ "' does not exist")
	}

	Do ##class(APTT.Utils).Log("Parsing directory " _ pFileDirectory, "Init")

	Set stmt = ##class(%SQL.Statement).%New()
	Set status = stmt.%PrepareClassQuery("%File", "FileSet")
	$$$ThrowOnError(status)

	Set rSet = stmt.%Execute(pFileDirectory, "*.json")
	If (rSet.%SQLCODE '= 0) {
		Do ##class(APTT.Utils).Log("File query failed, SQL CODE=" _ rSet.%SQLCOD _ ", MESSAGE=" _ rSet.%Message)
		Return $System.Status.Error("File Query ERROR", "Could not query directory for files: '" _ pFileDirectory _ "'")
	}

	Set testSuites = ##class(%ListOfObjects).%New()
	While rSet.%Next() {
		Try {
			Set path = ##class(%File).NormalizeFilename(rSet.%Get("Name"))
			Do ##class(APTT.Utils).Log("Parsing test definition file '" _ ##class(%File).GetFilename(path) _ "'...", "Init", 0)
			Set testSuite = ..LoadFile(path)
			Do testSuites.Insert(testSuite)

			Write "success",!
		} Catch ex {
			Write !
			Do ##class(APTT.Utils).Log(ex.AsSystemError(), "Parsing Error")
			Return $System.Status.Error("Parsing Error", ex.AsSystemError())
		}
	}
	
	Do ##class(APTT.Utils).Log("Identified " _ testSuites.Size _ " test suites to run", "Init")
	Do ##class(APTT.Utils).Log("Starting tests..", "Init")
	
	H 3
	Return $$$OK
}

/// 
/// Parses a file using the test definition JSON model
/// 
ClassMethod LoadFile(pFilepath As %String) As HS.Local.HSUK.Testing.Parser.Tests.TestSuite [ Private ]
{
	If ('##class(%File).Exists(pFilepath)) {
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
