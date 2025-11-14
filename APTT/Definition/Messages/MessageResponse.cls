/// 
/// The message response class for holding validators and response message
/// definitions from the test definition file
/// 
/// @author Auwais Hussain (ahussain@intersystems.com)
/// @version 05.08.2025
/// 
Class APTT.Definition.Messages.MessageResponse Extends APTT.Definition.Messages.Message
{

Parameter MESSAGECLASS = "Ens.Response";

Property Validators As array Of APTT.Definition.Validators.Base;

Property ResultStore As array Of %String;

Property ExpectedErrors As list Of %String;

Property ExpectedErrorCount As %Integer [ InitialExpression = 0 ];

/// For some reason the parent object is passed into p1
/// Ensure the "response" field is the %JSONFIELDNAME of Interaction.MessageRequest
ClassMethod %JSONNew(pJSON As %DynamicObject, pParent As %RegisteredObject) As %RegisteredObject
{
	#dim responseJSON As %DynamicObject
	Set responseJSON = pJSON.response
	If (responseJSON = "") {
		Throw ##class(%Exception.General).%New("Invalid JSON","-11",,"The 'response' property does not exist for interaction")
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
			Set validatorClass = "APTT.Definition.Validators." _ value.validator
			Set validatorOptions = value.options

			Try {
				Set validator = $CLASSMETHOD(validatorClass, "%New", validatorOptions)
			} Catch ex {
				Write "Validator class " _ validatorClass _ " could not be instantiated " _ ex.DisplayString()
				Throw ##class(%Exception.General).%New("Failed to initialise validator","-499",,"The validator class '" _ validatorClass _ "' could not be initialised: " _ ex.DisplayString())
			}
			Do message.Validators.SetAt(validator, fieldName)
		}
	}

	/// If any storage variables have been defined, add them to the ResultStore array
	If (responseJSON.%IsDefined("store")) {
		#dim store As %DynamicObject
		Set store = responseJSON.%Get("store")

		Set iter = store.%GetIterator()

		/// Update the result store
		While (iter.%GetNext(.path, .varName, .type)) {
			Do message.ResultStore.SetAt(varName, path)
		}
	}

	If (responseJSON.%IsDefined("errors")) {
		Set errors = responseJSON.errors
		Set dataType = responseJSON.%GetTypeOf("errors")

		If (dataType = "array") {
			/// This is a list of known errors expected by this business host
			Set iter = errors.%GetIterator()
			While (iter.%GetNext(.key, .value, .type)) {
				If (type '= "string") {
					Throw ##class(%Exception.General).%New("Invalid data type","-420",,"'error' field in response must be an array of strings")
				}

				Do message.ExpectedErrors.Insert(value)
			}

			Set message.ExpectedErrorCount = message.ExpectedErrors.Size
		} ElseIf (dataType = "number") {
			Set message.ExpectedErrorCount = errors
		} Else {
			Throw ##class(%Exception.General).%New("Invalid data type", "-419",,"'error' field in response must be either an integer or array of strings")
		}
	}

	Return message
}

