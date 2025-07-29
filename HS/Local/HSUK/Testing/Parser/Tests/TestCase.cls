Class HS.Local.HSUK.Testing.Parser.Tests.TestCase Extends %RegisteredObject
{

Property TargetProduction As %String;

Property TargetHost As %String;

Property TargetHostClass As %String;

Property Interactions As list Of HS.Local.HSUK.Testing.Parser.Tests.Interaction;

Method %OnNew(pProductionName As %String)
{
	/// We do not validate the production name and assume the production is valid
	Set ..TargetProduction = pProductionName
}

/// Runs the test suite, this will run all interactions against the TargetHost.
/// Verifies that the TargetHost has the TargetHostClass as it's class name
Method RunTestsOnProduction(pProductionName As %String)
{
	///
}
Method ValidateBusinessComponent()
Method RunInteraction(pInteraction As HS.Local.HSUK.Testing.Parser.Tests.Interaction) [Private] {
	/// Send the MessageRequest from the interaction and validate the response


}
