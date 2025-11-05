Class APTT.Definition.Interaction Extends (%SerialObject, %JSON.Adaptor)
{

Property Name As %String(%JSONFIELDNAME = "name");

Property MessageRequest As APTT.Definition.Messages.MessageRequest(%JSONFIELDNAME = "request");

Property MessageResponse As APTT.Definition.Messages.MessageResponse(%JSONFIELDNAME = "response");

Property AsyncMessages As list Of APTT.Definition.Messages.AsyncMessage(%JSONFIELDNAME = "asyncmessages");

Storage Default
{
<Data name="InteractionState">
<Value name="1">
<Value>MessageRequest</Value>
</Value>
<Value name="2">
<Value>MessageResponse</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>AsyncMessages</Value>
</Value>
</Data>
<State>InteractionState</State>
<StreamLocation>^APTT.Definition.InteractionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
