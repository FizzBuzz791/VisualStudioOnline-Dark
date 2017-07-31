using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(ShippingTgtImport.Startup))]
namespace ShippingTgtImport
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            
        }
    }
}
