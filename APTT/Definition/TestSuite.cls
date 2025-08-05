Class APTT.Definition.TestSuite Extends (%SerialObject, %JSON.Adaptor)
{

Property SourceFile As %String(%JSONINCLUDE = "none");

Property TargetProduction As %String(%JSONFIELDNAME = "production");

Property TargetNamespace As %String(%JSONFIELDNAME = "namespace");

Property TestCases As list Of APTT.Definition.TestCase(%JSONFIELDNAME = "tests");


}
