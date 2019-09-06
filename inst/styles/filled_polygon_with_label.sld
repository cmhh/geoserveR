<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
 xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
 xmlns="http://www.opengis.net/sld"
 xmlns:sld="http://www.opengis.net/sld"
 xmlns:ogc="http://www.opengis.net/ogc"
 xmlns:xlink="http://www.w3.org/1999/xlink"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>{{ name }}</Name>
    <UserStyle>
      <Title>{{ title }}</Title>
      <Abstract>{{ abstract }}</Abstract>
      <FeatureTypeStyle>
        {{ fillRules }}
        <Rule>
          <PolygonSymbolizer>
            <Stroke>
              <CssParameter name="stroke">{{ strokeColor }}</CssParameter>
              <CssParameter name="stroke-width">{{ strokeWidth }}</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
        </Rule>
        <Rule>
          <MaxScaleDenominator>{{ maxScale }}</MaxScaleDenominator>
          <TextSymbolizer>
            <Geometry>
              <ogc:Function name="centroid">
                <ogc:PropertyName>{{ geometryName }}</ogc:PropertyName>
              </ogc:Function>
            </Geometry>
            <Label>
              <ogc:PropertyName>{{ labelName }}</ogc:PropertyName>
            </Label>
            <Font>
              <CssParameter name="font-family">{{ fontFamily }}</CssParameter>
              <CssParameter name="font-size">{{ fontSize }}</CssParameter>
              <CssParameter name="font-style">{{ fontStyle }}</CssParameter>
              <CssParameter name="font-weight">{{ fontWeight }}</CssParameter>
            </Font>
            <Fill>
              <CssParameter name="fill">{{ fontColor }}</CssParameter>
            </Fill>
            <Halo>
              <Radius>{{ haloSize }}</Radius>
              <Fill>
                <CssParameter name="fill">{{ haloColor }}</CssParameter>
              </Fill>
            </Halo>
            <LabelPlacement>
              <PointPlacement>
                <AnchorPoint>
                  <AnchorPointX>0.5</AnchorPointX>
                  <AnchorPointY>0.5</AnchorPointY>
                </AnchorPoint>
              </PointPlacement>
            </LabelPlacement>
            <VendorOption name="autoWrap">100</VendorOption>
            <VendorOption name="maxDisplacement">0</VendorOption>
            <VendorOption name="repeat">1</VendorOption>
            <VendorOption name="goodnessOfFit">1</VendorOption>
            <VendorOption name="group">yes</VendorOption>
            <VendorOption name="spaceAround">10</VendorOption>
            <VendorOption name="conflictResolution">true</VendorOption>
          </TextSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
