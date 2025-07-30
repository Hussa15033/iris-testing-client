Class HS.Local.HSUK.Testing.Parser.Interactions.Message Extends (%SerialObject, %JSON.Adaptor)
{

Parameter %JSONIGNOREINVALIDFIELD As BOOLEAN = 1;

Property ClassName As %String(%JSONFIELDNAME = "class");

// Property Properties As %DynamicObject(%JSONFIELDNAME = "properties");

Storage Default
{
<Data name="MessageState">
<Value name="1">
<Value>ClassName</Value>
</Value>
<Value name="2">
<Value>Properties</Value>
</Value>
</Data>
<State>MessageState</State>
<StreamLocation>^HS.Local.HSUK.TestB95F.MessageS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
