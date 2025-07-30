Class HS.Local.HSUK.Testing.Parser.Tests.TestCase Extends (%SerialObject, %JSON.Adaptor)
{

Parameter %JSONENABLED = 1;

Property TargetHostName As %String(%JSONFIELDNAME = "name");

Property TargetHostClass As %String(%JSONFIELDNAME = "class");

Property Interactions As list Of HS.Local.HSUK.Testing.Parser.Tests.Interaction(%JSONFIELDNAME = "interactions");

// Property Interactions As list Of HS.Local.HSUK.Testing.Parser.Tests.Interaction(%JSONFIELDNAME = "interactions");

/// Runs the test suite, this will run all interactions against the TargetHost.
/// Verifies that the TargetHost has the TargetHostClass as it's class name
Method RunTestsOnProduction(pProductionName As %String)
{
	///
}

Method RunInteraction(pInteraction As HS.Local.HSUK.Testing.Parser.Tests.Interaction) [ Private ]
{
	/// Send the MessageRequest from the interaction and validate the response
}

Storage Default
{
<Data name="TestCaseState">
<Value name="1">
<Value>TargetHostName</Value>
</Value>
<Value name="2">
<Value>TargetHostClass</Value>
</Value>
<Value name="3">
<Value>Interactions</Value>
</Value>
</Data>
<State>TestCaseState</State>
<StreamLocation>^HS.Local.HSUK.TesAC16.TestCaseS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
