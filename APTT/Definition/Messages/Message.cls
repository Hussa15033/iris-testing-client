/// 
/// Abstract message class used to encapsulate request and response messages
/// 
/// @author Auwais Hussain
/// @version 05.08.2025
/// 
Class APTT.Definition.Messages.Message Extends %SerialObject [ Abstract ]
{

/// The type of message this is, should be either Ens.Request or Ens.Response
Parameter MESSAGECLASS [ Abstract ];

/// The message class name
Property ClassName As %String;

/// Parsed JSON properties from the test definition file
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

/// <p>For some reason the parent object is passed into 'pJSON', so this method should be overridden
/// to pass the correct JSON object from the parent</p>
/// <p>Ensure the "request" field is the %JSONFIELDNAME of Interaction.MessageRequest</p>
/// <p><property>pJSON</property> - The parent JSON object from the test definition file</p>
/// <p><property>pParent</property> - The parent ObjectScript OBJECT</p>
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

	/// If the message class specified in the test does not extend the MESSAGECLASS parameter
	/// throw an error
	Set messageClassValid = 0
	Try {
		Set messageClassValid = $CLASSMETHOD(message.ClassName, "%Extends", ..#MESSAGECLASS)
	} Catch ex {
		Throw ##class(%Exception.General).%New("Message class invalid","-891",,"The message class '" _ message.ClassName _ "' defined in the test file could not be validated, ensure the class exists and has been compiled. Error: " _ ex.DisplayString())
	}

	If ('messageClassValid) {
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
<StreamLocation>^APTT.Definition.MeA057.MessageS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
