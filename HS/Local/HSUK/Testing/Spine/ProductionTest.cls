/// 
/// This class contains test for a base Spine production.
/// 
/// The Base Spine production contains a "PDSProcess" of class "HS.Local.HSUK.Spine.PDS.Process.PDSProcess"
/// and a SpineOperation
Class HS.Local.HSUK.Testing.Spine.ProductionTest Extends %UnitTest.TestProduction
{

Parameter PRODUCTION = "HS.Local.HSUK.DefaultProduction";

Parameter IGNOREPRODUCTIONERRORS = 0;

Method OnAfterProductionStart() As %Status
{
	Do ..PDSProcessTest()
	
	Quit $$$OK
}

Method CreateKeyForApplication(pApplicationName As %String) As HS.Local.HSUK.Spine.Security.Key
{
	Set KeyPath = ##class(%File).ManagerDirectory() _ "jwkskeys"
	Set PublicKeyPath = ##class(%File).NormalizeFilename("public_key.pem", KeyPath)
	Set PrivateKeyPath = ##class(%File).NormalizeFilename("private_key.pem", KeyPath)
	Set PublicJWKSPath = ##class(%File).NormalizeFilename("public_jwks.json", KeyPath)
	Set PrivateJWKSPath = ##class(%File).NormalizeFilename("private_jwks.json", KeyPath)

	// Create the directory for the keypath
	Do ##class(%File).CreateDirectory(KeyPath)

	// Create the Test key
	Do:##class(%File).Exists(PrivateJWKSPath) ##class(%File).Delete(PrivateJWKSPath)

	Do $$$AssertNotTrue(##class(%File).Exists(PrivateJWKSPath), "Assert private key path does not exist before key creation")
	Set sc = ##class(HS.Local.HSUK.Spine.Security.Util).CreateJWKSFile("RS512", "test-1", "", PrivateKeyPath, PublicKeyPath, PrivateJWKSPath, PublicJWKSPath)
	Do $$$AssertStatusOK(sc)
	Do $$$AssertTrue(##class(%File).Exists(PrivateKeyPath), "Assert private key path exists after key creation")

	// Now that the files have been created, import the key from the file
	Set sc = ##class(HS.Local.HSUK.Spine.Security.Key).LoadKeyFromFile(pApplicationName, "JWKS", "INT", 1, "test-1", PrivateJWKSPath, 0, 1)
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
	Do ..CreateKeyForApplication("TestSpine")
	Do ..LogMessage("TestSpine test key created successfully")
	Quit $$$OK
}

Method OnAfterProductionStop() As %Status
{
	Do ..DeleteKeyForApplication("TestSpine")
	Do ..LogMessage("TestSpine test key deleted successfully")
	Quit $$$OK
}

Method PDSProcessTest() As %Status
{
	Set req = ##class(HS.Local.HSUK.Spine.Message.AccessTokenRequest).%New()
	Set req.AccessMode = "APP"
	Set req.APIKey = "0GOfVy4StcE7UagvGG5eA5GOPCEG6Cio"
	Set req.ForceNew = 1
	#; Set req.KID
}

}
