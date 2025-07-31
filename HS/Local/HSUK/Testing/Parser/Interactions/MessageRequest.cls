Class HS.Local.HSUK.Testing.Parser.Interactions.MessageRequest Extends HS.Local.HSUK.Testing.Parser.Interactions.Message
{

/// 
/// This method generates the Ens.Request using the <property>ClassName</property> specified
/// and attempts to populate the <property>Properties</property> within the message
/// class
/// 
/// This method will throw an error if it fails to populate any properties of the message class
/// 
/// Nested object properties will be instantiated and populated also
/// 
Method GenerateMessageRequest()
{
	Write "Creating message class " _ ..ClassName

	#dim messageObj As Ens.Request
	Set messageObj = $CLASSMETHOD(..ClassName, "%New")
	
	Set mIter = ..Properties.%GetIterator()
	While mIter.%GetNext(.key, .value, .type) {
		// TODO: Handle cases for serial objects within request messages
		Try {
			Set $PROPERTY(messageObj, key) = value
		} Catch ex {
			Throw ##class(%Exception.General).%New("Failed to set property of request class","-883",,"Property "_key_" of request message type " _ ..ClassName _ " does not exist")
		}
	}

	Return messageObj
}

Storage Default
{
<Type>%Storage.Serial</Type>
}

}
