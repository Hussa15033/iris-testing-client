/// 
Class HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestOperation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

Property Adapter As EnsLib.File.OutboundAdapter;

Parameter INVOCATION = "Queue";

/// <b>NOTE:</b> This is an example operation method.
/// You should replace it and its entry in the MessageMap with your custom operation methods.
/// See <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=EGDV_busop#EGDV_busop_message_handlers">the documentation</a>
/// for tips on how to implement operation methods.
Method SampleCall(pRequest As HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestRequest, Output pResponse As HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestResponse) As %Status
{
  Set pResponse = ##class(HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestRequest).%New()
  Set pResponse.Name = pRequest.Name
  Set pResponse.Gender = pRequest.Gender
  Set pResponse.MainAddress = pRequest.MainAddress
  Set pResponse.OtherAddresses = pRequest.OtherAddresses
  Set pResponse.NamedAddresses = pRequest.NamedAddresses
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestRequest">
    <Method>SampleCall</Method>
  </MapItem>
</MapItems>
}

}
