using System.Data;

namespace WebApplication1
{

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.17929")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(Namespace = "http://www.bhpbilliton.com/waio/F1F2F3DataService")]
    public partial class Grade
    {

        private string nameField;

        private double sampleValueField;

        private bool sampleValueFieldSpecified;

        private double headValueField;

        private bool headValueFieldSpecified;

        private double finesValueField;

        private bool finesValueFieldSpecified;

        private double lumpValueField;

        private bool lumpValueFieldSpecified;
        private System.Data.DataRow r;

        public Grade(System.Data.DataRow r)
        {
            this.r = r;
            Name = r.Field<string>("GradeName");

            if (r.Table.Columns.Contains("SampleValue"))
            {
                SampleValue = r.Field<double>("SampleValue");
                SampleValueSpecified = true;
            }
            else
            {
                SampleValueSpecified = false;
            }
            if (r.Table.Columns.Contains("HeadValue"))
            {
                HeadValue = r.Field<double>("HeadValue");
                HeadValueSpecified = true;
            }
            else
            {
                HeadValueSpecified = false;
            }
            if (r.Table.Columns.Contains("FinesValue"))
            {
                FinesValue = r.Field<double>("FinesValue");
                FinesValueSpecified = true;
            }
            else
            {
                FinesValueSpecified = false;
            }
            if (r.Table.Columns.Contains("LumpValue"))
            {
                LumpValue = r.Field<double>("LumpValue");
                LumpValueSpecified = true;
            }
            else
            {
                LumpValueSpecified = false;
            }
        }

        public Grade()
        {
            SampleValueSpecified = false;
            HeadValueSpecified = false;
            FinesValueSpecified = false;
            LumpValueSpecified = false;
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(Form = System.Xml.Schema.XmlSchemaForm.Unqualified)]
        public string Name
        {
            get
            {
                return this.nameField;
            }
            set
            {
                this.nameField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(Form = System.Xml.Schema.XmlSchemaForm.Unqualified)]
        public double SampleValue
        {
            get
            {
                return this.sampleValueField;
            }
            set
            {
                this.sampleValueField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlIgnoreAttribute()]
        public bool SampleValueSpecified
        {
            get
            {
                return this.sampleValueFieldSpecified;
            }
            set
            {
                this.sampleValueFieldSpecified = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(Form = System.Xml.Schema.XmlSchemaForm.Unqualified)]
        public double HeadValue
        {
            get
            {
                return this.headValueField;
            }
            set
            {
                this.headValueField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlIgnoreAttribute()]
        public bool HeadValueSpecified
        {
            get
            {
                return this.headValueFieldSpecified;
            }
            set
            {
                this.headValueFieldSpecified = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(Form = System.Xml.Schema.XmlSchemaForm.Unqualified)]
        public double FinesValue
        {
            get
            {
                return this.finesValueField;
            }
            set
            {
                this.finesValueField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlIgnoreAttribute()]
        public bool FinesValueSpecified
        {
            get
            {
                return this.finesValueFieldSpecified;
            }
            set
            {
                this.finesValueFieldSpecified = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(Form = System.Xml.Schema.XmlSchemaForm.Unqualified)]
        public double LumpValue
        {
            get
            {
                return this.lumpValueField;
            }
            set
            {
                this.lumpValueField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlIgnoreAttribute()]
        public bool LumpValueSpecified
        {
            get
            {
                return this.lumpValueFieldSpecified;
            }
            set
            {
                this.lumpValueFieldSpecified = value;
            }
        }
    }
}