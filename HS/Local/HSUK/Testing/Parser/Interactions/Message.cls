Class HS.Local.HSUK.Testing.Parser.Interactions.Message Extends %SerialObject [ Abstract ]
{

/// The type of message this is, should be either Ens.Request or Ens.Response
Parameter MESSAGECLASS [ Abstract ];

Property ClassName As %String;

Property Properties As %DynamicObject;

Method %JSONImportInternal() As %Status
{
	Quit $$$OK
}

/// TODO: MOVE THIS TO A UTIL CLASS
ClassMethod GetPropertyDefinition(pClassname, pProperty, Output Collection As %String, Output Type As %String)
{
	Set def = ##class(%Dictionary.CompiledProperty).%OpenId(pClassname _ "||" _ pProperty)
	If (def = "") {
		Throw ##class(%Exception.General).%New("Unable to find property","-77",,"Could not load property definition for property '" _ pProperty _ "' in class '" _ pClassname _ "', property does not exist")
	}

	Set Collection = def.Collection
	Set Type = def.Type
}

/// For some reason the parent object is passed into p1
/// Ensure the "request" field is the %JSONFIELDNAME of Interaction.MessageRequest
ClassMethod %JSONNew(pJSON As %DynamicObject, pParent As %RegisteredObject) As %RegisteredObject
{
	If ($PARAMETER(, "MESSAGECLASS") = "") {
		Throw ##class(%Exception.General).%New("Message class not specified","-883",,"The class " _ $CLASSNAME() _ " does not specify the MESSAGECLASS parameter. Please specify either Ens.Request or Ens.Response")
	}

	/// Create a new message 
	Set request = pJSON
	Set message = $CLASSMETHOD($CLASSNAME(), "%New")
	Set message.ClassName = request.class
	Set message.Properties = request.properties

	// 
	If ('$CLASSMETHOD(message.ClassName, "%Extends", ..#MESSAGECLASS)) {
		Throw ##class(%Exception.General).%New("Message class invalid","-882",,"Message class defined in test definition '" _ message.ClassName _ "' is not a child of '" _ ..#MESSAGECLASS _ "'")
	}

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
