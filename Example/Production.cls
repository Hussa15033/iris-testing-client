Class APTT.Example.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="APTT.Example.Production" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description>APTT Test Production</Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Item Name="MyOperation" Category="" ClassName="APTT.Example.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
