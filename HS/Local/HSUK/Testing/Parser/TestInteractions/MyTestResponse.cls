Class HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestResponse Extends Ens.Response
{

Property Name As %String;

Property Gender As %String;

Property Age As %Integer;

Property ContactNumbers As array Of %Integer;

Property FavouriteColours As list Of %String;

Property MainAddress As HS.Local.HSUK.Testing.Parser.TestInteractions.Address;

Property OtherAddresses As list Of HS.Local.HSUK.Testing.Parser.TestInteractions.Address;

Property NamedAddresses As array Of HS.Local.HSUK.Testing.Parser.TestInteractions.Address;

Storage Default
{
<Data name="ContactNumbers">
<Attribute>ContactNumbers</Attribute>
<Structure>subnode</Structure>
<Subscript>"HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestResponse.ContactNumbers"</Subscript>
</Data>
<Data name="MyTestResponseDefaultData">
<Subscript>"MyTestResponse"</Subscript>
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Gender</Value>
</Value>
<Value name="3">
<Value>Age</Value>
</Value>
<Value name="4">
<Value>FavouriteColours</Value>
</Value>
<Value name="5">
<Value>MainAddress</Value>
</Value>
<Value name="6">
<Value>OtherAddresses</Value>
</Value>
</Data>
<Data name="NamedAddresses">
<Attribute>NamedAddresses</Attribute>
<Structure>subnode</Structure>
<Subscript>"HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestResponse.NamedAddresses"</Subscript>
</Data>
<DefaultData>MyTestResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
