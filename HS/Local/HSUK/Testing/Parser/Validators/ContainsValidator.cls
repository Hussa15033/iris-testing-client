Class HS.Local.HSUK.Testing.Parser.Validators.ContainsValidator Extends HS.Local.HSUK.Testing.Parser.Validators.Validator
{

/// TODO: Change this to a "TextValidator" with more options
Method OnValidate(pExpectedValue As %String(MAXLEN=""), pActualValue As %String(MAXLEN="")) As %Status
{
	Set containsText = ..Options.%Get("containsText")
	If (containsText = "" || '$D(containsText)) {
		Do ..ValidationError("ContainsValidator not configured correctly, please include the 'containsText' option!")
		Return 0
	}

	If (pActualValue '[ containsText) {
		Do ..ValidationError("Value '" _ pActualValue _ "' does not contain text '" _ containsText)
		Return 0	
	}
	
	Return $$$OK
}

}
