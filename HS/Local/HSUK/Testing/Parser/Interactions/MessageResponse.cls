Class HS.Local.HSUK.Testing.Parser.Interactions.MessageResponse Extends HS.Local.HSUK.Testing.Parser.Interactions.Message
{

/// Validate the response to ensure all of the expected properties
/// within <property>Properties</property>) appear and are valid as shown in
/// the actual response - <property>pResponse</property>.
Method ValidateResponse(pResponse As Ens.Response) As %Status
{
	/// Check if we have any validators
}

Storage Default
{
<Data name="MessageState">
<Value name="1">
<Value>ClassName</Value>
</Value>
<Value name="2">
<Value>Properties</Value>
</Value>
<Value name="3">
<Value>Validators</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
