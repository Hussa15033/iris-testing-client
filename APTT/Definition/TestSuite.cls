/// 
/// A test suite is the foundation of a test definition file. It takes in a list of test cases aimed at various
/// components within the production. It is recommended to separate tests on a per-component basis, having 1 file
/// testing 1 component.
/// 
/// @author Auwais Hussain (ahussain@intersystems.com)
/// @version 05.08.2025
/// 
Class APTT.Definition.TestSuite Extends (%SerialObject, %JSON.Adaptor)
{

Property SourceFile As %String(%JSONINCLUDE = "none");

Property TargetProduction As %String(%JSONFIELDNAME = "production");

Property TargetNamespace As %String(%JSONFIELDNAME = "namespace");

Property TestCases As list Of APTT.Definition.TestCase(%JSONFIELDNAME = "tests");

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
<StreamLocation>^APTT.Definition.TestSuiteS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