/// A recursive helper method which resolves a path in dot notation
/// e.g. "Name.Addresses[0].Street" and extracts that information
/// from the Response object <property>pObj</property>
Method ResolveDotPath(pPath As %String, pObj As Ens.Response)
{
	Set splitPaths = $LISTFROMSTRING(pPath,".")
	Set curObj = pObj

	For i=1:1:$LL(splitPaths) {
		/// Default values
		Set fieldName = $LISTGET(splitPaths, i, "")
		Set index = ""
		Set indexes = ""

		If (fieldName [ "[") {
			/// If the value contains square brackets, it means this is square bracket notation for a list
			Set extractField = $LISTFROMSTRING(fieldName, "[")
			Set fieldName = $LISTGET(extractField, 1)
			Set indexes = $lb()

			/// We loop from the 2nd position onwards to extract all the indexes
			/// to deal with the case of multidimensional lists
			Set pos = 2
			While $LISTDATA(extractField, pos) {
				Set index = $LISTGET(extractField, pos, "")
				If index '= "" {
					/// Each index will be in the format of 3], 4], etc..
					/// So we need to extract the actual index by removing the "]" char at the end
					Set indexes = $LISTUPDATE(indexes, pos - 1, 1:$EXTRACT(index, 1, *-1))
				}

				Do $I(pos)
			}
		}

		/// Traverse the object, checking if it is an array
		Try {
			Set propertyValue = $PROPERTY(curObj, fieldName)
		} Catch ex {
			Throw ##class(%Exception.General).%New("Path resolve error","-413",,"Field '" _ fieldName _ "' not found within response object of class '" _ $CLASSNAME(pObj) _ "' while attempting to resolve path '" _ pPath _ "'")
		}

		Do ..GetPropertyDefinition($CLASSNAME(curObj), fieldName, .CollectionType, .DataType)

		If CollectionType = "array" {
			Set i = i + 1
			Set key = $LISTGET(splitPaths, i, "")
			If (key = "") {
				/// If this is an array, it's represented as an object, there should not be an index being used
				Throw ##class(%Exception.General).%New("Path resolve error for path '" _ pPath _ "'","-411",,"Field " _ fieldName _ " is an array within " _ $CLASSNAME(pObj) _ " response message, a key must be specified within the path")
			}

			/// Since this is an array, we want to extract the field
			Set curObj = propertyValue.GetAt(key)
			If curObj = "" {
				/// Find possible options of the key within this array
				Set possibleOptions = ""
				Set arrKey = propertyValue.Next("")
				While arrKey '= "" {
					Set possibleOptions = possibleOptions _ arrKey _ ","
					Set arrKey = propertyValue.Next(arrKey)
				}
				Throw ##class(%Exception.General).%New("Path resolve error for path '" _ pPath _ "'","-415",,"Field '" _ fieldName _ "' is an array within " _ $CLASSNAME(pObj) _ " response message, could not resolve key " _ key _ " within array, possible options for key: " _ possibleOptions)
			}
		} ElseIf CollectionType = "list" {
			If ((indexes = "") || ($LISTLENGTH(indexes) = 0)) {
				/// This property is a list, but no index was specified
				Throw ##class(%Exception.General).%New("Path resolve error for path '" _ pPath _ "'","-412",,"Field '" _ fieldName _ "' is a list within " _ $CLASSNAME(pObj) _ " response message, no index was specified by path -- ensure this field contains a JSON array within the JSON test definition file")
			}
			
			Set iKey = 1
			set listObj = propertyValue
			While iKey < $LISTLENGTH(indexes) {
				Set objClass = $CLASSNAME(curObj)
				If (objClass = "") || '$CLASSMETHOD(objClass, "%Extends", "%Collection.AbstractList") {
					Throw ##class(%Exception.General).%New("Path resolve error for path '" _ pPath _ "'", "-413",,"Could not access indices for field '" _ fieldName _ "', this list has the incorrect number of dimensions for the given path. Dimensions resolved: " _ iKey _ ", Dimensions expected: " _ $LISTLENGTH(indexes) _ ". Please check the test definition file to ensure all lists have the correct number of sublists")
				}

				Set listObj = listObj.GetAt($LISTGET(indexes, iKey))

				Do $I(iKey)
			}
			Set curObj = propertyValue.GetAt(index + 1)
		} Else {
			If (index '= "") {
				Throw ##class(%Exception.General).%New("Path resolve error for path '" _ pPath _ "'","-412",,"Field '" _ fieldName _ "' is NOT a list within " _ $CLASSNAME(pObj) _ " response message, unknown index specified: '" _ index _ "'")
			}
			Set curObj = propertyValue
		}
	}

	Return curObj
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
/// the production (ObjectScript:<property>pMessage</property>) matches the response
/// that we expected from this interaction (JSON:<property>MessageResponse</property>)
/// 
/// May throw an error if there was a problem with validating the response
/// against the expected response
/// 
/// The default behaviour is to check all fields of the actual <property>pMessage</property>
/// match the fields exactly as shown in <property>..Properties</property>, however the validators
/// specified in <property>..Validators</property> will overwrite the default behaviour
/// 
Method ValidateResponse(pMsgHeader As Ens.MessageHeader, Output pStorage As %DynamicObject = "") As %Status
{
	If (pStorage = "") {
		Set pStorage = {}
	}
	Set pMessage = $CLASSMETHOD(pMsgHeader.MessageBodyClassName, "%OpenId", pMsgHeader.MessageBodyId)
	If ($CLASSNAME(pMessage) '= ..ClassName) {
		Throw ##class(%Exception.General).%New("Invalid class","-553",,"Expected response of type '" _ ..ClassName _ "' but actual response was of type '" _ pMsgHeader.MessageBodyClassName _ "'")
	}
	Set JSON = ..Properties

	/// We loop through the JSON defined in the testing definition
	/// and ensure all values match, validators will override the behaviour used
	/// for the properties. We convert each path into the dot notation path
	/// and resolve it using <method>..ResolveDotPath</method>
	Set jsonIter = JSON.%GetIterator()
	Set JSONPaths = ##class(%ArrayOfDataTypes).%New()

	/// Build all the paths in dot notation form for ..Properties
	Do ..BuildAllPaths(..Properties, .JSONPaths)

	/// Loop through all validators to ensure the fields exist, if they don't
	/// throw an error to say the path specified by the validator is not valid
	Set vPath = ..Validators.Next("")
	While vPath '= "" {
		If ('JSONPaths.IsDefined(vPath)) {
			/// The path specified by the validator is non existent in the mapped paths of the 
			/// JSON test definition
			Throw ##class(%Exception.General).%New("Validation path '" _ vPath _ "' does not exist","-330",,"Path specified by validator is NOT a valid path. Please ensure all validators lead to an existing path within the JSON response test definition")
		}
		Set vPath = ..Validators.Next(vPath)
	}

	/// Loop through all storage variables and update the pStorage parameter
	Set sPath = ..ResultStore.Next("")
	While sPath '= "" {
		If ('JSONPaths.IsDefined(sPath)) {
			Throw ##class(%Exception.General).%New("Storage path '" _ sPath _ "' does not exist", "-331",,"Path specified by 'store' key is NOT a valid path. Please ensure all storage paths lead to an existing path within the JSON response test definition")
		}
		Set sPath = ..ResultStore.Next(sPath)
	}

	/// By this point, all paths specified in the "Validators" key exist

	/// Once all paths have been created, we default to using the EqualsValidator on all paths
	/// that do not have a custom validator set up:
	Set path = JSONPaths.Next("")
	While path '= "" {
		Set expectedValue = JSONPaths.GetAt(path)
		If '..Validators.IsDefined(path) {
			/// If no validator is specified for this path, we use the default validator
			Set validator = ##class(APTT.Definition.Validators.EqualsValidator).%New("")
			Do ..Validators.SetAt(validator, path)
		}

		/// Now run the validator for this path, resolving the path as needed with
		/// the method <method>..ResolveDotPath()</method>
		Set actualValue = ..ResolveDotPath(path, pMessage)
		Set validator = ..Validators.GetAt(path)

		If ..ResultStore.IsDefined(path) {
			/// This path is defined by the result store, update the storage variable
			Do pStorage.%Set(..ResultStore.GetAt(path), actualValue)
		}

		/// Run the validator, will throw a validation error if one occurs

		Try {
			Set tSC = validator.Validate(expectedValue, actualValue)
			$$$ThrowOnError(tSC)
		} Catch ex {
			Set ex.Data = "Failed validation on field " _ path _ ": " _ ex.DisplayString()
			Throw ex
		}

		Set path = JSONPaths.Next(path)
	}

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
<Value name="4">
<Value>ExpectedErrors</Value>
</Value>
<Value name="5">
<Value>ExpectedErrorCount</Value>
</Value>
<Value name="6">
<Value>ResultStore</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
