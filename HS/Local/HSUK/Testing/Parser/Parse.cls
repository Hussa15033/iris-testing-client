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
	Set TestSuites = ##class(%ListOfObjects).%New()

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

	While rSet.%Next() {
		Try {
			Set path = ##class(%File).NormalizeFilename(rSet.%Get("Name"))
			Do ##class(APTT.Utils).Log("Parsing test definition file '" _ ##class(%File).GetFilename(path) _ "'...", "Init", 0)
			Set testSuite = ..LoadFile(path)

			/// Throw errors if any of the test definition files have a different target namespace or production
			Throw:$NAMESPACE'=testSuite.TargetNamespace ##class(%Exception.General).%New("Incorrect namespace","-93",,"The namespace specified '" _ testSuite.TargetNamespace _ "' is different to the selected namespace '" _ $NAMESPACE _ "'. Ensure all test definition files have the same target namespace")
			Throw:production'=testSuite.TargetProduction ##class(%Exception.General).%New("Incorrect production","-93",,"The production specified '" _ testSuite.TargetProduction _ "' is different to the selected production '" _ production _ "'. Ensure all test definition files have the same target production")

			Do TestSuites.Insert(testSuite)

			/// TODO: Find a more elegant way to obtain a total test count, maybe even move this whole method to the
			/// ProductionTester class and have this as a util function
			/// Count how many test cases there are
			Set tKey = testSuite.TestCases.Next("")
			While tKey '= "" {
				Set pTestCount = pTestCount + testSuite.TestCases.GetAt(tKey).Interactions.Size
				Set tKey = testSuite.TestCases.Next(tKey)
			}

			Write "success",!
		} Catch ex {
			Write !
			Do ##class(APTT.Utils).Log(ex.AsSystemError(), "Parsing Error")
			Throw ex
		}
	}
	
	If TestSuites.Size = 0 {
		Do ##class(APTT.Utils).Log("No test suites found", "Init")
	} Else {
		Do ##class(APTT.Utils).Log("Identified " _ TestSuites.Size _ " test suites to run", "Init")	
	}
	H 2
	Return TestSuites
}

/// 
/// Parses a file using the test definition JSON model
/// 
ClassMethod LoadFile(pFilepath As %String) As APTT.Tests.TestSuite [ Private ]
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

	Set testSuite = ##class(APTT.Tests.TestSuite).%New()
	Set testSuite.SourceFile = pFilepath
	Set tSC = testSuite.%JSONImport(data)

	$$$ThrowOnError(tSC)

	Return testSuite
}

}
