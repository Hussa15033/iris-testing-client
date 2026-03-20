/// 
/// The message request class which parses request messages from the test definition file
/// 
/// @author Auwais Hussain (ahussain@intersystems.com)
/// @version 05.08.2025
/// 
Class TestingClient.Definition.Messages.MessageRequest Extends TestingClient.Definition.Messages.Message
{

/// Message classes from the test definition file MUST be a child of Ens.Request
Parameter MESSAGECLASS = "%Persistent";

Property Fill As %DynamicObject;

/// 
/// <p>Parse JSON object into an instance of this MessageRequest class</p>
/// <p><property>pJSON</property> - The JSON object to parse</p>
/// <p><property>pParent</property> - The parent ObjectScript OBJECT</p>
ClassMethod %JSONNew(pJSON As %DynamicObject, pParent As %RegisteredObject) As %RegisteredObject
{
	Set requestJSON = pJSON.request
	If (requestJSON = "") {
		Throw ##class(%Exception.General).%New("Invalid JSON","-11",,"The request property does not exist for interaction")
	}

	Return ##super(requestJSON, pParent)
}

/// 
/// <p>This method generates an object of the message class specified in the test definition file, this value is
/// stored in the <property>ClassName</property> property</p>
/// 
/// <p>It attempts to populate the <property>..Properties</property> property using the
/// <method>..PopulateObjectFromJSON</method> method</p>
/// 
/// <p>This method will throw an error if it fails to populate any properties of the message class</p>
/// 
/// <p>Nested object properties will also be instantiated and populated</p>
/// 
Method GenerateMessageRequest(pStorage As %DynamicObject = "")
{
	If (pStorage = "") {
		Set pStorage = {}
	}

	Set ..Fill = pStorage
	#dim messageObj As Ens.Request
	Try {
		Set messageObj = $CLASSMETHOD(..ClassName, "%New")
	} Catch ex {
		Throw ##class(%Exception.General).%New("Failed to instantiate message","-17",,"The request message class specified in the test definition file '" _ ..ClassName _ "' could not be instantiated. Ensure this is a valid message class (error = " _ ex.DisplayString() _ ")")
	}
	Do ..PopulateObjectFromJSON(.messageObj, ..Properties)

	Return messageObj
}

/// Helper method for assertion
Method AssertEquals(pStr1, pStr2, pFailMessage) As %Status [ Private ]
{
	If (pStr1 '= pStr2) {
		Throw ##class(%Exception.General).%New("Equal Assertion Failed","-39",,pStr1 _ " != " _ pStr2 _ ": " _ pFailMessage)
	}

	Quit $$$OK
}

/// A helper method to populate the properties of an object, given the object, and the corresponding
/// JSON object, will throw an error if any properties cannot be set
/// Todo: Move this method to a helper class, along with the reverse method of turning an object to JSON
Method PopulateObjectFromJSON(Output pObj As %RegisteredObject, pJSON As %DynamicObject)
{
	If ('$ISOBJECT(pJSON) || 'pJSON.%Extends("%DynamicObject")) {
		Throw ##class(%Exception.General).%New("Cannot populate object","-303",,"Cannot populate ObjectScript object of type " _ $CLASSNAME(pObj) _ " as JSON is not a valid %DynamicObject.")
	}

	/// This method loops through all of the properties in the JSON and sets their value in the
	/// objectscript object. This is a recursive method and will populate
	/// serial objects within that object from the JSON
	Set mIter = pJSON.%GetIterator()

	While mIter.%GetNext(.key, .value, .jsonType) {
		Do ..GetPropertyDefinition($CLASSNAME(pObj), key, .CollectionType, .DataType)

		Set OSType = $CLASSNAME($PROPERTY(pObj, key))
		#; w !,"Key " _ key,!
		#; W "ObjectScript value: " _ value,!
		#; w "ObjectScript type: "_OSType,!
		#; w "ObjectScript type 2: " _ CollectionType _ "||" _ DataType,!
		#; w "JSON Type: " _ jsonType,!

		If ((OSType = value) || (OSType = "")) {
			/// The objectscript type is a string, check if it is a variable (in format ${varname}, inspired by Gitlab)
			If (($EXTRACT(value, 1, 2) = "${") && (value [ "}")) {
				/// Likely a variable, extract the variable name
				Set varName = $EXTRACT(value, 3, *-1)
				If (..Fill.%IsDefined(varName)) {
					Set varValue = ..Fill.%Get(varName)
					Set value = varValue
				} Else {
					Throw ##class(%Exception.General).%New("Cannot create request message: variable does not exist","-3392",,"The variable " _ varName _ " does not exist - cannot populate message, Key: " _ key _ ", JSON: " _ value)
				}
			}
		}

		If ($CLASSMETHOD(DataType, "%Extends", "%Stream.Object")) && ((jsonType = "string") || (jsonType = "number") || (jsonType = "boolean")) {
			/// The ObjectScript property is a Stream and the JSON is a primitive type
			/// Write the JSON primitive to the stream
			Try {
				If ($METHOD(pObj, "%Extends", "Ens.StreamContainer")) {
					// The Object is a stream container, NOT a stream, so we need to initialise the stream
					Set tempStream = ##class(%Stream.GlobalCharacter).%New()
					Do tempStream.Write(value)
					Set tSC = pObj.StreamSet(tempStream)
				} Else {
					Set tSC = $METHOD($PROPERTY(pObj, key), "Write", value)
				}
			} Catch ex {
				Throw ##class(%Exception.General).%New("Failed to set stream property","-18",,"Failed to set the property '" _ key _ "' in request message. Check that this property exists and is not ReadOnly (error = " _ ex.DisplayString() _ ")")
			}
			Throw:$$$ISERR(tSC) ##class(%Exception.StatusException).ThrowIfInterrupt(tSC)
		 } ElseIf ((OSType = value) || (OSType = "")) && ((jsonType = "string") || (jsonType = "number") || (jsonType = "boolean")) {
			/// Both the JSON and ObjectScript field are primitive data types, simply set the property value
			Try {
				Set $PROPERTY(pObj, key) = value
			} Catch ex {
				Throw ##class(%Exception.General).%New("Failed to set property","-18",,"Failed to set the property '" _ key _ "' in request message. Check that this property exists and is not ReadOnly (error = " _ ex.DisplayString() _ ")")
			}
		} ElseIf (CollectionType = "list") {
			Do ..AssertEquals(jsonType, "array")

			/// We are mapping an array in JSON to either a list of primitive data types in ObjectScript
			/// or a list of Complex objects in ObjectScript
			/// We loop over the values in the JSON array and insert them into the list in ObjectScript
			#dim list As %Collection.AbstractList
			#dim value As %DynamicArray
			Set list = $PROPERTY(pObj, key)
			Set jsonArrayIterator = value.%GetIterator()
			While jsonArrayIterator.%GetNext(.key1, .value1, .type1) {
				Set insertVal = ""
				If $CLASSMETHOD(OSType, "%Extends", "%Collection.ListOfDT") {
					/// Since we are mapping to a list of primitive data types in ObjectScript,
					/// we can simply insert this into the list
					Set insertVal = value1
				} ElseIf ($CLASSMETHOD(OSType, "%Extends", "%Collection.ListOfObj")) {
					/// We are inserting into a list of Complex objects, we need to instantiate the object,
					/// populate it then insert
					/// We mapping an array of JSON objects in a JSON array to a list of Complex object types in ObjectScript
					/// First determine the type of the object in ObjectScript, this is stored in the PropertyDefinition
					/// and extracted to the 'DataType' variable
					Set insertVal = $CLASSMETHOD(DataType, "%New")
					Do ..PopulateObjectFromJSON(.insertVal, value1)
				}
				Do list.Insert(insertVal)
			}
		} ElseIf (CollectionType = "array") {
			Do ..AssertEquals(jsonType, "object")

			/// We are mapping to an array of primitives/Complex Objects in ObjectScript, this should be stored in a JSON object
			/// with the key->value mapping remaining the same.
			/// We loop through all key/value pairs in the JSON and use SetAt to set the assoc array in ObjectScript

			#dim arr As %Collection.AbstractArray
			Set arr = $PROPERTY(pObj, key)
			Set jsonObjectIterator = value.%GetIterator()
			While jsonObjectIterator.%GetNext(.key1, .value1, .type1) {
				Set putVal = ""
				If ($CLASSMETHOD(OSType, "%Extends", "%Collection.ArrayOfDT")) {
					/// Mapping to an array of primitives, we can simply copy the JSON value over
					Set putVal = value1
				} ElseIf ($CLASSMETHOD(OSType, "%Extends", "%Collection.ArrayOfObj")) {
					/// We are mapping to an array of Complex objects in ObjectScript. This is stored as a JSON object in the JSON
					/// with each key being a string, and each value being another JSON object
					/// We need to determine the data type using the DataType variable from the %Dictionary.PropertyDefinition
					/// We loop through all key/value pairs in the JSON, instantiate the ObjectScript objects, populate using
					/// this same method and then use SetAt to set the keys in the array
					Set putVal = $CLASSMETHOD(DataType, "%New")
					Do ..PopulateObjectFromJSON(.putVal, value1)
				}

				Do arr.SetAt(putVal, key1)
				
			}
		} ElseIf ($CLASSMETHOD(DataType, "%Extends", "%RegisteredObject")) {
			Set subObj = $PROPERTY(pObj, key)
			If ('$ISOBJECT(subObj))	 {
				#; Write "Populating object of type " _ $CLASSNAME(pObj) _ ", property=" _ key _ " of type " _ DataType _ " with value " _ value.%ToJSON(),!,!,!
				/// If the object has not been instantiated for whatever reason, we create a new object of that type
				/// and continue the population of the object
				Set $PROPERTY(pObj, key) = $CLASSMETHOD(DataType, "%New")
				Set subObj = $CLASSMETHOD(DataType, "%New")
			}
			Do ..PopulateObjectFromJSON(.subObj, value)
		} Else {
			/// Mismatch or unhandled types between JSON and ObjectScript Object
			Throw ##class(%Exception.General).%New("Failed to populate message","-313",,"Mismatch of data types - cannot populate message, Parent class: " _ $CLASSNAME(pObj) _ ", Key: " _ key _ ", JSON type: " _ jsonType _ " ObjectScript type: " _ OSType _ ", ObjectScript collection: " _ CollectionType _ ", ObjectScript data type: " _ DataType _ ". JSON: " _ value.%ToJSON())
		}
	}
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
<Value>Fill</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
