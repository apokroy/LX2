unit LX2SampleXML;

interface

const
  TestXml1: Utf8String =
  '''
  <?xml version="1.0"?>
  <Tests xmlns:tst="http://test/sample">
    <Test     TestType="CMD" tst:TestId="0001">
      <Name>Convert number to string</Name>
      <CommandLine>Examp1.EXE</CommandLine>
      <Input>1</Input>
      <Output>One</Output>
    </Test>
    <tst:Test TestId="0002" TestType="CMD">
      <Name>Find succeeding characters</Name>
      <CommandLine>Examp2.EXE</CommandLine>
      <Input>abc</Input>
      <Output>def</Output>
    </tst:Test>
    <Test TestId="0003" TestType="GUI">
      <Name>Convert multiple numbers to strings</Name>
      <CommandLine>Examp2.EXE /Verbose</CommandLine>
      <Input>123</Input>
      <Output>One Two Three</Output>
    </Test>
    <Test TestId="0004" TestType="GUI">
      <Name>Find correlated key</Name>
      <CommandLine>Examp3.EXE</CommandLine>
      <Input>a1</Input>
      <Output>b1</Output>
    </Test>
    <Test TestId="0005" TestType="GUI">
      <Name>Count characters</Name>
      <CommandLine>FinalExamp.EXE</CommandLine>
      <Input>This is a test</Input>
      <Output>14</Output>
    </Test>
    <Test TestId="0006" TestType="GUI">
      <Name>Another Test</Name>
      <CommandLine>Examp2.EXE</CommandLine>
      <Input>Test Input</Input>
      <Output>10</Output>
    </Test>
    <Test TestId="0007" TestType="GUI">
      <Name>Русские буковки</Name>
      <CommandLine>Examp2.EXE</CommandLine>
      <Input>Test Input</Input>
      <Output>10</Output>
    </Test>
  </Tests>
  ''';

  TestTransformXML =
  '''
  <?xml version="1.0" ?>
  <customers>
     <customer id="1" name="Acme, Inc.">
        <orders>
           <order order_no="1">
              <items>
                 <item item_no="1" quantity="10" />
                 <item item_no="2" quantity="2" />
                 <item item_no="3" quantity="1" />
              </items>
           </order>
           <order order_no="2">
              <items>
                 <item item_no="123" quantity="2" />
                 <item item_no="123" quantity="2" />
                 <item item_no="321" quantity="3" />
              </items>
           </order>
        </orders>
        <addresses>
           <address street="192 Prospect St" city="Auburn" state="MA" zip="01501" />
           <address street="50 Washington St" city="Westborough" state="MA" zip="01581" />
        </addresses>
     </customer>
     <customer id="2" name="Bubba Gump Shrimp Co, Inc.">
        <orders>
           <order order_no="3">
              <items>
                 <item item_no="654" quantity="1" />
              </items>
           </order>
        </orders>
        <addresses>
           <address street="1099 18th St, Suite 2500" city="Denver" state="CO" zip="80202" />
        </addresses>
     </customer>
  </customers>
  ''';

  TestTransformXSD =
  '''
  <?xml version="1.0" ?>
  <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
     <xsl:output method="xml" indent="yes" />
     <xsl:template match="/">
        <table>
           <xsl:apply-templates select="/customers/customer/orders/order" />
        </table>
     </xsl:template>
     <xsl:template match="order">
        <xsl:variable name="id" select="../../@id" />
        <xsl:apply-templates select="/customers/customer/addresses/address[../../@id =$id]">
           <xsl:with-param name="id" select="$id" />
           <xsl:with-param name="order_no" select="@order_no" />
        </xsl:apply-templates>
     </xsl:template>
     <xsl:template match="address">
        <xsl:param name="id" />
        <xsl:param name="order_no" />
        <row>
           <column name="CUSTOMER_ID">
              <xsl:value-of select="$id" />
           </column>
           <column name="ORDER_NO">
              <xsl:value-of select="$order_no" />
           </column>
           <column name="STREET">
              <xsl:value-of select="@street" />
           </column>
           <column name="CITY">
              <xsl:value-of select="@city" />
           </column>
           <column name="STATE">
              <xsl:value-of select="@state" />
           </column>
           <column name="ZIP">
              <xsl:value-of select="@zip" />
           </column>
        </row>
     </xsl:template>
  </xsl:stylesheet>
  ''';

implementation

end.
