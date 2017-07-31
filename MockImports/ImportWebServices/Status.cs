using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebApplication1
{

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.17929")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(Namespace = "http://www.bhpbilliton.com/waio/F1F2F3DataService")]
    public partial class Status
    {

        private string statusMessageField;

        private bool statusFlagField;

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(Form = System.Xml.Schema.XmlSchemaForm.Unqualified)]
        public string StatusMessage
        {
            get
            {
                return this.statusMessageField;
            }
            set
            {
                this.statusMessageField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(Form = System.Xml.Schema.XmlSchemaForm.Unqualified)]
        public bool StatusFlag
        {
            get
            {
                return this.statusFlagField;
            }
            set
            {
                this.statusFlagField = value;
            }
        }
    }
}