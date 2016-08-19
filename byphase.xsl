<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" version="4.0" encoding="iso-8859-1" indent="yes" standalone="yes" />
   <xsl:template match="/">
<html>
   <body>
   <xsl:for-each select="//phases/phase">
     <h2><xsl:value-of select="./title" /></h2>
     <table border="1">
       <thead>
       <tr>
         <th>Item</th>
         <th>Effort fp</th>
       </tr>
       </thead>
       <tbody>
       <xsl:for-each select="//items/item[string(./phase)=string(current()/title)]">
       <tr>
         <td><xsl:value-of select="./title" /></td>
         <td><xsl:value-of select="./estimation_fp" /></td>
       </tr>
       </xsl:for-each>
       </tbody>
       <tfoot>
       <tr>
         <td><em>Sum</em></td>
         <td><em><xsl:value-of select="sum(//items/item[string(./phase)=string(current()/title)]/estimation_fp)" /></em></td>
       </tr>
       </tfoot>
     </table>
   </xsl:for-each>
   </body>
</html>
   </xsl:template>
</xsl:stylesheet>