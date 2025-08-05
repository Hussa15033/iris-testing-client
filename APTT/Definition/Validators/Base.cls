Class APTT.Definition.Validators.Base Extends (%RegisteredObject, %SerialObject) [ Abstract ]
{

/// A comma separated list of valid options this validator takes, override in your subclass
Parameter VALIDOPTIONS;

Property Options As %DynamicObject;

Method %OnNew(pOptions As %DynamicObject) As %Status
{
	Set ..Options = pOptions

	If (pOptions = "") {
		Return $$$OK
	}
	
	/// Check only the valid options appear in the options OBJECT
	Set jsonIter = pOptions.%GetIterator()
	
	Set validOptionsList = $LISTFROMSTRING(..#VALIDOPTIONS, ",")

	While jsonIter.%GetNext(.key, .value, .type) {
		If ($LISTFIND(validOptionsList, key) = 0) {
			Throw ##class(%Exception.General).%New("Invalid option for validator '" _ $CLASSNAME() _ "'","-438",,"'" _ key _ "' is not a valid option for this validator. Valid options: " _ $LISTTOSTRING(validOptionsList, ", "))
		}
	}
	
	Quit $$$OK
}

Method ValidationError(pText As %String)
{
	Throw ##class(%Exception.General).%New(
			"ValidationError for " _ $CLASSNAME(),
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

/// Options methods
Method hasOption(pOption As %String)
{
	Return ..Options.%IsDefined(pOption)
}

Method getOption(pOption As %String) As %String
{
	If ('..hasOption(pOption)) {
		Do ..ValidationError("The option " _ pOption _ " is required for this validator")
	}

	Return ..Options.%Get(pOption)
}

}
