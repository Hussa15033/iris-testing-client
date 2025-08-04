Class APTT.Utils
{

ClassMethod Log(pText As %String, pCode As %String = "", pInclLineTerminator = 1)
{
		Write $ZDT($H) _ ""
		Write:pCode'="" " [" _ pCode _ "]"
		Write ": " _ pText
		Write:pInclLineTerminator !
}

}
