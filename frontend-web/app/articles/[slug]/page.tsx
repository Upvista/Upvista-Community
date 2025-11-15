'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { Post, postsAPI } from '@/lib/api/posts';
import ArticleView from '@/components/posts/ArticleView';
import { Loader2 } from 'lucide-react';
import { MainLayout } from '@/components/layout/MainLayout';

export default function ArticlePage() {
  const params = useParams();
  const router = useRouter();
  const slug = params?.slug as string;
  
  const [post, setPost] = useState<Post | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!slug) return;

    const fetchArticle = async () => {
      try {
        setLoading(true);
        setError(null);
        
        // Try to fetch article by slug
        // First try the dedicated endpoint, fallback to getting all posts and finding by slug
        try {
          const response = await postsAPI.getArticleBySlug(slug);
          if (response.success && response.post) {
            setPost(response.post);
            return;
          }
        } catch (err: any) {
          // If endpoint doesn't exist (404), try fallback method
          if (err.message?.includes('404') || err.message?.includes('not found')) {
            // Fallback: Get posts and find by slug
            // This is a temporary workaround until backend endpoint is added
            console.log('Article endpoint not found, using fallback method');
            // For now, we'll show an error and suggest using post ID
            setError('Article endpoint not available. Please ensure backend has /api/v1/articles/:slug endpoint.');
            return;
          }
          throw err;
        }
      } catch (err: any) {
        console.error('Error fetching article:', err);
        // Fallback: try to get by post ID if slug is actually an ID
        if (err.message?.includes('404') || err.message?.includes('not found')) {
          setError('Article not found');
        } else {
          setError('Failed to load article. Please try again.');
        }
      } finally {
        setLoading(false);
      }
    };

    fetchArticle();
  }, [slug]);

  if (loading) {
    return (
      <MainLayout>
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <Loader2 className="w-8 h-8 animate-spin text-purple-600 mx-auto mb-4" />
            <p className="text-neutral-600 dark:text-neutral-400">Loading article...</p>
          </div>
        </div>
      </MainLayout>
    );
  }

  if (error || !post) {
    return (
      <MainLayout>
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center max-w-md">
            <h1 className="text-2xl font-bold text-neutral-900 dark:text-neutral-50 mb-2">
              Article Not Found
            </h1>
            <p className="text-neutral-600 dark:text-neutral-400 mb-6">
              {error || 'The article you\'re looking for doesn\'t exist or has been removed.'}
            </p>
            <button
              onClick={() => router.push('/home')}
              className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
            >
              Go to Home
            </button>
          </div>
        </div>
      </MainLayout>
    );
  }

  if (!post.article) {
    return (
      <MainLayout>
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <p className="text-neutral-600 dark:text-neutral-400">
              This post is not an article.
            </p>
          </div>
        </div>
      </MainLayout>
    );
  }

  const article = post.article;

  // Set SEO metadata dynamically
  useEffect(() => {
    if (!article) return;

    const siteUrl = window.location.origin;
    const articleUrl = `${siteUrl}/articles/${article.slug}`;
    const coverImage = article.cover_image_url || `${siteUrl}/assets/u.png`;
    const authorName = post.author?.display_name || post.author?.username || 'UpVista Author';
    const description = article.meta_description || article.subtitle || `${article.title} - Read on UpVista Community`;
    const title = article.meta_title || article.title;

    // Update document title
    document.title = `${title} | UpVista Community`;

    // Update or create meta tags
    const updateMetaTag = (name: string, content: string, isProperty = false) => {
      const attribute = isProperty ? 'property' : 'name';
      let element = document.querySelector(`meta[${attribute}="${name}"]`);
      if (!element) {
        element = document.createElement('meta');
        element.setAttribute(attribute, name);
        document.head.appendChild(element);
      }
      element.setAttribute('content', content);
    };

    // Basic meta tags
    updateMetaTag('description', description);
    updateMetaTag('author', authorName);

    // Open Graph tags
    updateMetaTag('og:type', 'article', true);
    updateMetaTag('og:title', title, true);
    updateMetaTag('og:description', description, true);
    updateMetaTag('og:url', articleUrl, true);
    updateMetaTag('og:image', coverImage, true);
    updateMetaTag('og:site_name', 'UpVista Community', true);
    updateMetaTag('article:published_time', post.created_at, true);
    updateMetaTag('article:modified_time', article.updated_at, true);
    updateMetaTag('article:author', authorName, true);
    if (article.category) {
      updateMetaTag('article:section', article.category, true);
    }

    // Twitter Card tags
    updateMetaTag('twitter:card', 'summary_large_image');
    updateMetaTag('twitter:title', title);
    updateMetaTag('twitter:description', description);
    updateMetaTag('twitter:image', coverImage);
    if (post.author?.username) {
      updateMetaTag('twitter:creator', `@${post.author.username}`);
    }

    // Canonical URL
    let canonicalLink = document.querySelector('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.setAttribute('rel', 'canonical');
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.setAttribute('href', articleUrl);

    // Structured data (JSON-LD)
    const structuredData = {
      '@context': 'https://schema.org',
      '@type': 'Article',
      headline: title,
      description: description,
      image: coverImage,
      datePublished: post.created_at,
      dateModified: article.updated_at,
      author: {
        '@type': 'Person',
        name: authorName,
        ...(post.author?.username && { url: `${siteUrl}/profile?u=${post.author.username}` }),
      },
      publisher: {
        '@type': 'Organization',
        name: 'UpVista Community',
        url: siteUrl,
      },
      mainEntityOfPage: {
        '@type': 'WebPage',
        '@id': articleUrl,
      },
      ...(article.category && { articleSection: article.category }),
      ...(article.tags && article.tags.length > 0 && { keywords: article.tags.join(', ') }),
    };

    // Remove existing structured data
    const existingScript = document.querySelector('script[type="application/ld+json"][data-article]');
    if (existingScript) {
      existingScript.remove();
    }

    // Add new structured data
    const script = document.createElement('script');
    script.type = 'application/ld+json';
    script.setAttribute('data-article', 'true');
    script.textContent = JSON.stringify(structuredData);
    document.head.appendChild(script);
  }, [article, post]);

  return (
    <MainLayout>
      <div className="min-h-screen bg-white dark:bg-gray-900">
        <ArticleView
          post={post}
          onComment={(post) => {
            // Handle comment - could open comment modal
          }}
          onShare={(post) => {
            // Handle share
            if (navigator.share) {
              navigator.share({
                title: post.article?.title || 'Article',
                text: post.article?.subtitle || '',
                url: window.location.href,
              });
            }
          }}
          onSave={async (post) => {
            try {
              if (post.is_saved) {
                await postsAPI.unsavePost(post.id);
                setPost({ ...post, is_saved: false });
              } else {
                await postsAPI.savePost(post.id);
                setPost({ ...post, is_saved: true });
              }
            } catch (error: any) {
              console.error('Failed to save article:', error);
            }
          }}
        />
      </div>
    </MainLayout>
  );
}

