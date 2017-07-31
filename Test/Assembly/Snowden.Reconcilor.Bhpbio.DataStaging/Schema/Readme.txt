The Xsd2Code custom tool must be run on the ReconcilorMessages.xsd schema.

Unfortunately the code generated requires some additional attributes to be added.  

Please compare with previous generated code version for details.

Some property names are generated with a suffix of 1, where the property name clashes with a Type name.  An XmlElement attribute must be added to specify the correct element name.
Some array / list properties require an xml element to name the expected child element name.