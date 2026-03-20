Class TestingClient.Example.Model.Address Extends (%SerialObject, %XML.Adaptor)
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
<Value>Streets</Value>
</Value>
</Data>
<State>AddressState</State>
<StreamLocation>^TestingClient.Example.Model.AddressS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
