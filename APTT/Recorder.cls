/// 
/// This class can be used to record test messages and automatically create a 
/// JSON test definition file that can be modified to replay the tests that have been recorded.
/// 
/// To use this class:
/// 1. Run:
/// 	`Do ##class(APTT.Recorder).Record(<production-class>, <target-component-name>)`
/// 2. Enter the file path to save the test definition file
/// 3. Choose whether to record [R] a new test or exit [E]. Exiting will save all tests to the definition file
/// 4. After recording a test, the test summary will be displayed in the console. Choose whether to Accept [A] or Reject [R] the test
/// 5. All accepted tests will be saved to the test definition file
/// 
/// @author Auwais Hussain
/// @version 26.10.2025
/// 
Class APTT.Recorder Extends %RegisteredObject
{

// Todo: Move to UTIL class, DUPLICATE CODE.

ClassMethod GetPropertyDefinition(pClassname, pProperty, Output Collection As %String, Output Type As %String)
{
	Set def = ##class(%Dictionary.CompiledProperty).%OpenId(pClassname _ "||" _ pProperty)
	If (def = "") {
		Throw ##class(%Exception.General).%New("Unable to find property","-77",,"Could not load property definition for property '" _ pProperty _ "' in class '" _ pClassname _ "', property does not exist")
	}

	Set Collection = def.Collection
	Set Type = def.Type
}

ClassMethod GetLastMessageHeaderID(pFrom As %String, pTo As %String) As %Integer [ Private ]
{
	&sql(SELECT TOP 1 id INTO :lastid
			 FROM Ens.MessageHeader
			 WHERE SourceConfigName=:pFrom AND TargetConfigName=:pTo
			 ORDER BY id DESC)

	Return lastid
}

/// Compute a property type given its class name
/// Returns either "primitive", "list", "array", "object" or "json"
ClassMethod ClassType(pObj As %RegisteredObject)
{
	Set pClassName = $CLASSNAME(pObj)
		
	If ((pClassName = pObj) || $CLASSMETHOD(pClassName, "%Extends", "%DataType")) {
		Return "primitive"
	} ElseIf ($CLASSMETHOD(pClassName, "%Extends", "%Collection.AbstractList")) {
		Return "list"
	} ElseIf ($CLASSMETHOD(pClassName, "%Extends", "%Collection.AbstractArray")) {
		Return "array"
	} ElseIf ($CLASSMETHOD(pClassName, "%Extends", "%DynamicObject") || $CLASSMETHOD(pClassName, "%Extends", "%DynamicArray")) {
		Return "json"
	} ElseIf ($CLASSMETHOD(pClassName, "%Extends", "%RegisteredObject")) {
		Return "object"
	} Else {
		Throw ##class(%Exception.General).%New("Unknown object","-3911",,"Unknown how to handle object of class " _ pClassName)
	}
}

ClassMethod TestConverter()
{
	Set a = ##class(APTT.Example.Request).%New()
	Set a.Name = "Testing"
	Set a.Age = 183
	Set a.Gender = "M"
	Do a.ContactNumbers.SetAt(1938293, "Home")
	Do a.FavouriteColours.Insert("Blue")
	Do a.FavouriteColours.Insert("Red")
	Do a.FavouriteColours.Insert("Green")
	Set address1 = ##class(APTT.Example.Model.Address).%New()
	Set address1.HouseNumber = 381
	Do address1.Streets.Insert("FakeStreet 1")
	Set a.MainAddress = address1

	Set address2 = ##class(APTT.Example.Model.Address).%New()
	Set address2.HouseNumber = 34
	Do address2.Streets.Insert("FakeStreet2 For OtherAddress")
	Do a.OtherAddresses.Insert(address1)
	Do a.OtherAddresses.Insert(address2)
	Do a.NamedAddresses.SetAt(address1, "Home")

	Write ..PopulateJSONFromObject(a).%ToJSON()
}

ClassMethod PopulateJSONFromObject(pObject As %RegisteredObject)
{
	If (('$ISOBJECT(pObject)) || (pObject = "")) {
		Return pObject
	}

	/// Loop through all properties of this object
	Set className = $CLASSNAME(pObject)
	Set objType = ..ClassType(pObject)

	If (objType = "json") {
		Return pObject
	} ElseIf (objType = "primitive") {
		Return pObject
	} ElseIf (objType = "object") {

		Set dyn = ##class(%Library.DynamicObject).%New()

		/// This is an IRIS object, populate its properties

		Set sql = ##class(%SQL.Statement).%ExecDirect(,"SELECT * FROM %Dictionary.CompiledProperty WHERE parent=? AND $EXTRACT(name, 1) != '%' AND private='0'", className)

		While sql.%Next() {
			Set property = ##class(%Dictionary.CompiledProperty).%OpenId(sql.%Get("id1"))

			Set propName = property.Name
			Set val = $PROPERTY(pObject, propName)

			Do dyn.%Set(propName, ..PopulateJSONFromObject(val))
		}

		Return dyn
		
	} ElseIf (objType = "list") {
		Set jsonlist = ##class(%DynamicArray).%New()

		For i=1:1:pObject.Count() {
			Do jsonlist.add(..PopulateJSONFromObject(pObject.GetAt(i)))
		}

		Return jsonlist
	} ElseIf (objType = "array") {
		/// Converting an objectscript array (key/value pair) into
		/// a JSON object
		Set jsonobj = ##class(%DynamicObject).%New()

		Set sKey = pObject.Next("")
		While sKey '= "" {
			Set val = ..PopulateJSONFromObject(pObject.GetAt(sKey))
			Do jsonobj.put(sKey, val)

			Set sKey = pObject.Next(sKey)
		}

		Return jsonobj
	}
}

ClassMethod Record(pProductionClass As %String, pTarget As %String)
{
		Set pProductionClass = "HS.Local.HSUK.DefaultProduction"
		Set pTarget = "TestPDS"

		Set testDefinition = {}
		Set testDefinition.production = pProductionClass
		Set testDefinition.namespace = $NAMESPACE
		Set testDefinition.tests = []
		Set testSuite = {}
		Set testSuite.name = pTarget
		Set testSuite.class = "Testing"
		Set interactions = []


		Set tdf = "C:\Users\ahussain\Desktop\NHS Interfaces\PDSFHIRAPI\local\src\pds-fhir-api\Tests\ExampleFile.json"

		Write "Recording tests.."

		Set action = ""
		While (action '= "R") && (action '= "E") {
			Read !, "Record a new test [R] or exit [E]: ", action
		}


		If action = "E" {
			Write "Exiting..."
			Return
		}


		Set lastID = ..GetLastMessageHeaderID(pTarget, "EnsLib.Testing.Process")
		Set lastID = 8402
		Write !,"Last message ID found: " _ lastID

		Set accept = ""
		While accept '= "A" {
			Read !, "Accept test? [A]: ", accept
		}

		Set newLastID = ..GetLastMessageHeaderID(pTarget, "EnsLib.Testing.Process")

		If newLastID = lastID {
			Write !,"No new messages detected..."
			Return
		}

		/// A new message was detected, attempt to parse the input and output of this message
		/// into JSON to be stored in the test definition file
		Set msgRequestHeader = ##class(Ens.MessageHeader).%OpenId(..GetLastMessageHeaderID("EnsLib.Testing.Process", pTarget))
		Set msgBodyClass = msgRequestHeader.MessageBodyClassName
		Set msgBodyID = msgRequestHeader.MessageBodyId

		Set obj = $CLASSMETHOD(msgBodyClass, "%OpenId", msgBodyID)

		Set interaction = {}
		Set interaction.name = "Interaction"
		Set interaction.request = {}
		Set interaction.request.class = msgBodyClass
		Set interaction.request.properties = ..PopulateJSONFromObject(obj)
		
		Set msgRequestHeader = ##class(Ens.MessageHeader).%OpenId(..GetLastMessageHeaderID(pTarget, "EnsLib.Testing.Process"))
		Set msgBodyClass = msgRequestHeader.MessageBodyClassName
		Set msgBodyID = msgRequestHeader.MessageBodyId

		Set obj = $CLASSMETHOD(msgBodyClass, "%OpenId", msgBodyID)

		Set interaction.response = {}
		Set interaction.response.class = msgBodyClass
		Set interaction.response.properties = ..PopulateJSONFromObject(obj)

		Do interactions.add(interaction)
		Set testSuite.interactions = interactions
		Do testDefinition.tests.add(testSuite)

		W testDefinition.%ToJSON()
}

}
