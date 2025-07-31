Class HS.Local.HSUK.Testing.Parser.Tests.Interaction Extends (%SerialObject, %JSON.Adaptor)
{

Property MessageRequest As HS.Local.HSUK.Testing.Parser.Interactions.MessageRequest(%JSONFIELDNAME = "request");

Property MessageResponse As HS.Local.HSUK.Testing.Parser.Interactions.MessageResponse(%JSONFIELDNAME = "response");

Storage Default
{
<Data name="InteractionState">
<Value name="1">
<Value>MessageRequest</Value>
</Value>
<Value name="2">
<Value>MessageResponse</Value>
</Value>
</Data>
<State>InteractionState</State>
<StreamLocation>^HS.Local.HSUKAC16.InteractionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
