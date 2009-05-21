/* ****************************************************************************
 *
 * Copyright (c) Microsoft Corporation. 
 *
 * This source code is subject to terms and conditions of the Microsoft Public License. A 
 * copy of the license can be found in the License.html file at the root of this distribution. If 
 * you cannot locate the  Microsoft Public License, please send an email to 
 * dlr@microsoft.com. By using this source code in any fashion, you are agreeing to be bound 
 * by the terms of the Microsoft Public License.
 *
 * You must not remove this notice, or any other, from this software.
 *
 *
 * ***************************************************************************/

using System.ComponentModel;
using System.Diagnostics;
using System.Dynamic.Utils;
using System.Runtime.CompilerServices;

namespace System.Dynamic {
    /// <summary>
    /// This API supports the .NET Framework infrastructure and is not intended to be used directly from your code.
    /// Represents a cache of runtime binding rules.
    /// </summary>
    /// <typeparam name="T">The delegate type.</typeparam>
    [EditorBrowsable(EditorBrowsableState.Never), DebuggerStepThrough]
    public class RuleCache<T> where T : class {
        private CallSiteRule<T>[] _rules = new CallSiteRule<T>[0];
        private readonly Object cacheLock = new Object();

        private const int MaxRules = 128;

        internal RuleCache() { }

        internal CallSiteRule<T>[] GetRules() {
            return _rules;
        }

        // move the rule +2 up.
        // this is called on every successful rule.
        internal void MoveRule(T rule, int i) {
            // limit search to MaxSearch elements. 
            // Rule should not get too far unless it has been already moved up.
            // need a lock to make sure we are moving the right rule and not loosing any.
            lock (cacheLock) {
                const int MaxSearch = 8;
                int count = _rules.Length - i;
                if (count > MaxSearch) {
                    count = MaxSearch;
                }

                int oldIndex = -1;
                int max = Math.Min(_rules.Length, i + count);
                for (int index = i; index < max; index++) {
                    if (_rules[index].Target == rule) {
                        oldIndex = index;
                        break;
                    }
                }
                if (oldIndex < 0) {
                    return;
                }
                CallSiteRule<T> oldRule = _rules[oldIndex];
                _rules[oldIndex] = _rules[oldIndex - 1];
                _rules[oldIndex - 1] = _rules[oldIndex - 2];
                _rules[oldIndex - 2] = oldRule;
            }
        }

        internal void AddRule(CallSiteRule<T> newRule) {
            // need a lock to make sure we are not loosing rules.
            lock (cacheLock) {
                _rules = AddOrInsert(_rules, newRule);
            }
        }

        internal void ReplaceRule(CallSiteRule<T> oldRule, CallSiteRule<T> newRule) {
            // need a lock to make sure we are replacing the right rule
            lock (cacheLock) {
                int i = Array.IndexOf(_rules, oldRule);
                if (i >= 0) {
                    _rules[i] = newRule;
                    return; // DONE
                }

                // could not find it.
                _rules = AddOrInsert(_rules, newRule);
            }
        }


        // Adds to end or or inserts items at InsertPosition
        private const int InsertPosition = MaxRules / 2;

        private static CallSiteRule<T>[] AddOrInsert(CallSiteRule<T>[] rules, CallSiteRule<T> item) {
            if (rules.Length < InsertPosition) {
                return rules.AddLast(item);
            }

            CallSiteRule<T>[] newRules;

            int newLength = rules.Length + 1;
            if (newLength > MaxRules) {
                newLength = MaxRules;
                newRules = rules;
            } else {
                newRules = new CallSiteRule<T>[newLength];
            }

            Array.Copy(rules, 0, newRules, 0, InsertPosition);
            newRules[InsertPosition] = item;
            Array.Copy(rules, InsertPosition, newRules, InsertPosition + 1, newLength - InsertPosition - 1);
            return newRules;
        }
    }
}