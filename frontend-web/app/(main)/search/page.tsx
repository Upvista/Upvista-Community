'use client';

/**
 * Professional Search Page - Minimal & Clean Design
 * Focus on functionality with professional aesthetics
 */

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { MainLayout } from '@/components/layout/MainLayout';
import { Avatar } from '@/components/ui/Avatar';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import VerifiedBadge from '@/components/ui/VerifiedBadge';
import { 
  Search, 
  Loader2, 
  X,
  MapPin,
  Users,
  Filter,
  SlidersHorizontal
} from 'lucide-react';

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

type FilterType = 'all' | 'verified' | 'professionals' | 'creators';
type SortType = 'relevance' | 'followers' | 'recent';

export default function SearchPage() {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchUser[]>([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [hasSearched, setHasSearched] = useState(false);
  const [recentSearches, setRecentSearches] = useState<string[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [activeFilter, setActiveFilter] = useState<FilterType>('all');
  const [sortBy, setSortBy] = useState<SortType>('relevance');
  const [showFilters, setShowFilters] = useState(false);
  const searchInputRef = useRef<HTMLInputElement>(null);
  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);

  // Load recent searches from localStorage
  useEffect(() => {
    const saved = localStorage.getItem('recentSearches');
    if (saved) {
      try {
        setRecentSearches(JSON.parse(saved).slice(0, 5));
      } catch (e) {
        // Ignore parse errors
      }
    }
  }, []);

  // Save search to recent searches
  const saveToRecentSearches = (searchQuery: string) => {
    if (!searchQuery.trim() || searchQuery.length < 2) return;
    
    setRecentSearches((prev) => {
      const updated = [
        searchQuery,
        ...prev.filter(s => s.toLowerCase() !== searchQuery.toLowerCase())
      ].slice(0, 5);
      localStorage.setItem('recentSearches', JSON.stringify(updated));
      return updated;
    });
  };

  const performSearch = async () => {
    if (query.trim().length < 2) return;
    
    setLoading(true);
    setHasSearched(true);
    setShowSuggestions(false);
    
    // Save to recent searches
    if (query.trim().length >= 2) {
      saveToRecentSearches(query);
    }

    try {
      const params = new URLSearchParams({
        q: query.trim(),
        page: page.toString(),
        limit: '20',
      });

      // Add filters if not 'all'
      if (activeFilter === 'verified') {
        params.append('verified', 'true');
      }

      const response = await fetch(`/api/proxy/v1/search/users?${params.toString()}`);

      if (response.ok) {
        const data = await response.json();
        let users = data.users || [];
        
        // Client-side sorting
        if (sortBy === 'followers') {
          users = users.sort((a: SearchUser, b: SearchUser) => 
            (b.followers_count || 0) - (a.followers_count || 0)
          );
        }
        
        setResults(users);
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

  // Debounced search
  useEffect(() => {
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
    }

    if (query.trim().length >= 2) {
      debounceTimerRef.current = setTimeout(() => {
        performSearch();
      }, 400);
    } else {
      setResults([]);
      setTotal(0);
      setHasSearched(false);
      setShowSuggestions(query.length > 0);
    }

    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [query, page, activeFilter, sortBy]);

  const handleSearch = (searchQuery: string) => {
    setQuery(searchQuery);
    setPage(1);
    setShowSuggestions(false);
    searchInputRef.current?.blur();
  };

  const clearSearch = () => {
    setQuery('');
    setResults([]);
    setTotal(0);
    setHasSearched(false);
    setPage(1);
    setShowSuggestions(false);
    setActiveFilter('all');
    setSortBy('relevance');
    searchInputRef.current?.focus();
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      setShowSuggestions(false);
      searchInputRef.current?.blur();
    } else if (e.key === 'Enter' && query.trim().length >= 2) {
      performSearch();
    }
  };

  const formatNumber = (num?: number) => {
    if (!num) return '0';
    if (num >= 1000000) return `${(num / 1000000).toFixed(1)}M`;
    if (num >= 1000) return `${(num / 1000).toFixed(1)}K`;
    return num.toString();
  };

  const quickFilters: { id: FilterType; label: string }[] = [
    { id: 'all', label: 'All' },
    { id: 'verified', label: 'Verified' },
    { id: 'professionals', label: 'Professionals' },
    { id: 'creators', label: 'Creators' },
  ];

  return (
    <MainLayout>
      <div className="min-h-screen bg-white dark:bg-neutral-950">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Search Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
              Search
            </h1>
            <p className="text-sm text-neutral-600 dark:text-neutral-400">
              Find people, professionals, and creators
            </p>
          </div>

          {/* Search Bar */}
          <div className="relative mb-6">
            <div className="relative">
              <div className="absolute left-4 top-1/2 -translate-y-1/2 z-10">
                <Search className="w-5 h-5 text-neutral-400" />
              </div>
              
              <input
                ref={searchInputRef}
                type="text"
                placeholder="Search by name, username, or location..."
                value={query}
                onChange={(e) => {
                  setQuery(e.target.value);
                  setPage(1);
                  setShowSuggestions(true);
                }}
                onKeyDown={handleKeyDown}
                onFocus={() => {
                  if (query.length > 0 || recentSearches.length > 0) {
                    setShowSuggestions(true);
                  }
                }}
                className="w-full pl-12 pr-12 py-3 bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-lg text-neutral-900 dark:text-neutral-50 placeholder:text-neutral-500 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-transparent transition-all"
                autoFocus
              />

              {query && (
                <button
                  onClick={clearSearch}
                  className="absolute right-12 top-1/2 -translate-y-1/2 p-1 rounded hover:bg-neutral-200 dark:hover:bg-neutral-800 transition-colors"
                  aria-label="Clear search"
                >
                  <X className="w-4 h-4 text-neutral-400" />
                </button>
              )}

              {loading && (
                <div className="absolute right-4 top-1/2 -translate-y-1/2">
                  <Loader2 className="w-5 h-5 animate-spin text-brand-purple-600" />
                </div>
              )}

              {/* Search Suggestions */}
              {showSuggestions && !hasSearched && (query.length > 0 || recentSearches.length > 0) && (
                <div className="absolute top-full left-0 right-0 mt-2 bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-lg shadow-lg overflow-hidden z-30">
                  {recentSearches.length > 0 && query.length === 0 && (
                    <div className="p-3 border-b border-neutral-200 dark:border-neutral-800">
                      <p className="text-xs font-medium text-neutral-500 dark:text-neutral-400 mb-2 px-2">
                        Recent Searches
                      </p>
                      <div className="space-y-1">
                        {recentSearches.map((search, idx) => (
                          <button
                            key={idx}
                            onClick={() => handleSearch(search)}
                            className="w-full text-left px-3 py-2 rounded hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors text-sm text-neutral-700 dark:text-neutral-300"
                          >
                            {search}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                  
                  {query.length > 0 && (
                    <button
                      onClick={() => handleSearch(query)}
                      className="w-full text-left px-4 py-3 hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors text-sm font-medium text-neutral-900 dark:text-neutral-50 flex items-center gap-3"
                    >
                      <Search className="w-4 h-4 text-neutral-400" />
                      Search for "{query}"
                    </button>
                  )}
                </div>
              )}
            </div>

            {/* Filters */}
            {hasSearched && (
              <div className="mt-4 flex items-center gap-3 flex-wrap">
                <button
                  onClick={() => setShowFilters(!showFilters)}
                  className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-neutral-700 dark:text-neutral-300 hover:text-neutral-900 dark:hover:text-neutral-50 border border-neutral-200 dark:border-neutral-800 rounded-lg hover:bg-neutral-50 dark:hover:bg-neutral-900 transition-colors"
                >
                  <SlidersHorizontal className="w-4 h-4" />
                  Filters
                </button>

                {quickFilters.map((filter) => {
                  const isActive = activeFilter === filter.id;
                  return (
                    <button
                      key={filter.id}
                      onClick={() => {
                        setActiveFilter(filter.id);
                        setPage(1);
                      }}
                      className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${
                        isActive
                          ? 'bg-brand-purple-600 text-white'
                          : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-200 dark:hover:bg-neutral-700'
                      }`}
                    >
                      {filter.label}
                    </button>
                  );
                })}
              </div>
            )}

            {/* Advanced Filters Panel */}
            {showFilters && hasSearched && (
              <div className="mt-4 p-4 bg-neutral-50 dark:bg-neutral-900 rounded-lg border border-neutral-200 dark:border-neutral-800">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-sm font-semibold text-neutral-900 dark:text-neutral-50 flex items-center gap-2">
                    <Filter className="w-4 h-4" />
                    Sort Options
                  </h3>
                  <button
                    onClick={() => setShowFilters(false)}
                    className="p-1 rounded hover:bg-neutral-200 dark:hover:bg-neutral-800"
                  >
                    <X className="w-4 h-4 text-neutral-500" />
                  </button>
                </div>
                
                <div className="flex flex-wrap gap-2">
                  {[
                    { id: 'relevance', label: 'Relevance' },
                    { id: 'followers', label: 'Most Followers' },
                    { id: 'recent', label: 'Recently Active' },
                  ].map((sort) => {
                    const isActive = sortBy === sort.id;
                    return (
                      <button
                        key={sort.id}
                        onClick={() => {
                          setSortBy(sort.id as SortType);
                          setPage(1);
                        }}
                        className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${
                          isActive
                            ? 'bg-brand-purple-600 text-white'
                            : 'bg-white dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-50 dark:hover:bg-neutral-700'
                        }`}
                      >
                        {sort.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Results Count */}
            {hasSearched && results.length > 0 && !loading && (
              <div className="mt-4 text-sm text-neutral-600 dark:text-neutral-400">
                <span className="font-medium text-neutral-900 dark:text-neutral-50">{total}</span>{' '}
                {total === 1 ? 'result' : 'results'}
              </div>
            )}
          </div>

          {/* Results Section */}
          {hasSearched && (
            <>
              {loading ? (
                <div className="flex flex-col items-center justify-center py-20">
                  <Loader2 className="w-8 h-8 animate-spin text-brand-purple-600 mb-4" />
                  <p className="text-sm text-neutral-600 dark:text-neutral-400">
                    Searching...
                  </p>
                </div>
              ) : results.length > 0 ? (
                <>
                  <div className="space-y-3">
                    {results.map((user) => (
                      <Card
                        key={user.id}
                        hoverable
                        className="cursor-pointer"
                        onClick={() => router.push(`/profile?u=${user.username}`)}
                      >
                        <div className="flex items-center gap-4">
                          {/* Avatar */}
                          <div className="flex-shrink-0">
                            <Avatar
                              src={user.profile_picture}
                              alt={user.display_name}
                              fallback={user.display_name}
                              size="md"
                            />
                          </div>

                          {/* User Info */}
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 mb-1">
                              <h3 className="font-semibold text-neutral-900 dark:text-neutral-50 truncate">
                                {user.display_name}
                              </h3>
                              {user.is_verified && (
                                <VerifiedBadge size="sm" />
                              )}
                            </div>
                            <p className="text-sm text-neutral-600 dark:text-neutral-400 mb-1">
                              @{user.username}
                            </p>
                            {user.bio && (
                              <p className="text-sm text-neutral-700 dark:text-neutral-300 line-clamp-2 mb-2">
                                {user.bio}
                              </p>
                            )}
                            <div className="flex items-center gap-4 text-xs text-neutral-500 dark:text-neutral-400">
                              {user.location && (
                                <div className="flex items-center gap-1">
                                  <MapPin className="w-3.5 h-3.5" />
                                  <span>{user.location}</span>
                                </div>
                              )}
                              {user.followers_count !== undefined && (
                                <div className="flex items-center gap-1">
                                  <Users className="w-3.5 h-3.5" />
                                  <span>{formatNumber(user.followers_count)} followers</span>
                                </div>
                              )}
                            </div>
                          </div>
                        </div>
                      </Card>
                    ))}
                  </div>

                  {/* Pagination */}
                  {total > 20 && (
                    <div className="mt-8 flex items-center justify-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPage((p) => Math.max(1, p - 1))}
                        disabled={page === 1 || loading}
                      >
                        Previous
                      </Button>
                      
                      <div className="flex items-center gap-1">
                        {Array.from({ length: Math.min(5, Math.ceil(total / 20)) }, (_, i) => {
                          const pageNum = i + 1;
                          const totalPages = Math.ceil(total / 20);
                          let displayPage: number | string = pageNum;
                          
                          if (totalPages > 5) {
                            if (page <= 3) {
                              displayPage = pageNum <= 4 ? pageNum : pageNum === 5 ? '...' : totalPages;
                            } else if (page >= totalPages - 2) {
                              displayPage = pageNum === 1 ? 1 : pageNum === 2 ? '...' : totalPages - 5 + pageNum;
                            } else {
                              if (pageNum === 1) displayPage = 1;
                              else if (pageNum === 2) displayPage = '...';
                              else if (pageNum === 3) displayPage = page - 1;
                              else if (pageNum === 4) displayPage = page;
                              else if (pageNum === 5) displayPage = page + 1;
                            }
                          }
                          
                          if (displayPage === '...') {
                            return (
                              <span key={i} className="px-2 text-neutral-400">
                                ...
                              </span>
                            );
                          }
                          
                          const isActive = Number(displayPage) === page;
                          return (
                            <Button
                              key={i}
                              variant={isActive ? 'primary' : 'ghost'}
                              size="sm"
                              onClick={() => setPage(Number(displayPage))}
                              disabled={loading}
                              className="min-w-[36px]"
                            >
                              {displayPage}
                            </Button>
                          );
                        })}
                      </div>

                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPage((p) => p + 1)}
                        disabled={page >= Math.ceil(total / 20) || loading}
                      >
                        Next
                      </Button>
                    </div>
                  )}
                </>
              ) : (
                <div className="text-center py-16">
                  <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-neutral-100 dark:bg-neutral-800 flex items-center justify-center">
                    <Search className="w-8 h-8 text-neutral-400" />
                  </div>
                  <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
                    No results found
                  </h3>
                  <p className="text-sm text-neutral-600 dark:text-neutral-400 mb-6">
                    Try adjusting your search terms or filters
                  </p>
                  <Button
                    variant="outline"
                    onClick={clearSearch}
                    size="sm"
                  >
                    Clear Search
                  </Button>
                </div>
              )}
            </>
          )}

          {/* Empty State */}
          {!hasSearched && !loading && (
            <div className="text-center py-16">
              <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-neutral-100 dark:bg-neutral-800 flex items-center justify-center">
                <Search className="w-8 h-8 text-neutral-400" />
              </div>
              <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
                Start searching
              </h3>
              <p className="text-sm text-neutral-600 dark:text-neutral-400 mb-6">
                Enter a name, username, or location to find people
              </p>
              
              {/* Recent Searches */}
              {recentSearches.length > 0 && (
                <div className="max-w-md mx-auto">
                  <p className="text-xs font-medium text-neutral-500 dark:text-neutral-400 mb-3 uppercase tracking-wide">
                    Recent Searches
                  </p>
                  <div className="flex flex-wrap items-center justify-center gap-2">
                    {recentSearches.map((search, idx) => (
                      <button
                        key={idx}
                        onClick={() => handleSearch(search)}
                        className="px-3 py-1.5 bg-neutral-100 dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-800 rounded-lg text-sm text-neutral-700 dark:text-neutral-300 hover:bg-neutral-200 dark:hover:bg-neutral-700 transition-colors"
                      >
                        {search}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </MainLayout>
  );
}
