Class HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestResponse Extends Ens.Response
{

Property Name As %String;

Property Gender As %String;

Property FavouriteColours As list Of %String;

Property MainAddress As HS.Local.HSUK.Testing.Parser.TestInteractions.Address;

Property OtherAddresses As list Of HS.Local.HSUK.Testing.Parser.TestInteractions.Address;

Property NamedAddresses As array Of HS.Local.HSUK.Testing.Parser.TestInteractions.Address;

Storage Default
{
<Data name="MyTestRequestDefaultData">
<Subscript>"MyTestRequest"</Subscript>
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Gender</Value>
</Value>
<Value name="3">
<Value>MainAddress</Value>
</Value>
<Value name="4">
<Value>OtherAddresses</Value>
</Value>
<Value name="5">
<Value>NamedAddresses</Value>
</Value>
<Value name="6">
<Value>FavouriteColours</Value>
</Value>
</Data>
<DefaultData>MyTestRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
