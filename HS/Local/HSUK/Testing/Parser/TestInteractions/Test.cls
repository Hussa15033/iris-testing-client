Class HS.Local.HSUK.Testing.Parser.TestInteractions.Test Extends %RegisteredObject
{

ClassMethod GenerateRequestMessage() As HS.Local.HSUK.Testing.Parser.Tests.Interaction
{
		Set a = ##class(HS.Local.HSUK.Testing.Parser.Tests.Interaction).%New()
		Do a.%JSONImport(
			{
                    "request": {
                        "class": "HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestRequest",
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
                        "class": "HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestResponse",
                        "validators": {
                            "Name": {
                                "validator": "ContainsValidator",
                                "options": {
                                    "containsText": "rUs"
                                }
                            },
                            "OtherAddresses[0].Streets[0]": {
                                "validator": "ContainsValidator",
                                "options": {
                                    "containsText": "eet3"
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
	#dim interaction As HS.Local.HSUK.Testing.Parser.Tests.Interaction
	Set interaction = ..GenerateRequestMessage()
	Set message = interaction.MessageRequest.GenerateMessageRequest()
	
    Set bo = ##class(HS.Local.HSUK.Testing.Parser.TestInteractions.MyTestOperation).SampleCallCM(message, .response)
    Set sc = interaction.MessageResponse.ValidateResponse(response)
    $$$ThrowOnError(sc)

    Write "Validation success!",!
    Return message
}

}
