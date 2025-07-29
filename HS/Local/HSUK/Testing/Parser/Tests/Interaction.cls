Class HS.Local.HSUK.Testing.Parser.Tests.Interaction
{

Property MessageRequest As HS.Local.HSUK.Testing.Parser.Interactions.MessageRequest;

Property MessageResponse As HS.Local.HSUK.Testing.Parser.Interactions.MessageResponse;

Method %OnNew(pMessageRequest As HS.Local.HSUK.Testing.Parser.Interactions.MessageRequest, pMessageResponse As HS.Local.HSUK.Testing.Parser.Interactions.MessageResponse)
{
	Set ..MessageRequest = pMessageRequest
	Set ..MessageResponse = pMessageResponse
}

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

}
