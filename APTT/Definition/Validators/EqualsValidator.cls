/// 
/// The default and most basic validator.
/// 
/// It checks to ensure the expected value and the actual value match, no options are expected
/// 
/// @author Auwais Hussain (ahussain@intersystems.com)
/// @version 01.08.2025
/// 
Class APTT.Definition.Validators.EqualsValidator Extends APTT.Definition.Validators.Base
{

Method OnValidate(pExpectedValue As %String(MAXLEN=""), pActualValue As %String(MAXLEN="")) As %Status
{
	If (pActualValue = pExpectedValue) {
		Return $$$OK
	}

	Do ..ValidationError("Validation error with EqualsValidator - expected '" _ pExpectedValue _ "' but got '" _ pActualValue _ "'")
}

}
