/// 
/// This class test the key generation for Spine. It ensures that a valid key can be generated
/// and is stored successfully within the database
/// 
Class HS.Local.HSUK.Testing.Spine.KeyGeneration Extends %UnitTest.TestCase [ Abstract ]
{

Parameter KID = "test-1";

Parameter KEYALGORITHM = "RS512";

Parameter APPLICATION = "Test";

Property KeyPath;

Property PublicKeyPath;

Property PrivateKeyPath;

Property PublicJWKSPath;

Property PrivateJWKSPath;

// Helper methods

Method EnsureKeyFilesExist()
{
	Do $$$AssertTrue(##class(%File).Exists(..PublicKeyPath), "Ensure public key file exists")
	Do $$$AssertTrue(##class(%File).Exists(..PrivateKeyPath), "Ensure private key fjle exists")
	Do $$$AssertTrue(##class(%File).Exists(..PublicJWKSPath), "Ensure public JWKS file exists")
	Do $$$AssertTrue(##class(%File).Exists(..PrivateJWKSPath), "Ensure private JWKS file exists")
}

Method EnsureKeyFilesDoNotExist()
{
	Do $$$AssertNotTrue(##class(%File).Exists(..PublicKeyPath), "Ensure public key file does not exist")
	Do $$$AssertNotTrue(##class(%File).Exists(..PrivateKeyPath), "Ensure private key fjle does not exist")
	Do $$$AssertNotTrue(##class(%File).Exists(..PublicJWKSPath), "Ensure public JWKS file does not exist")
	Do $$$AssertNotTrue(##class(%File).Exists(..PrivateJWKSPath), "Ensure private JWKS file does not exist")
}

Method OnBeforeAllTests() As %Status
{
	Set ..KeyPath = ##class(%File).ManagerDirectory() _ "jwkskeys"
	Set ..PublicKeyPath = ##class(%File).NormalizeFilename("public_key.pem", ..KeyPath)
	Set ..PrivateKeyPath = ##class(%File).NormalizeFilename("private_key.pem", ..KeyPath)
	Set ..PublicJWKSPath = ##class(%File).NormalizeFilename("public_jwks.json", ..KeyPath)
	Set ..PrivateJWKSPath = ##class(%File).NormalizeFilename("private_jwks.json", ..KeyPath)

	Do ..EnsureKeyFilesDoNotExist()

	// Create the directory for the keypath
	Do $$$AssertTrue(##class(%File).CreateDirectory(..KeyPath))

	Quit $$$OK
}

Method OnAfterAllTests() As %Status
{
	// Delete key files if they already exists
	Do ##class(%File).Delete(..PublicKeyPath)
	Do ##class(%File).Delete(..PrivateKeyPath)
	Do ##class(%File).Delete(..PublicJWKSPath)
	Do ##class(%File).Delete(..PrivateJWKSPath)

	// Delete keys from storage
	Do ##class(HS.Local.HSUK.Spine.Security.Key).%DeleteExtent()
	Do ##class(HS.Local.HSUK.Spine.Security.Key).%KillExtent()

	Do ..EnsureKeyFilesExist()

	Quit $$$OK
}

/// This method tests to see if generating a key file is successful
Method TestKeyFileGeneration() As %Status
{
	
	Do ..LogMessage("Writing keys to path " _ ..KeyPath)
	Write "Public key path: " _ ..PublicKeyPath,!
	Write "Private key path: " _ ..PrivateKeyPath,!
	Write "Public JWKS path: " _ ..PublicJWKSPath,!
	Write "Private JWKS path: " _ ..PrivateJWKSPath,!

	/// We first create the JWKSFile, ensure it works and then import the key from the file
	Set sc = ##class(HS.Local.HSUK.Spine.Security.Util).CreateJWKSFile(..#KEYALGORITHM, ..#KID, "", ..PrivateKeyPath, ..PublicKeyPath, ..PrivateJWKSPath, ..PublicJWKSPath)

	Do $$$AssertStatusOK(sc)
	Do ..EnsureKeyFilesExist()

	// Now that the files have been created, import the key from the file
	Set sc = ##class(HS.Local.HSUK.Spine.Security.Key).LoadKeyFromFile(..#APPLICATION, "JWKS", "INT", 1, ..#KID, ..PrivateJWKSPath, 0, 1)
	Do $$$AssertStatusOK(sc)

	// Ensure the key can be retrieved
	Set key = ##class(HS.Local.HSUK.Spine.Security.Key).GetKey(..#APPLICATION, "JWKS", "INT", 1, ..#KID, .status)
	Do $$$AssertNotEquals(key, "")
	Do $$$AssertStatusOK(status)
}

}
