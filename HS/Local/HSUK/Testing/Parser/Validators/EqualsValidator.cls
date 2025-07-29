/// 
/// The default and most basic validator.
/// 
/// It checks to ensure the expected value and the actual value match, no options are expected
Class HS.Local.HSUK.Testing.Parser.Validators.EqualsValidator Extends HS.Local.HSUK.Testing.Parser.Validators.Validator
{

Method OnValidate(pExpectedValue As %String(MAXLEN=""), pActualValue As %String(MAXLEN=""), pOptions As %DynamicObject) As %Status
{
	If (pActualValue = pExpectedValue) {
		Return $$$OK
	}

	Return 0
}

}
