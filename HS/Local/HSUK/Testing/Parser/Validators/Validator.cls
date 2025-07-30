Class HS.Local.HSUK.Testing.Parser.Validators.Validator Extends (%RegisteredObject, %SerialObject) [ Abstract ]
{

Property Options As %DynamicObject;

Method %OnNew(pOptions As %DynamicObject) As %Status
{
	Set ..Options = pOptions
	Quit $$$OK
}

Method ValidationError(pText As %String)
{
	Throw ##class(%Exception.General).%New(
			"ValidationError",
			"-2000",,
			"Validation error occurred for " _ $CLASSNAME() _ ": " _ pText)
}

Method Validate(pExpectedValue As %String(MAXLEN=""), pActualValue As %String(MAXLEN="")) As %Status
{
	If ($$$ISOK(..OnValidate(pExpectedValue, pActualValue))) {
		Return $$$OK
	} Else {
		Do ..ValidationError("Validator Failed on validation, expected value '" _ pExpectedValue _ "' but got '" _ pActualValue _ "'")
		Return 0
	}
}

/// Override this method to validate the value, should return a value of 0 (failure) or 1 (success)
Method OnValidate(pExpectedValue As %String(MAXLEN=""), pActualValue As %String(MAXLEN="")) As %Status [ Abstract ]
{
}

Storage Default
{
<Data name="ValidatorState">
<Value name="1">
<Value>Options</Value>
</Value>
</Data>
<State>ValidatorState</State>
<StreamLocation>^HS.Local.HSUK.Te9387.ValidatorS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
