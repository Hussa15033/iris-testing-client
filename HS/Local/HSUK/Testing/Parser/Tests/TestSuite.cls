Class HS.Local.HSUK.Testing.Parser.Tests.TestSuite Extends (%SerialObject, %JSON.Adaptor)
{

Property SourceFile As %String(%JSONINCLUDE = "none");

Property TargetProduction As %String(%JSONFIELDNAME = "production");

Property TargetNamespace As %String(%JSONFIELDNAME = "namespace");

Property TestCases As list Of HS.Local.HSUK.Testing.Parser.Tests.TestCase(%JSONFIELDNAME = "tests");

Method RunTests() As %Status
{
	/// TODO: ENSURE THE PRODUCTION IS WORKING AND IS RUNNING AND IS IDLE
	Set prod = ##class(Ens.Config.Production).%OpenId(..TargetProduction)

	If ('$D(prod) || '$ISOBJECT(prod)) {
		Throw ##class(%Exception.General).%New("Failed to open production", "-1382",,"Failed to open production " _ ..TargetProduction)
	}

	New $NAMESPACE
	Set $NAMESPACE = ..TargetNamespace

	Write "Running Tests.."

	For i=1:1:..TestCases.Size {
		Set testCase = ..TestCases.GetAt(i)
		Write "Passing production into RunTestsOnProduction"
		Do testCase.RunTestsOnProduction(prod)
	}
}

Storage Default
{
<Data name="TestSuiteState">
<Value name="1">
<Value>SourceFile</Value>
</Value>
<Value name="2">
<Value>TargetProduction</Value>
</Value>
<Value name="3">
<Value>TargetNamespace</Value>
</Value>
<Value name="4">
<Value>TestCases</Value>
</Value>
</Data>
<State>TestSuiteState</State>
<StreamLocation>^HS.Local.HSUK.TeAC16.TestSuiteS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
