Class HS.Local.HSUK.Testing.Parser.Interactions.MessageResponse Extends HS.Local.HSUK.Testing.Parser.Interactions.Message
{

Parameter MESSAGECLASS = "Ens.Response";

Property Validators As array Of HS.Local.HSUK.Testing.Parser.Validators.Validator;

/// For some reason the parent object is passed into p1
/// Ensure the "response" field is the %JSONFIELDNAME of Interaction.MessageRequest
ClassMethod %JSONNew(pJSON As %DynamicObject, pParent As %RegisteredObject) As %RegisteredObject
{
	Set responseJSON = pJSON.response
	If (responseJSON = "") {
		Throw ##class(%Exception.General).%New("Invalid JSON","-11",,"The request property does not exist for interaction")
	}

	/// Create a new message 
	Set message = ##super(responseJSON, pParent)

	/// If any properties have validators attached, parse them and create the validator
	If (responseJSON.validators) {
		#dim validators As %DynamicObject
		Set validators = responseJSON.validators

		Set iter = validators.%GetIterator()

		/// Loop through all validators for this response
		/// and attempt to create the validator with the
		/// options
		While (iter.%GetNext(.key, .value, .type)) {
			Set fieldName = key
			Set validatorClass = "HS.Local.HSUK.Testing.Parser.Validators." _ value.validator
			Set validatorOptions = value.options

			Set validator = $CLASSMETHOD(validatorClass, "%New", validatorOptions)
			Do message.Validators.SetAt(validator, fieldName)
		}
	}

	Return message
}

/// This validates the interaction to ensure the response we actually got back from
/// the production (<property>pResponse</property>) matches the response
/// that we expected from this interact (<property>MessageResponse</property>)
/// 
/// May throw an error if there was a problem with validating the response
/// against the expected response
/// 
/// The default behaviour is to check all fields of the actual <property>pResponse</property>
/// match the fields exactly as shown in <property>..Properties</property>, however the validators
/// specified in <property>..Validators</property> will overwrite the default behaviour
/// 
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
