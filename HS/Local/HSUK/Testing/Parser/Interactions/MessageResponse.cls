Class HS.Local.HSUK.Testing.Parser.Interactions.MessageResponse Extends HS.Local.HSUK.Testing.Parser.Interactions.Message
{

Property Validators As array Of HS.Local.HSUK.Testing.Parser.Validators.Validator;

/// For some reason the parent object is passed into p1
/// Ensure the "request" field is the %JSONFIELDNAME of Interaction.MessageRequest
ClassMethod %JSONNew(pJSON As %DynamicObject, pParent As %RegisteredObject) As %RegisteredObject
{
	/// Create a new message 
	Set response = pJSON.response
	Write "WE ARE HERE"
	Set message = ##super(pJSON, pParent)

	If (response.validators) {
		#dim validators As %DynamicObject
		Set validators = response.validators

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
