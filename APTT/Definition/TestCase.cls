Class APTT.Definition.TestCase Extends (%SerialObject, %JSON.Adaptor)
{

Parameter %JSONENABLED = 1;

Property TargetHostName As %String(%JSONFIELDNAME = "name", MAXLEN = "");

Property TargetHostClass As %String(%JSONFIELDNAME = "class", MAXLEN = "");

Property Interactions As list Of APTT.Definition.Interaction(%JSONFIELDNAME = "interactions");

}
