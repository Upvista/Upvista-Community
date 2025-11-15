'use client';

/**
 * Search Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Search for users, connect with the community
 */

import { useState, useEffect } from 'react';
import { MainLayout } from '@/components/layout/MainLayout';
import { Card } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import UserCard from '@/components/search/UserCard';
import { Search, Loader2, Users, Filter } from 'lucide-react';

interface SearchUser {
  id: string;
  username: string;
  display_name: string;
  profile_picture?: string | null;
  bio?: string | null;
  location?: string | null;
  is_verified: boolean;
  followers_count?: number;
  following_count?: number;
}

export default function SearchPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchUser[]>([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [hasSearched, setHasSearched] = useState(false);

  useEffect(() => {
    const delaySearch = setTimeout(() => {
      if (query.trim().length >= 2) {
        performSearch();
      } else {
        setResults([]);
        setTotal(0);
        setHasSearched(false);
      }
    }, 500); // Debounce 500ms

    return () => clearTimeout(delaySearch);
  }, [query, page]);

  const performSearch = async () => {
    setLoading(true);
    setHasSearched(true);

    try {
      const response = await fetch(
        `/api/proxy/v1/search/users?q=${encodeURIComponent(query)}&page=${page}&limit=20`
      );

      if (response.ok) {
        const data = await response.json();
        setResults(data.users || []);
        setTotal(data.total || 0);
      } else {
        console.error('Search failed:', response.status);
        setResults([]);
        setTotal(0);
      }
    } catch (error) {
      console.error('Search error:', error);
      setResults([]);
      setTotal(0);
    } finally {
      setLoading(false);
    }
  };

  return (
    <MainLayout>
      <div className="max-w-4xl mx-auto">
        {/* Search Bar - Clean & Professional */}
        <div className="sticky top-0 z-10 bg-white dark:bg-neutral-900 pb-4 mb-6 border-b border-neutral-200 dark:border-neutral-800">
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400 dark:text-neutral-500" />
            <input
              type="text"
              placeholder="Search people by name, username, bio, or location..."
              value={query}
              onChange={(e) => {
                setQuery(e.target.value);
                setPage(1);
              }}
              className="w-full pl-12 pr-4 py-3.5 bg-neutral-50 dark:bg-neutral-800/50 border border-neutral-200 dark:border-neutral-700 rounded-xl text-neutral-900 dark:text-neutral-50 placeholder:text-neutral-400 dark:placeholder:text-neutral-500 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all text-base"
              autoFocus
            />
            {loading && (
              <Loader2 className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 animate-spin text-purple-600" />
            )}
          </div>
        </div>

        {/* Results Section */}
        {hasSearched && (
          <>
            {/* Results Header */}
            {results.length > 0 && !loading && (
              <div className="flex items-center justify-between mb-4">
                <p className="text-sm font-medium text-neutral-600 dark:text-neutral-400">
                  {total} {total === 1 ? 'result' : 'results'}
                </p>
              </div>
            )}

            {/* Results List */}
            {loading ? (
              <div className="flex items-center justify-center py-16">
                <div className="text-center">
                  <Loader2 className="w-10 h-10 animate-spin text-purple-600 mx-auto mb-3" />
                  <p className="text-sm text-neutral-500 dark:text-neutral-400">Searching...</p>
                </div>
              </div>
            ) : results.length > 0 ? (
              <div className="space-y-3">
                {results.map((user) => (
                  <UserCard key={user.id} user={user} />
                ))}
              </div>
            ) : (
              <div className="text-center py-16">
                <Users className="w-16 h-16 mx-auto mb-4 text-neutral-300 dark:text-neutral-700" />
                <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
                  No results found
                </h3>
                <p className="text-sm text-neutral-600 dark:text-neutral-400">
                  Try adjusting your search or check your spelling
                </p>
              </div>
            )}

            {/* Pagination */}
            {results.length > 0 && total > 20 && !loading && (
              <div className="flex items-center justify-center gap-3 pt-4 mt-6 border-t border-neutral-200 dark:border-neutral-800">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-5 py-2.5 bg-white dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 rounded-lg disabled:opacity-40 disabled:cursor-not-allowed hover:bg-neutral-50 dark:hover:bg-neutral-700 transition-colors font-medium text-sm text-neutral-700 dark:text-neutral-300"
                >
                  Previous
                </button>
                <span className="text-sm font-medium text-neutral-600 dark:text-neutral-400 px-2">
                  {page} / {Math.ceil(total / 20)}
                </span>
                <button
                  onClick={() => setPage((p) => p + 1)}
                  disabled={page >= Math.ceil(total / 20)}
                  className="px-5 py-2.5 bg-white dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 rounded-lg disabled:opacity-40 disabled:cursor-not-allowed hover:bg-neutral-50 dark:hover:bg-neutral-700 transition-colors font-medium text-sm text-neutral-700 dark:text-neutral-300"
                >
                  Next
                </button>
              </div>
            )}
          </>
        )}

        {/* Empty State - Before Search */}
        {!hasSearched && !loading && (
          <div className="text-center py-20">
            <div className="w-20 h-20 mx-auto mb-6 rounded-full bg-gradient-to-br from-purple-50 to-purple-100 dark:from-purple-900/20 dark:to-purple-800/20 flex items-center justify-center">
              <Search className="w-10 h-10 text-purple-600 dark:text-purple-400" />
            </div>
            <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-3">
              Discover amazing people
            </h3>
            <p className="text-sm text-neutral-500 dark:text-neutral-400 max-w-md mx-auto leading-relaxed">
              Search for developers, designers, creators, and professionals. Connect with the community.
            </p>
          </div>
        )}
      </div>
    </MainLayout>
  );
}

