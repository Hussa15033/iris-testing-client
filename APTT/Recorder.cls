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
/// @author Auwais Hussain (ahussain@intersystems.com)
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

/// 
/// pAcceptedAnswers is a comma-delimited list of potential answers
ClassMethod MakeBooleanPrompt(pPrompt As %String, pAcceptedAnswers As %String)
{
	Set acceptedAns = $LISTFROMSTRING(pAcceptedAnswers, ",")
	Set action = ""
	
	While (action = "" || '$LISTFIND(acceptedAns, action)) {
		Write !,pPrompt
		Read action
	}

	Return action
}

ClassMethod Record(pProductionClass As %String = "", pTargetName As %String = "")
{
		If (pProductionClass = "") {
			Read !,"Enter the production class: ",pProductionClass
		}

		Set production = ##class(Ens.Config.Production).%OpenId(pProductionClass,,.tSC)

		If ('$$$ISOK(tSC)) {
			Throw ##class(%Exception.General).%New("No production found", "-9910",,"No production named '"_pProductionClass_"' was found")
		}

		If (pTargetName = "") {
			Read !,"Enter the target item name: ",pTargetName
		}

		Set pTarget = ""
		For i=1:1:production.Items.Count() {
			Set item = production.Items.GetAt(i)

			#dim item As Ens.Config.Item
			If (item.Name = pTargetName) {
				Set pTarget = item
			}
		}

		If (pTarget = "") {
			Throw ##class(%Exception.General).%New("No item found","-3920",,"The production component named '" _ pTargetName _ "' was not found.")
			Return
		}

		#dim pTarget As Ens.Config.Item

		Set testDefinition = {}
		Set testDefinition.production = pProductionClass
		Set testDefinition.namespace = $NAMESPACE
		Set testDefinition.tests = []
		Set testSuite = {}
		Set testSuite.name = pTarget.Name
		Set testSuite.class = pTarget.ClassName
		Set interactions = []

		Write !,!,"**Selected production '" _ pProductionClass _ "'"
		Write !,"**Selected target item '" _ pTarget.Name _ "'"
		Write !,"**Selected target item class '" _ pTarget.ClassName _ "'",!

		While (1) {
			Set action = ..MakeBooleanPrompt("Record a new test [R] or exit [E]: ", "R,E")

			If (action = "E") {
				Write !,"Exiting..."
				Write !
				Set testSuite.interactions = interactions
				Do testDefinition.tests.add(testSuite)

				Write !,"Please paste this JSON into your test definition file:",!
				Write testDefinition.%ToJSON()
				Return
			}

			Set interaction = ..RecordOneTest(pTarget.Name)

			If (interaction '= "") {
				Do interactions.add(interaction)
			}
		}
}

ClassMethod RecordOneTest(pTarget As %String)
{
		Set lastID = ..GetLastMessageHeaderID(pTarget, "EnsLib.Testing.Process")

		Write !,"Last message ID found: " _ lastID

		Write !,"**Please test the component using the management portal.."

		Set latestID = lastID
		While (latestID = lastID) {
			Set latestID = ..GetLastMessageHeaderID(pTarget, "EnsLib.Testing.Process")
			Hang 2
		}

		/// A new message was detected, attempt to parse the input and output of this message
		/// into JSON to be stored in the test definition file
		Set reqMsgRequestHeader = ##class(Ens.MessageHeader).%OpenId(..GetLastMessageHeaderID("EnsLib.Testing.Process", pTarget))
		Set reqMsgBodyClass = reqMsgRequestHeader.MessageBodyClassName
		Set reqMsgBodyID = reqMsgRequestHeader.MessageBodyId
		Set reqObj = $CLASSMETHOD(reqMsgBodyClass, "%OpenId", reqMsgBodyID)
		Set reqJSON = ..PopulateJSONFromObject(reqObj)

		Set respMsgRequestHeader = ##class(Ens.MessageHeader).%OpenId(..GetLastMessageHeaderID(pTarget, "EnsLib.Testing.Process"))
		Set respMsgBodyClass = respMsgRequestHeader.MessageBodyClassName
		Set respMsgBodyID = respMsgRequestHeader.MessageBodyId
		Set respObj = $CLASSMETHOD(respMsgBodyClass, "%OpenId", respMsgBodyID)
		Set respJSON = ..PopulateJSONFromObject(respObj)

		/// Print the test results out to the user
		Write !,!,"Request Message",!
		Set formatter = ##class(%JSON.Formatter).%New()

		Do formatter.FormatToString(reqJSON, .reqFormatted)
		Write reqFormatted

		Write !,!,"Response Message",!

		Do formatter.FormatToString(respJSON, .respFormatted)
		Write respFormatted

		Set accept = ..MakeBooleanPrompt("Accept test [A] or Reject [R]: ", "A,R")

		If (accept = "R") {
			Write !,"**Test has been rejected"
			Return ""
		}
		
		Set newLastID = ..GetLastMessageHeaderID(pTarget, "EnsLib.Testing.Process")

		If newLastID = lastID {
			Write !,"No new messages detected..."
			Return ""
		}

		Read !,"Enter a name for this test: ", testName

		Set interaction = {}
		Set interaction.name = testName
		Set interaction.request = {}
		Set interaction.request.class = reqMsgBodyClass
		Set interaction.request.properties = reqJSON

		Set interaction.response = {}
		Set interaction.response.class = respMsgBodyClass
		Set interaction.response.properties = respJSON

		Return interaction
}

}
