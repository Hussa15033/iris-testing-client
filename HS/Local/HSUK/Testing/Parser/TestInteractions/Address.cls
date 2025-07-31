Class HS.Local.HSUK.Testing.Parser.TestInteractions.Address Extends (%SerialObject, %XML.Adaptor)
{

Property HouseNumber As %Integer;

Property Streets As list Of %String;

Storage Default
{
<Data name="AddressState">
<Value name="1">
<Value>HouseNumber</Value>
</Value>
<Value name="2">
<Value>Street</Value>
</Value>
<Value name="3">
<Value>Streets</Value>
</Value>
</Data>
<State>AddressState</State>
<StreamLocation>^HS.Local.HSUK.Test4FC5.AddressS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
