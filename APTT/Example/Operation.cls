/// 
Class APTT.Example.Operation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

Property Adapter As EnsLib.File.OutboundAdapter;

Parameter INVOCATION = "Queue";

/// <b>NOTE:</b> This is an example operation method.
/// You should replace it and its entry in the MessageMap with your custom operation methods.
/// See <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=EGDV_busop#EGDV_busop_message_handlers">the documentation</a>
/// for tips on how to implement operation methods.
Method TestCall(pRequest As APTT.Example.Request, Output pResponse As APTT.Example.Response) As %Status
{
  Do ..TestCallCM(pRequest, .pResponse)

  Quit $$$OK
}

ClassMethod TestCallCM(pRequest As APTT.Example.Request, Output pResponse As APTT.Example.Response) As %Status
{
  Set pResponse = ##class(APTT.Example.Response).%New()
  Set pResponse.Name = pRequest.Name
  Set pResponse.Gender = pRequest.Gender
  Set pResponse.Age = pRequest.Age
  Set pResponse.FavouriteColours = pRequest.FavouriteColours
  Set pResponse.ContactNumbers = pRequest.ContactNumbers
  Set pResponse.MainAddress = pRequest.MainAddress
  Set pResponse.OtherAddresses = pRequest.OtherAddresses
  Set pResponse.NamedAddresses = pRequest.NamedAddresses

  Quit $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="APTT.Example.Request">
    <Method>TestCall</Method>
  </MapItem>
</MapItems>
}

}
