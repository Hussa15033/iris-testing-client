/// 
/// The default and most basic validator.
/// 
/// It checks to ensure the expected value and the actual value match, no options are expected
Class HS.Local.HSUK.Testing.Parser.Validators.EqualsValidator Extends HS.Local.HSUK.Testing.Parser.Validators.Validator
{

Method OnValidate(pExpectedValue As %String(MAXLEN=""), pActualValue As %String(MAXLEN="")) As %Status
{
	If (pActualValue = pExpectedValue) {
		Return $$$OK
	}

	Return $System.Status.Error("-109", "Validation error with EqualsValidator - expected '" _ pExpectedValue _ "' but got '" _ pActualValue _ "'")
}

}
