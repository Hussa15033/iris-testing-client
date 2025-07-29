/// 
/// This class contains test for PDS FHIR base production
/// 
/// The PDS FHIR base production contains all components of the Spine production as well as:
/// - PDSService: A SOAP enabled web service to take in SOAP mesages
/// - PDSProcess: A PDS process to forward messages from the PDSService to the NHS PDS FHIR API
/// 
/// Testing the PDSService is sufficient to ensuring the production works as expected, as if the PDSService messages work correctly,
/// then we can safely assume the PDSProcess and GetAccessTokenProcess work too.
/// 
/// 

Class HS.Local.HSUK.Testing.PDS.ProductionTest Extends %UnitTest.TestProduction
{

Parameter PRODUCTION = "HS.Local.HSUK.DefaultProduction";

Parameter IGNOREPRODUCTIONERRORS = 0;

Method OnAfterProductionStart() As %Status
{
	Do ..GetAccessTokenProcessTest()
	
	Quit $$$OK
}

Method ImportKeyFileForApplication(pApplicationName As %String, pPrivateJWKSFile As %String) As HS.Local.HSUK.Spine.Security.Key
{
	// Now that the files have been created, import the key from the file
	Set sc = ##class(HS.Local.HSUK.Spine.Security.Key).LoadKeyFromFile(pApplicationName, "JWKS", "INT", 1, "test-1", pPrivateJWKSFile, 0, 1)
	Do $$$AssertStatusOK(sc)

	// Ensure the key can be retrieved
	Set key = ##class(HS.Local.HSUK.Spine.Security.Key).GetKey(pApplicationName, "JWKS", "INT", 1, "test-1", .status)
	Do $$$AssertNotEquals(key, "")
	Do $$$AssertStatusOK(status)

	Set keyValue = ##class(HS.Local.HSUK.Spine.Security.Key).GetKey(pApplicationName, "JWKS", "INT", 1, "test-1", .st)
	
	Do $$$AssertStatusOK(st)

	Quit $$$OK
}

Method DeleteKeyForApplication(pApplicationName As %String)
{
	Do ##class(HS.Local.HSUK.Spine.Security.Key).IdIndexDelete(pApplicationName, "JWKS", "INT", 1, "test-1", .st)
	Do $$$AssertStatusOK(st)
	Do ..LogMessage("Test key deleted successfully")

	Quit $$$OK
}

Method OnBeforeProductionStart() As %Status
{
	/// Before the Spine production is started, we initialise a test key to test the GetAccessTokenProcess
	Do ..ImportKeyFileForApplication("TestSpine", "C:\Users\ahussain\Desktop\NHS Interfaces\keys\private_jwks.json")
	Do ..LogMessage("TestSpine test key created successfully")
	Quit $$$OK
}

Method OnAfterProductionStop() As %Status
{
	Do ..DeleteKeyForApplication("TestSpine")
	Do ..LogMessage("TestSpine test key deleted successfully")
	Quit $$$OK
}

Method GetAccessTokenProcessTest() As %Status
{
	Set key = ##class(HS.Local.HSUK.Spine.Security.Key).GetKey("TestSpine", "JWKS", "INT", 1, "test-1", .status)
	Do $$$AssertNotEquals(key, "")
	Do $$$AssertStatusOK(status)
	
	Do ..LogMessage("Checking if GetAccessTokenProcess works correctly..")

	Set req = ##class(HS.Local.HSUK.Spine.Message.AccessTokenRequest).%New()
	Set req.AccessMode = "APP"
	Set req.APIKey = "0GOfVy4StcE7UagvGG5eA5GOPCEG6Cio"
	Set req.ForceNew = 1
	Set req.KID = "test-1"
	Set req.Code = ""
	Set req.PrivateJWKS = key

	Do ..SendRequest("GetAccessToken", req, .response, 1, 10)

	Do $$$AssertTrue($ISOBJECT(response))
	Do $$$AssertNotEquals(response.AccessToken, "")
}

}
