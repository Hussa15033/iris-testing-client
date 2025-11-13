/// 
/// Message class responsible for parsing Asynchronous messages.
/// 
/// These messages include a timeout and are expected to be in response to an interaction
/// 
/// @author Auwais Hussain (ahussain@intersystems.com)
/// @version 05.11.2025
/// 
Class APTT.Definition.Messages.AsyncMessage Extends APTT.Definition.Messages.MessageResponse
{

Parameter MESSAGECLASS = "Ens.MessageBody";

Property Source As %String;

Property Target As %String;

Property Timeout As %Integer;

Property Before As %String(MAXLEN = 10000);

Property After As %String(MAXLEN = 10000);

ClassMethod %JSONNew(pJSON As %DynamicObject, pParent As %RegisteredObject) As %RegisteredObject
{
	#dim asyncMessages As %Library.DynamicArray

	Set asyncMessages = pJSON.asyncmessages

	If (pJSON.%IsDefined("asyncmessages") && ('$ISOBJECT(asyncMessages) || 'asyncMessages.%Extends("%DynamicArray"))) {
		Throw ##class(%Exception.General).%New("Invalid JSON","-11",,"The 'asyncmessages' property has not been set correctly. Please ensure the value is an array of AsyncMessages")
	}

	If (pParent.AsyncMessages.Size > 0) {
		/// We have already inserted all elements from the JSON into this object, return a dud object
		Return ##class(APTT.Definition.Messages.AsyncMessage).%New()
	}

	Set iter = asyncMessages.%GetIterator()

	/// Loop through all async messages and create instances of this class.
	/// This is done because the %JSONNew() is called for EVERY item in the last, however the problem is
	/// it is not called with a key value, so we can't track which item this method is supposed to generate
	/// For this reason, we generate all items on the first pass, and then on remaining passes we insert
	/// dud objects
	While (iter.%GetNext(.key, .asyncMessage, .type)) {
		Set jTimeout = asyncMessage.timeout
		Set jSource = asyncMessage.source
		Set jTarget = asyncMessage.target
		Set jBefore = asyncMessage.before
		Set jAfter = asyncMessage.after

		If (jSource = "" || jTarget = "" || jTimeout = "") {
			Throw ##class(%Exception.General).%New("Invalid async message defined",,"-30943","Invalid async message defined. Ensure all async messages have a source, target and timeout field defined")
		}

		Set tempObj = {}
		Set tempObj.response = asyncMessage

		/// Create an instance of Async Messages
		#dim instance As APTT.Definition.Messages.AsyncMessage
		Set instance = ##super(tempObj, pParent)
		Set instance.Timeout = jTimeout
		Set instance.Source = jSource
		Set instance.Target = jTarget
		Set instance.Before = jBefore
		Set instance.After = jAfter

		Do pParent.AsyncMessages.Insert(instance)
	}

	/// Redundant return
	Return ##class(APTT.Definition.Messages.AsyncMessage).%New()
}

Method ValidateResponse(pMsgHeader As Ens.MessageHeader) As %Status
{
	If (pMsgHeader.SourceConfigName '= ..Source) {
		Throw ##class(%Exception.General).%New("Source does not match",,"-30942","Expected async message source to be '" _ ..Source _ "', instead found '" _ pMsgHeader.SourceConfigName _ "'")
	}

	If (pMsgHeader.TargetConfigName '= ..Target) {
		Throw ##class(%Exception.General).%New("Target does not match",,"-30942","Expected async message target to be '" _ ..Target _ "', instead found '" _ pMsgHeader.TargetConfigName _ "'")
	}

	Return ##super(pMsgHeader)
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
<Value>Source</Value>
</Value>
<Value name="7">
<Value>Target</Value>
</Value>
<Value name="8">
<Value>Timeout</Value>
</Value>
<Value name="9">
<Value>Before</Value>
</Value>
<Value name="10">
<Value>After</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
