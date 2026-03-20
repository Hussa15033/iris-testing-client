/// 
/// A validator for TextFields. This validator takes various options to perform different text validations. Each option adds to the validation checks.
/// 
/// @author Auwais Hussain (ahussain@intersystems.com)
/// @version 18.08.2025
/// 
Class APTT.Definition.Validators.TextValidator Extends APTT.Definition.Validators.Base
{

Parameter VALIDOPTIONS = "equals,contains,beginsWith,endsWith,caseSensitive,notEquals,base64";

/// Valid options for this TextValidator:
/// "options": {
/// 	"contains": ??,
/// 	"equals": ??,
/// 	"beginsWith": ??,
/// 	"endsWith": ??,
/// 	"caseSensitive": "true", "false",
/// 	"base64": ?? # A base64 value this field should encode to
/// }
/// 
/// Can specify any combination of the above and they will all be checked
/// /// Override this method to validate the value, should return a value of 0 (failure) or 1 (success)
Method OnValidate(pExpectedValue As %String(MAXLEN=""), pActualValue As %String(MAXLEN="")) As %Status
{
	Set caseSensitive = 1
	If ..hasOption("caseSensitive") {
		Set caseSensitive = ..getOption("caseSensitive")
	}

	If (..hasOption("equals")) {
		Do ..ValidateText("equals", pActualValue, ..getOption("equals"), caseSensitive)
	}
	If (..hasOption("contains")) {
		Do ..ValidateText("contains", pActualValue, ..getOption("contains"), caseSensitive)
	}

	If (..hasOption("beginsWith")) {
		Do ..ValidateText("beginsWith", pActualValue, ..getOption("beginsWith"), caseSensitive)
	}

	If (..hasOption("endsWith")) {
		Do ..ValidateText("endsWith", pActualValue, ..getOption("endsWith"), caseSensitive)
	}
	
	If (..hasOption("notEquals")) {
		Do ..ValidateText("notEquals", pActualValue, ..getOption("notEquals"), caseSensitive)
	}

	If (..hasOption("base64")) {
		Do ..ValidateText("base64", pActualValue, ..getOption("base64"), 1)
	}

	Return $$$OK
}

Method ValidateText(pMode As %String, pText As %String, pAuxText As %String, pSensitive As %Boolean) As %Boolean
{
	If 'pSensitive {
		Set pText = $ZCONVERT(pText, "l")
		Set pAuxText = $ZCONVERT(pAuxText, "l")
	}

	Set valid = 0
	If pMode = "equals" {
		Set valid = (pText = pAuxText)
	} ElseIf pMode = "contains" {
		Set valid = (pText [ pAuxText)
	} ElseIf (pMode = "beginsWith") && ($L(pAuxText) <= $L(pText)) {
		Set valid = ($EXTRACT(pText, 0, $L(pAuxText)) = pAuxText)
	} ElseIf (pMode = "endsWith") && ($L(pAuxText) <= $L(pText)) {
		Set valid = ($EXTRACT(pText, *-($L(pAuxText) - 1), *) = pAuxText)
	} ElseIf (pMode = "notEquals") {
		Set valid = (pText '= pAuxText)
	} ElseIf (pMode = "base64") {
		Set valid = ($System.Encryption.Base64Encode(pText) = pAuxText)
	}

	If valid = 0 {
		Do ..ValidationError("Failed validation with mode '" _ pMode _ "', text = '" _ pText _ "', auxText = '" _ pAuxText _ "' with case sensitive mode = " _ pSensitive)
	}

	Return 1
}

}
