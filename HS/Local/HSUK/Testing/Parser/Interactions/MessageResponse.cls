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

/// A recursive helper method which resolves a path in dot notation
/// e.g. "Name.Addresses[0].Street" and extracts that information
/// from the Response object <property>pObj</property>
Method ResolveDotPath(pPath As %String, pObj As Ens.Response)
{
}

/// A recursive helper method to extract all paths from a JSON object
Method BuildAllPaths(pJSON, Output paths As %ArrayOfDataTypes, curPath = "")
{
	Set JSONClass = $CLASSNAME(pJSON)

	/// Base case
	If (JSONClass = pJSON) {
		/// If the $CLASSNAME() returns the value itself, it means this value
		/// is a primitive
		Set curPath = $ZSTRIP(curPath, "<", ".")
		Do paths.SetAt(pJSON, curPath)
		Return
	}
	
	/// Otherwise we are only dealing with arrays or objects,
	/// we want to loop through and recursively build their paths
	/// If dealing with Arrays we use square bracket notation [0] for indexes
	/// and if dealing with Objects we use dot notation
	Set jsonIter = pJSON.%GetIterator()
	While jsonIter.%GetNext(.key, .value, .type) {
		Set resolvedPath = key
		If curPath '= "" {
			/// We are not at the root
			Set resolvedPath = curPath _ "." _ key
		}

		If ($CLASSMETHOD(JSONClass, "%Extends", "%DynamicObject")) {
			/// This is an object
			Set resolvedPath = curPath _ "." _ key
		} ElseIf ($CLASSMETHOD(JSONClass, "%Extends", "%DynamicArray")) {
			/// This is an array
			Set resolvedPath = curPath _ "[" _ key _ "]"
		}

		Do ..BuildAllPaths(value, .paths, resolvedPath)
	}
}

/// This validates the interaction to ensure the response we actually got back from
/// the production (ObjectScript:<property>pResponse</property>) matches the response
/// that we expected from this interaction (JSON:<property>MessageResponse</property>)
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
	Set JSON = ..Properties

	/// We loop through the JSON defined in the testing definition
	/// and ensure all values match, validators will override the behaviour used
	/// for the properties. We convert each path into the dot notation path
	/// and resolve it using <method>..ResolveDotPath</method>
	Set jsonIter = JSON.%GetIterator()
	Set JSONPaths = ##class(%ArrayOfDataTypes).%New()
	Do ..BuildAllPaths(..Properties, .JSONPaths)

	zw output

	Quit $$$OK
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
