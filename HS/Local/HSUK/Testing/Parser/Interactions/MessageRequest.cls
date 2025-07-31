Class HS.Local.HSUK.Testing.Parser.Interactions.MessageRequest Extends HS.Local.HSUK.Testing.Parser.Interactions.Message
{

Parameter MESSAGECLASS = "Ens.Request";

ClassMethod %JSONNew(pJSON As %DynamicObject, pParent As %RegisteredObject) As %RegisteredObject
{
	Set requestJSON = pJSON.request
	If (requestJSON = "") {
		Throw ##class(%Exception.General).%New("Invalid JSON","-11",,"The request property does not exist for interaction")
	}

	Return ##super(requestJSON, pParent)
}

/// 
/// This method generates the Ens.Request using the <property>ClassName</property> specified
/// and attempts to populate the <property>Properties</property> within the message
/// class
/// 
/// This method will throw an error if it fails to populate any properties of the message class
/// 
/// Nested object properties will be instantiated and populated also
/// 
Method GenerateMessageRequest()
{
	Write "Creating message class " _ ..ClassName

	#dim messageObj As Ens.Request
	Set messageObj = $CLASSMETHOD(..ClassName, "%New")
	Do ..PopulateObjectFromJSON(.messageObj, ..Properties)

	Return messageObj
}

Method AssertEquals(pStr1, pStr2, pFailMessage) As %Status
{
	If (pStr1 '= pStr2) {
		Throw ##class(%Exception.General).%New("Equal Assertion Failed","-39",,pStr1 _ " != " _ pStr2 _ ": " _ pFailMessage)
	}

	Quit $$$OK
}

/// A helper method to populate the properties of an object, given the object, and the corresponding
/// JSON object, will throw an error if any properties cannot be set
Method PopulateObjectFromJSON(Output pObj As %RegisteredObject, pJSON As %DynamicObject)
{
	If ('pJSON.%Extends("%DynamicObject")) {
		Throw ##class(%Exception.General).%New("Cannot populate object","-303",,"Cannot populate ObjectScript object of type " _ $CLASSNAME(pObj) _ " as JSON is not a valid %DynamicObject")
	}

	/// This method loops through all of the properties in the JSON and sets their value in the
	/// objectscript object. This is a recursive method and will populate
	/// serial objects within that object from the JSON
	Set mIter = pJSON.%GetIterator()

	While mIter.%GetNext(.key, .value, .jsonType) {
		Do ..GetPropertyDefinition($CLASSNAME(pObj), key, .CollectionType, .DataType)

		Set OSType = $CLASSNAME($PROPERTY(pObj, key))
		#; w !,"Key " _ key,!
		#; w "ObjectScript type: "_$CLASSNAME($PROPERTY(pObj, key)),!
		#; w "ObjectScript type 2: " _ CollectionType _ "||" _ DataType,!
		#; w "JSON Type: " _ jsonType,!

		If (OSType = "" && ((jsonType = "string") || (jsonType = "number") || (jsonType = "boolean"))) {
			/// Both are primitive data types, simply set the property values
			Set $PROPERTY(pObj, key) = value
		} ElseIf (CollectionType = "list" && $CLASSMETHOD(OSType, "%Extends", "%Collection.ListOfDT")) {
			Do ..AssertEquals(jsonType, "array")

			/// We are mapping an array in JSON to a list of primitive data types in ObjectScript
			/// We loop over the values in the JSON array and insert them into the list in ObjectScript
			#dim list As %Collection.ListOfDT
			#dim value As %DynamicArray
			Set list = $PROPERTY(pObj, key)
			Set lIter = value.%GetIterator()
			While lIter.%GetNext(.key1, .value1, .type1) {
				Do list.Insert(value1)
			}
		} ElseIf (CollectionType = "list" && $CLASSMETHOD(OSType, "%Extends", "%Collection.ListOfObj")) {
			Do ..AssertEquals(jsonType, "array")

			/// We mapping an array of JSON objects in a JSON array to a list of Complex object types in ObjectScript
			/// First determine the type of the object in ObjectScript, this is stored in the PropertyDefinition
			/// and extracted to the 'DataType' variable
			/// We then loop over the array and instantiate the object, then call this method again to populate its fields recursively
			Set list = $PROPERTY(pObj, key)
			Set lIter = value.%GetIterator()
			While lIter.%GetNext(.key1, .value1, .type1) {
				Set subObj = $CLASSMETHOD(DataType, "%New")
				Do ..PopulateObjectFromJSON(.subObj, value1)
				Do list.Insert(subObj)
			}
		} ElseIf (CollectionType = "array" && $CLASSMETHOD(OSType, "%Extends", "%Collection.ArrayOfDT")) {
			Do ..AssertEquals(jsonType, "object")
			
			/// We are mapping to an array of primitives on ObjectScript, this should be stored in a JSON object
			/// with the key->value mapping remaining the same.
			/// We loop through all key/value pairs in the JSON and use SetAt to set the assoc array in ObjectScript
			#dim arr As %Collection.ArrayOfDT
			Set arr = $PROPERTY(pObj, key)
			Set lIter = value.%GetIterator()
			While lIter.%GetNext(.key1, .value1, .type1) {
				Do arr.SetAt(value1, key1)
			}
		} ElseIf (CollectionType = "array" && $CLASSMETHOD(OSType, "%Extends", "%Collection.ArrayOfObj")) {
			Do ..AssertEquals(jsonType, "object")

			/// We are mapping to an array of Complex objects in ObjectScript. This is stored as a JSON object in the JSON
			/// with each key being a string, and each value being another JSON object
			/// We need to determine the data type using the DataType variable from the %Dictionary.PropertyDefinition
			/// We loop through all key/value pairs in the JSON, instantiate the ObjectScript objects, populate using
			/// this same method and then use SetAt to set the keys in the array
			#dim arr1 As %Collection.ArrayOfObj
			Set arr1 = $PROPERTY(pObj, key)
			Set lIter = value.%GetIterator()
			While lIter.%GetNext(.key1, .value1, .type1) {
				Set subObj = $CLASSMETHOD(DataType, "%New")
				Do ..PopulateObjectFromJSON(.subObj, value1)
				Do arr1.SetAt(subObj, key1)
			}
		} ElseIf ($ISOBJECT($PROPERTY(pObj, key))) {
			Set subObj = $PROPERTY(pObj, key)
			Do ..PopulateObjectFromJSON(.subObj, value)
		} Else {
			/// Mismatch or unhandled types between JSON and ObjectScript Object
			Throw ##class(%Exception.General).%New("Failed to populate message","-313",,"Unknown how to handle types, JSON type: " _ jsonType _ " ObjectScript type: " _ OSType _ ", ObjectScript collection: " _ CollectionType _ ", ObjectScript data type: " _ DataType _ ". JSON: " _ value.%ToJSON())
		}
	}
}

Storage Default
{
<Type>%Storage.Serial</Type>
}

}
