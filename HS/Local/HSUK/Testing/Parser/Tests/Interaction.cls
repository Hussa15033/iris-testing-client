Class HS.Local.HSUK.Testing.Parser.Tests.Interaction Extends (%SerialObject, %JSON.Adaptor)
{

Property MessageRequest As HS.Local.HSUK.Testing.Parser.Interactions.MessageRequest(%JSONFIELDNAME = "request");

Property MessageResponse As HS.Local.HSUK.Testing.Parser.Interactions.MessageResponse(%JSONFIELDNAME = "response");

/// This validates the interaction to ensure the response we actually got back from
/// the production (<property>pResponse</property>) matches the response
/// that we expected from this interact (<property>MessageResponse</property>)
/// 
/// May throw an error if there was a problem with validating the response
/// against the expected response
/// 
/// TODO: WE MAY NOT NEED THIS CLASS, CAN DIRECTLY DO THIS FROM MESSAGERESPONSE CLASS IN THE TESTCASE CLASS
Method ValidateInteraction(pResponse As Ens.Response) As %Status
{
	/// Loop through all properties in the MessageResponse to
	Quit ..MessageResponse.ValidateResponse(pResponse)
}

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
