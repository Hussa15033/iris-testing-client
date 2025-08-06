Class APTT.Example.Request Extends (Ens.Request, %XML.Adaptor)
{

Property Name As %String;

Property Gender As %String;

Property Age As %Integer;

Property ContactNumbers As array Of %Integer;

Property FavouriteColours As list Of %String;

Property MainAddress As APTT.Example.Model.Address;

Property OtherAddresses As list Of APTT.Example.Model.Address;

Property NamedAddresses As array Of APTT.Example.Model.Address;

Storage Default
{
<Data name="ContactNumbers">
<Attribute>ContactNumbers</Attribute>
<Structure>subnode</Structure>
<Subscript>"APTT.Example.Request.ContactNumbers"</Subscript>
</Data>
<Data name="NamedAddresses">
<Attribute>NamedAddresses</Attribute>
<Structure>subnode</Structure>
<Subscript>"APTT.Example.Request.NamedAddresses"</Subscript>
</Data>
<Data name="RequestDefaultData">
<Subscript>"Request"</Subscript>
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
<DefaultData>RequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
