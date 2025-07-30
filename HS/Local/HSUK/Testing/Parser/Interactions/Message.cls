Class HS.Local.HSUK.Testing.Parser.Interactions.Message Extends %SerialObject [ Abstract ]
{

Property ClassName As %String;

Property Properties As %DynamicObject;

Method %JSONImportInternal() As %Status
{
	Quit $$$OK
}

/// For some reason the parent object is passed into p1
/// Ensure the "request" field is the %JSONFIELDNAME of Interaction.MessageRequest
ClassMethod %JSONNew(pJSON As %DynamicObject, pParent As %RegisteredObject) As %RegisteredObject
{

	/// Create a new message 
	Set request = pJSON.request
	Set message = $CLASSMETHOD($CLASSNAME(), "%New")
	Set message.ClassName = request.class
	Set message.Properties = request.properties

	Return message
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
</Data>
<State>MessageState</State>
<StreamLocation>^HS.Local.HSUK.TestB95F.MessageS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
