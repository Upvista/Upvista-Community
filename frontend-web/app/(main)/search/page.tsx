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
      <div className="space-y-6 max-w-4xl mx-auto">
        {/* Header */}
        <div>
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-neutral-50 mb-2">
            Search
          </h1>
          <p className="text-base text-neutral-600 dark:text-neutral-400">
            Find and connect with developers, designers, and creators
          </p>
        </div>

        {/* Search Input */}
        <Card variant="solid" hoverable={false}>
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Search by name, username, bio, or location..."
              value={query}
              onChange={(e) => {
                setQuery(e.target.value);
                setPage(1);
              }}
              className="w-full pl-12 pr-4 py-3 bg-neutral-50 dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 rounded-xl text-neutral-900 dark:text-neutral-50 placeholder:text-neutral-400 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-transparent"
              autoFocus
            />
          </div>
        </Card>

        {/* Loading State */}
        {loading && (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="w-8 h-8 animate-spin text-brand-purple-600" />
          </div>
        )}

        {/* Results */}
        {!loading && hasSearched && (
          <>
            {/* Results Header */}
            {results.length > 0 && (
              <div className="flex items-center justify-between">
                <p className="text-sm text-neutral-600 dark:text-neutral-400">
                  Found {total} {total === 1 ? 'user' : 'users'}
                </p>
              </div>
            )}

            {/* Results List */}
            {results.length > 0 ? (
              <div className="space-y-3">
                {results.map((user) => (
                  <UserCard key={user.id} user={user} />
                ))}
              </div>
            ) : (
              <Card variant="solid" hoverable={false}>
                <div className="text-center py-12">
                  <Users className="w-16 h-16 mx-auto mb-4 text-neutral-300 dark:text-neutral-700" />
                  <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
                    No users found
                  </h3>
                  <p className="text-sm text-neutral-600 dark:text-neutral-400">
                    Try a different search term or check your spelling
                  </p>
                </div>
              </Card>
            )}

            {/* Pagination */}
            {results.length > 0 && total > 20 && (
              <div className="flex items-center justify-center gap-2">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-4 py-2 bg-white dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-neutral-50 dark:hover:bg-neutral-700 transition-colors"
                >
                  Previous
                </button>
                <span className="text-sm text-neutral-600 dark:text-neutral-400">
                  Page {page} of {Math.ceil(total / 20)}
                </span>
                <button
                  onClick={() => setPage((p) => p + 1)}
                  disabled={page >= Math.ceil(total / 20)}
                  className="px-4 py-2 bg-white dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-neutral-50 dark:hover:bg-neutral-700 transition-colors"
                >
                  Next
                </button>
              </div>
            )}
          </>
        )}

        {/* Empty State - Before Search */}
        {!hasSearched && !loading && (
          <Card variant="solid" hoverable={false}>
            <div className="text-center py-16">
              <Search className="w-20 h-20 mx-auto mb-4 text-neutral-200 dark:text-neutral-800" />
              <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
                Search for people
              </h3>
              <p className="text-sm text-neutral-600 dark:text-neutral-400 max-w-md mx-auto">
                Find developers, designers, engineers, and creators to connect with.
                Search by name, username, location, or interests.
              </p>
            </div>
      </Card>
        )}
      </div>
    </MainLayout>
  );
}

