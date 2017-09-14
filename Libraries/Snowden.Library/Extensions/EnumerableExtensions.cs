using System.Collections.Generic;
using System.Linq;

namespace Snowden.Library.Extensions
{
    public static class EnumerableExtensions
    {
        public static IEnumerable<IEnumerable<T>> CartesianProduct<T>(this IEnumerable<IEnumerable<T>> sequences)
        {
            IEnumerable<IEnumerable<T>> emptyProduct = new[] { Enumerable.Empty<T>() };
            return sequences.Aggregate(emptyProduct, (accumulator, sequence) => accumulator.SelectMany(accseq => sequence, (accseq, item) => accseq.Concat(new[] { item })));
        }
    }
}