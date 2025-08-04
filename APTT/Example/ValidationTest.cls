Class APTT.Example.ValidationTest Extends %RegisteredObject
{

ClassMethod GenerateRequestMessage() As APTT.Definition.Interaction
{
		Set a = ##class(APTT.Definition.Interaction).%New()
		Do a.%JSONImport(
			{
                    "request": {
                        "class": "APTT.Definition.Request",
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
                        "class": "APTT.Example.Response",
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
	#dim interaction As APTT.Definition.Interaction
	Set interaction = ..GenerateRequestMessage()
	Set message = interaction.MessageRequest.GenerateMessageRequest()
	
    Set bo = ##class(APTT.Example.Operation).SampleCallCM(message, .response)
    Set sc = interaction.MessageResponse.ValidateResponse(response)
    $$$ThrowOnError(sc)

    Write "Validation success!",!
    Return message
}

}
