Class TestingClient.Example.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="TestingClient.Example.Production" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description>TestingClient Test Production</Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Item Name="MyOperation" Category="" ClassName="TestingClient.Example.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
