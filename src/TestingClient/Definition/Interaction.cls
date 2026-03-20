/// 
/// Represents an interaction, which is a Request/Response message pair going into a component. The AsyncMessages can be used to
/// test for asynchronous messages after the interaction occurs.
/// 
/// @author Auwais Hussain (ahussain@intersystems.com)
/// @version 05.11.2025
/// 
Class TestingClient.Definition.Interaction Extends (%SerialObject, %JSON.Adaptor)
{

Property Name As %String(%JSONFIELDNAME = "name", MAXLEN = "");

Property MessageRequest As TestingClient.Definition.Messages.MessageRequest(%JSONFIELDNAME = "request");

Property MessageResponse As TestingClient.Definition.Messages.MessageResponse(%JSONFIELDNAME = "response");

Property AsyncMessages As list Of TestingClient.Definition.Messages.AsyncMessage(%JSONFIELDNAME = "asyncmessages");

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
<StreamLocation>^TestingClient.Definition.InteractionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
