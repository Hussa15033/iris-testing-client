Class APTT.Definition.TestCase Extends (%SerialObject, %JSON.Adaptor)
{

Parameter %JSONENABLED = 1;

Property TargetHostName As %String(%JSONFIELDNAME = "name", MAXLEN = "");

Property TargetHostClass As %String(%JSONFIELDNAME = "class", MAXLEN = "");

Property Interactions As list Of APTT.Definition.Interaction(%JSONFIELDNAME = "interactions");

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
