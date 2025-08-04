Class APTT.Definition.TestCase Extends (%SerialObject, %JSON.Adaptor)
{

Parameter %JSONENABLED = 1;

Property TargetHostName As %String(%JSONFIELDNAME = "name", MAXLEN = "");

Property TargetHostClass As %String(%JSONFIELDNAME = "class", MAXLEN = "");

Property Interactions As list Of APTT.Definition.Interaction(%JSONFIELDNAME = "interactions");

/// Runs the test suite, this will run all interactions against the TargetHost.
/// Verifies that the TargetHost has the TargetHostClass as it's class name
Method RunTestsOnProduction(pProduction As Ens.Config.Production)
{
	Set itemFound = ""
	#dim item As Ens.Config.Item

	For i=1:1:pProduction.Items.Count() {
		Set item = pProduction.Items.GetAt(i)
		If ((item.Name = ..TargetHostName) && (item.ClassName = ..TargetHostClass)) {
			Set itemFound = item
		}
	}

	If (itemFound = "") {
		Throw ##class(%Exception.General).%New("Item not found", "-193",,"Business host '" _ ..TargetHostName _ "' with class '" _ ..TargetHostClass _ "' not found")
	}

	#dim itemFound As Ens.Config.Item
	If ('itemFound.Enabled) {
		Throw ##class(%Exception.General).%New("Item not enabled", "-15",,"Business host '" _ ..TargetHostName _ "' with class '" _ ..TargetHostClass _ "' has not been enabled within production")
	}

	/// Loop through all interactions and run them
	For i=1:1:..Interactions.Size {
		Do ..RunInteraction(itemFound, ..Interactions.GetAt(i))
	}
	#; W host
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
<StreamLocation>^APTT.Definition.TestCaseS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
