Class TestingClient.Example.ValidationTest Extends %RegisteredObject
{

ClassMethod GenerateRequestMessage() As TestingClient.Definition.Interaction
{
		Set a = ##class(TestingClient.Definition.Interaction).%New()
		Do a.%JSONImport(
			{
                    "request": {
                        "class": "TestingClient.Example.Request",
                        "properties": {
                            "Name": "OtherUser",
                            "Gender": "M",
                            "Age": 25,
                            "ContactNumbers": {
                                "Home": "0371783 831 8931",
                                "Work": "073892783913"
                            },
                            "FavouriteColours": [
                                "Blue",
                                "Green",
                                "Red"
                            ],
                            "MainAddress": {
                                "HouseNumber": 55,
                                "Streets": [
                                    "Street1",
                                    "Street2"
                                ]
                            },
                            "OtherAddresses": [
                                {
                                    "HouseNumber": 66,
                                    "Streets": [
                                        "Street3"
                                    ]
                                }
                            ],
                            "NamedAddresses": {
                                "Main": {
                                    "HouseNumber": 33,
                                    "Streets": [
                                        "Street 4"
                                    ]
                                }
                            }
                        }
                    },
                    "response": {
                        "class": "TestingClient.Example.Response",
                        "validators": {
                            "Name": {
                                "validator": "TextValidator",
                                "options": {
                                    "contains": "rUs"
                                }
                            },
                            "OtherAddresses[0].Streets[0]": {
                                "validator": "TextValidator",
                                "options": {
                                    "contains": "eet3"
                                }
                            }
                        },
                        "properties": {
                            "Name": "OtherUser",
                            "FavouriteColours": [
                                "Blue",
                                "Green",
                                "Red"
                            ],
                            "MainAddress": {
                                "HouseNumber": 55,
                                "Streets": [
                                    "Street1",
                                    "Street2"
                                ]
							},
                            "OtherAddresses": [
								{
									"HouseNumber": 66,
									"Streets": [
										"Street3"
									]
								}
							],
							"NamedAddresses": {
								"Main": {
									"HouseNumber": 33,
									"Streets": [
										"Street 4"
									]
								}
							}
                        }
                    }
                }
		)

		Return a
}

ClassMethod Test()
{
	#dim interaction As TestingClient.Definition.Interaction
	Set interaction = ..GenerateRequestMessage()
	Set message = interaction.MessageRequest.GenerateMessageRequest()
	
    Set bo = ##class(TestingClient.Example.Operation).TestCallCM(message, .response)
    Set sc = interaction.MessageResponse.ValidateResponse(response)
    $$$ThrowOnError(sc)
    zw sc

    Write "Validation success!",!
    Return message
}

}
