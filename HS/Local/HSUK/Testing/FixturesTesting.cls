/// This class should use a ^FIXTURES global to hold JSON data
/// This data should then be imported using ##class(%DynamicObject).%FromJSON()
/// 
/// You can then use this fixtures data to "play" NHS messages and modify the responses.
/// Key part of this is that the fixtures is a JSON file which can be modified by the developer
/// to enable their own testing methods
/// The fixtures should contain the HttpResponse codes and should only really specify the properties
/// of each request/response messages and their types.
/// 
/// The Testing framework will only really need the fixtures to run. Technically we don't even need any ObjectScript code, we should be
/// able to run tests by modifying the fixtures. These fixtures will then play messages, and as long as their arent any errors in the production
/// we should be good to go.....?
Class HS.Local.HSUK.Testing.FixturesTesting Extends %RegisteredObject
{

}
