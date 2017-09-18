using System;
using System.Collections.Generic;
using System.Linq;

namespace Snowden.Library.Extensions
{
    public static class EnumerableExtensions
    {
        public static IEnumerable<IEnumerable<TSource>> CartesianProduct<TSource>(
            this IEnumerable<IEnumerable<TSource>> sequences)
        {
            IEnumerable<IEnumerable<TSource>> emptyProduct = new[] {Enumerable.Empty<TSource>()};
            return sequences.Aggregate(emptyProduct,
                (accumulator, sequence) =>
                    accumulator.SelectMany(accseq => sequence, (accseq, item) => accseq.Concat(new[] {item})));
        }

        /// <summary>
        /// Distinct by a particular propery. See example for usage.
        /// </summary>
        /// <typeparam name="TSource"></typeparam>
        /// <typeparam name="TKey"></typeparam>
        /// <param name="source"></param>
        /// <param name="keySelector"></param>
        /// <returns></returns>
        /// <example>var query = list.DistinctBy(l => l.Id);</example>
        public static IEnumerable<TSource> DistinctBy<TSource, TKey>(this IEnumerable<TSource> source,
            Func<TSource, TKey> keySelector)
        {
            HashSet<TKey> seenKeys = new HashSet<TKey>();
            foreach (TSource element in source)
            {
                if (seenKeys.Add(keySelector(element)))
                {
                    yield return element;
                }
            }
        }
    }
}