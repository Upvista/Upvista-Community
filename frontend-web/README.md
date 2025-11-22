# Upvista Community - Frontend Web Application

**Version:** 1.0.0  
**Created by:** Hamza Hafeez, Founder & CEO  
**Technology Stack:** Next.js 16, React 19, TypeScript, Tailwind CSS  
**Last Updated:** November 2025

---

## Executive Summary

Upvista Community is a comprehensive social networking platform designed to facilitate professional connections, content sharing, and real-time collaboration. This frontend web application represents the client-side implementation of the Upvista ecosystem, built with modern web technologies to deliver a responsive, performant, and user-centric experience across desktop and mobile devices.

The application implements a hybrid social platform model, combining the engagement features of contemporary social networks with the professional networking capabilities of business-oriented platforms. Built using Next.js 16 with React 19 and TypeScript, the frontend delivers server-side rendering capabilities, optimized performance, and enterprise-grade scalability.

**Strategic Position:** This frontend application serves as the primary user interface for the Upvista Community platform, enabling users to create profiles, share content, connect with peers, engage in real-time messaging, and participate in community-driven activities.

---

## Project Overview

### Purpose and Scope

The Upvista Community frontend web application provides a complete user interface layer for social networking functionality, including but not limited to:

- User authentication and profile management
- Content creation and consumption (posts, articles, polls)
- Real-time messaging and communication
- Social connections and relationship management
- Community engagement and discovery
- Notification and activity tracking
- Settings and account configuration

### Target Platform

- **Primary:** Modern web browsers (Chrome, Firefox, Safari, Edge)
- **Responsive Design:** Mobile, tablet, and desktop viewports
- **Progressive Web Application:** PWA capabilities for mobile-like experience
- **Accessibility:** WCAG 2.1 Level AA compliance

### Business Objectives

The application supports the strategic goals of Upvista Community by providing:

1. **User Acquisition:** Intuitive onboarding and registration flow
2. **Engagement:** Rich content creation tools and social interaction features
3. **Retention:** Real-time notifications, personalized feeds, and community features
4. **Professional Networking:** Profile management, experience tracking, and professional discovery
5. **Scalability:** Architecture designed to support growth from thousands to millions of users

---

## Architecture and Technology Stack

### Core Framework

**Next.js 16.0.0**
- Server-side rendering (SSR) and static site generation (SSG)
- App Router architecture for modern routing patterns
- API routes for proxy and middleware functionality
- Image optimization and performance enhancements
- Automatic code splitting and lazy loading

**React 19.2.0**
- Latest React features including concurrent rendering
- Server Components and Client Components architecture
- Suspense boundaries for improved loading states
- Hooks-based state management

**TypeScript 5.x**
- Strict type checking for enhanced code quality
- Type safety across the entire application
- Improved developer experience and maintainability
- Integration with Next.js and React for full type coverage

### Styling and Design

**Tailwind CSS 4.0**
- Utility-first CSS framework
- Custom design system tokens
- Responsive design utilities
- Dark mode support
- Custom plugin system

**Design Philosophy:**
- iOS-inspired minimal professional aesthetic
- Glassmorphism effects for depth and hierarchy
- Consistent 4px spacing system
- Vibrant purple branding (#A855F7)
- Professional typography system

### State Management

**Zustand 5.0.8**
- Lightweight state management solution
- Client-side state for theme, user preferences
- Minimal boilerplate with TypeScript support

**React Context API**
- Theme context for global theme management
- Message context for real-time messaging state
- Notification context for activity tracking

### Rich Text Editing

**TipTap 3.10.3**
- Extensible rich text editor framework
- Support for headings, lists, code blocks, links, mentions
- Custom extensions for article composition
- Syntax highlighting with Lowlight
- Mention autocomplete capabilities

### Media Processing

**FFmpeg 0.12.15**
- Client-side video processing
- Audio format conversion
- Media compression and optimization

**Browser Image Compression 2.0.2**
- Image optimization before upload
- Quality adjustment and file size reduction
- Client-side processing for improved performance

### Additional Libraries

**Framer Motion 12.23.24**
- Animation library for smooth transitions
- Gesture handling and interaction animations
- Performance-optimized animations

**Date-fns 4.1.0**
- Date manipulation and formatting
- Relative time calculations
- Internationalization support

**IndexedDB (idb 8.0.3)**
- Client-side data persistence
- Offline data storage
- Cache management

---

## Features and Capabilities

### Authentication and User Management

**Registration and Login**
- Email and password authentication
- Social OAuth integration (Google, GitHub, LinkedIn)
- Email verification with 6-digit codes
- Password reset flow with token-based security
- Session management and multi-device support

**Profile Management**
- Comprehensive profile creation and editing
- Profile picture upload with image optimization
- Display name, bio, and tagline configuration
- Experience and education tracking
- Profile visibility and privacy controls
- Username management with change restrictions
- Email change with verification workflow

**Account Settings**
- Password change functionality
- Active session monitoring and management
- Device-based session termination
- Account deactivation and permanent deletion
- GDPR-compliant data export
- Notification preferences configuration
- Theme and appearance customization
- Language and timezone settings

### Content Creation and Management

**Post Types**
- **Text Posts:** Character-limited text content with hashtag and mention support
- **Polls:** Interactive voting with real-time results and duration settings
- **Articles:** Rich text articles with formatting, code blocks, and media embedding
- **Media Posts:** Image and video content with grid layouts and optimization

**Content Features**
- Hashtag extraction and trending tracking
- User mentions with notification integration
- Content categories and tagging
- Draft saving and auto-save functionality
- Content editing and deletion
- Post scheduling capabilities

**Media Handling**
- Image upload with compression and optimization
- Video upload with format conversion
- Audio file support with player integration
- File upload with progress tracking
- Media grid display for multiple items
- Image cropping and editing tools

### Social Interaction

**Feed System**
- Personalized home feed
- Following-based feed
- Explore feed for content discovery
- Saved posts collection
- Infinite scroll implementation
- Real-time feed updates via WebSocket

**Engagement Features**
- Like and unlike posts
- Comment system with nested replies (2 levels)
- Share functionality with multiple destinations
- Save posts to collections
- Report inappropriate content
- Content visibility controls

**Social Connections**
- Follow and unfollow users
- Follower and following management
- Relationship status tracking
- Connection requests system
- User discovery and search
- Profile viewing and interaction

### Messaging System

**Real-time Communication**
- Direct messaging between users
- WebSocket-based real-time delivery
- Typing indicators
- Read receipts and message status
- Online/offline presence indicators
- Unread message tracking

**Message Types**
- Text messages with rich formatting
- Image messages with compression
- Video messages with quality options
- Audio messages with player integration
- File attachments
- Link previews

**Advanced Messaging Features**
- Message editing with history
- Message deletion and recall
- Message forwarding
- Pinned messages
- Starred messages
- Message search functionality
- Reaction support (emojis)
- Media viewer for images and videos

### Notification System

**Notification Types**
- Post likes and comments
- Follow requests and acceptances
- Message notifications
- Mention notifications
- Hashtag activity notifications
- Community updates

**Notification Management**
- Real-time notification delivery
- Category-based notification filtering
- Notification preferences per category
- Notification history and archive
- Mark as read functionality
- Batch notification actions

### Search and Discovery

**Search Capabilities**
- User search with filters
- Post and article search
- Hashtag search and trending
- Advanced search filters
- Search history and suggestions
- Saved search queries

**Discovery Features**
- Trending topics
- Suggested communities
- Recommended users
- Popular content discovery
- Hashtag exploration
- Category-based browsing

### Community Features

**Community Management**
- Community creation and configuration
- Member management and roles
- Community settings and moderation
- Community feed and content
- Community discovery
- Join and leave functionality

### Layout and Navigation

**Responsive Design**
- Desktop sidebar navigation (10+ items)
- Mobile top bar with action icons
- Mobile bottom navigation bar
- Adaptive layout based on viewport
- Touch gesture support
- Swipe navigation patterns

**Navigation Structure**
- Home feed
- Communities discovery
- Content creation
- Explore content
- Messages and conversations
- Notifications center
- User profile
- Settings and configuration

---

## Design System

### Color Palette

**Primary Brand Colors**
- Purple (#A855F7): Primary brand color derived from logo
- Deep Purple (#9333EA): Active states and accents
- Secondary Purple (#8B5CF6): Alternative accents

**Semantic Colors**
- Success Green (#10B981): Success states and confirmations
- Error Red (#EF4444): Error states and warnings
- Warning Amber (#F59E0B): Warning messages
- Info Blue (#3B82F6): Informational content

**Neutral Palette**
- Light Mode: White backgrounds (#FFFFFF, #FAFAFA, #F5F5F5)
- Dark Mode: Black backgrounds (#0A0A0A, #171717, #1A1A1A)
- Text Colors: Full gray scale (50-950) for hierarchy
- Border Colors: Subtle grays for separation

### Typography

**Font System**
- Base Font Size: 15px (iOS standard)
- Font Family: SF Pro Display fallback stack
- Line Height: 1.4 (tight, iOS-like)
- Font Weights: 400 (regular), 500 (medium), 600 (semibold), 700 (bold)

**Heading Hierarchy**
- H1: 36px, Bold
- H2: 32px, Bold
- H3: 24px, Semibold
- H4: 20px, Semibold
- H5: 18px, Medium
- Body: 15px, Regular
- Caption: 13px, Regular

### Spacing System

**Base Unit: 4px**
- Consistent spacing multiples (4, 8, 12, 16, 20, 24, 32, 40, 48, 64)
- Padding: 16px, 20px, 24px standard
- Margins: 16px, 24px, 32px common
- Gaps: 8px, 12px, 16px for flex/grid layouts

### Component Patterns

**Glassmorphism**
- Backdrop blur effects (backdrop-blur-xl)
- Semi-transparent backgrounds
- Layered depth perception
- Modern visual hierarchy

**Card Components**
- Glass variant: Transparent with blur
- Solid variant: Opaque backgrounds
- Hover states: Subtle elevation
- Consistent border radius: 12px-16px

**Button Variants**
- Primary: Solid purple background
- Secondary: Outlined with purple border
- Ghost: Transparent with hover state
- Danger: Red for destructive actions

### Responsive Breakpoints

- Mobile: < 640px
- Tablet: 640px - 1024px
- Desktop: > 1024px
- Large Desktop: > 1280px

### Dark Mode Support

- System preference detection
- Manual theme switching
- Persistent theme preference
- Smooth theme transitions
- Consistent color adaptation

---

## Project Structure

```
frontend-web/
├── app/                          # Next.js App Router
│   ├── (main)/                   # Protected routes (authentication required)
│   │   ├── home/                 # Home feed page
│   │   ├── profile/              # User profile pages
│   │   ├── settings/             # Account settings page
│   │   ├── search/               # Search and discovery
│   │   ├── communities/          # Community pages
│   │   ├── explore/              # Content exploration
│   │   ├── messages/             # Messaging interface
│   │   ├── notifications/        # Notifications center
│   │   ├── create/               # Content creation
│   │   ├── collaborate/          # Collaboration features
│   │   ├── jobs/                 # Job board
│   │   ├── saved/                # Saved content
│   │   ├── activity/             # User activity tracking
│   │   ├── posts/[id]/           # Individual post pages
│   │   ├── articles/[slug]/      # Article reader pages
│   │   └── layout.tsx            # Main application layout
│   ├── auth/                     # Authentication routes
│   │   ├── page.tsx              # Login and registration
│   │   ├── verify-email/         # Email verification
│   │   ├── forgot-password/      # Password reset request
│   │   ├── reset-password/       # Password reset
│   │   └── callback/             # OAuth callback handler
│   ├── api/                      # API routes
│   │   ├── proxy/[...path]/      # Backend API proxy
│   │   └── test/                 # API testing endpoints
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Root redirect page
│   └── globals.css               # Global styles and design tokens
├── components/                   # React components
│   ├── layout/                   # Layout components
│   │   ├── Sidebar.tsx           # Desktop sidebar navigation
│   │   ├── Topbar.tsx            # Mobile top bar
│   │   ├── BottomNav.tsx         # Mobile bottom navigation
│   │   └── MainLayout.tsx        # Responsive layout wrapper
│   ├── ui/                       # Reusable UI components
│   │   ├── Button.tsx            # Button component
│   │   ├── Card.tsx              # Card component
│   │   ├── Avatar.tsx            # Avatar component
│   │   ├── Badge.tsx             # Badge component
│   │   ├── Input.tsx             # Input component
│   │   ├── IconButton.tsx        # Icon button component
│   │   ├── Modal.tsx             # Modal dialog
│   │   ├── Toast.tsx             # Toast notifications
│   │   └── SkeletonLoader.tsx    # Loading skeletons
│   ├── posts/                    # Post-related components
│   │   ├── PostCard.tsx          # Post display card
│   │   ├── PostComposer.tsx      # Post creation interface
│   │   ├── PostDetailView.tsx    # Post detail page
│   │   ├── CommentSection.tsx    # Comment system
│   │   ├── MediaGrid.tsx         # Media display grid
│   │   ├── ArticleView.tsx       # Article reader
│   │   └── ShareDialog.tsx       # Share functionality
│   ├── messages/                 # Messaging components
│   │   ├── ChatWindow.tsx        # Main chat interface
│   │   ├── ConversationList.tsx  # Conversation list
│   │   ├── MessageBubble.tsx     # Message display
│   │   └── MediaViewer.tsx       # Media viewer
│   ├── notifications/            # Notification components
│   │   ├── NotificationBell.tsx  # Notification indicator
│   │   └── NotificationItem.tsx  # Notification display
│   ├── profile/                  # Profile components
│   │   ├── ProfileStats.tsx      # User statistics
│   │   └── RelationshipButton.tsx # Follow/unfollow button
│   ├── settings/                 # Settings components
│   │   ├── NotificationSettings.tsx
│   │   └── StatVisibilitySettings.tsx
│   └── pwa/                      # PWA components
│       ├── PWAWrapper.tsx        # PWA configuration
│       └── InstallPrompt.tsx     # Installation prompt
├── lib/                          # Utilities and helpers
│   ├── api/                      # API client functions
│   │   ├── api.ts                # Base API configuration
│   │   ├── posts.ts              # Post API functions
│   │   ├── messages.ts           # Message API functions
│   │   ├── notifications.ts      # Notification API functions
│   │   └── media.ts              # Media API functions
│   ├── contexts/                 # React contexts
│   │   ├── ThemeContext.tsx      # Theme management
│   │   ├── MessagesContext.tsx   # Message state management
│   │   └── NotificationContext.tsx # Notification state
│   ├── hooks/                    # Custom React hooks
│   │   ├── useUser.ts            # User data hook
│   │   ├── useUnreadMessages.ts  # Unread message tracking
│   │   └── useMediaUpload.ts     # Media upload hook
│   ├── utils/                    # Utility functions
│   │   ├── formatNumber.ts       # Number formatting
│   │   ├── formatDate.ts         # Date formatting
│   │   └── validation.ts         # Input validation
│   ├── websocket/                # WebSocket utilities
│   │   ├── client.ts             # WebSocket client
│   │   └── handlers.ts           # Message handlers
│   └── utils.ts                  # Common utilities
├── public/                       # Static assets
│   ├── assets/                   # Application assets
│   │   ├── u.png                 # Brand logo
│   │   └── auth/                 # OAuth provider icons
│   ├── PWA-icons/                # PWA icon set
│   ├── manifest.json             # PWA manifest
│   ├── robots.txt                # SEO robots file
│   └── sw.js                     # Service worker
├── docs/                         # Documentation
│   ├── FRONTEND_DESIGN.md        # Design specification
│   ├── IMPLEMENTATION_SUMMARY.md # Implementation details
│   └── MOBILE_SIZING_IMPROVEMENTS.md
├── package.json                  # Dependencies and scripts
├── tsconfig.json                 # TypeScript configuration
├── tailwind.config.ts            # Tailwind CSS configuration
├── next.config.ts                # Next.js configuration
└── README.md                     # This file
```

---

## Development Setup

### Prerequisites

- **Node.js:** Version 20.x or higher
- **npm:** Version 9.x or higher (or yarn/pnpm equivalent)
- **Backend API:** Upvista Community backend running on `http://localhost:8081`
- **Modern Browser:** Chrome, Firefox, Safari, or Edge (latest versions)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd frontend-web
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   Create a `.env.local` file in the root directory:
   ```env
   NEXT_PUBLIC_API_BASE_URL=http://localhost:8081
   NEXT_PUBLIC_WS_URL=ws://localhost:8081/ws
   ```

4. **Start development server**
   ```bash
   npm run dev
   ```

5. **Access the application**
   Open `http://localhost:3000` in your browser

### Available Scripts

- **`npm run dev`**: Start development server with hot reload
- **`npm run build`**: Build production-optimized application
- **`npm run start`**: Start production server (requires build first)
- **`npm run lint`**: Run ESLint for code quality checks

### Development Guidelines

**Code Standards**
- TypeScript strict mode enabled
- ESLint configuration for code consistency
- Component-based architecture
- Separation of concerns (UI, logic, data)
- Reusable component library

**Best Practices**
- Use TypeScript for all new files
- Follow Next.js App Router patterns
- Implement proper error boundaries
- Optimize images using Next.js Image component
- Implement loading states for async operations
- Provide accessibility attributes (ARIA labels)
- Test responsive design across breakpoints

---

## Backend Integration

### API Configuration

The frontend communicates with the backend API through a proxy route (`/api/proxy`) to handle CORS and authentication. The proxy forwards requests to the backend API running on `http://localhost:8081/api/v1`.

**Base API URL:** `http://localhost:8081/api/v1`

### Authentication Flow

1. User registration via `/auth/register`
2. Email verification with 6-digit code
3. Login via `/auth/login` to receive JWT token
4. Token stored in localStorage
5. Token included in Authorization header for protected routes
6. Token refresh via `/auth/refresh` when expired

### WebSocket Integration

Real-time features utilize WebSocket connections:
- **Connection URL:** `ws://localhost:8081/ws`
- **Message Delivery:** Real-time message notifications
- **Presence Status:** Online/offline user status
- **Feed Updates:** Live post engagement updates
- **Typing Indicators:** Real-time typing status

### API Endpoints Utilized

**Authentication**
- POST `/auth/register` - User registration
- POST `/auth/login` - User login
- POST `/auth/verify-email` - Email verification
- POST `/auth/forgot-password` - Password reset request
- POST `/auth/reset-password` - Password reset
- POST `/auth/logout` - User logout
- GET `/auth/me` - Current user information

**Account Management**
- GET `/account/profile` - Get user profile
- PATCH `/account/profile` - Update profile
- POST `/account/profile-picture` - Upload profile picture
- POST `/account/change-password` - Change password
- POST `/account/change-email` - Change email
- POST `/account/change-username` - Change username
- GET `/account/sessions` - View active sessions
- DELETE `/account/sessions/:id` - Revoke session
- GET `/account/export-data` - Export user data
- POST `/account/deactivate` - Deactivate account
- DELETE `/account/delete` - Delete account

**Content and Social**
- GET `/posts` - Retrieve posts feed
- POST `/posts` - Create new post
- GET `/posts/:id` - Get post details
- POST `/posts/:id/like` - Like post
- POST `/posts/:id/comments` - Add comment
- GET `/users/:id` - Get user profile
- POST `/users/:id/follow` - Follow user
- POST `/users/:id/unfollow` - Unfollow user

**Messaging**
- GET `/messages/conversations` - List conversations
- GET `/messages/conversations/:id` - Get conversation
- POST `/messages` - Send message
- PATCH `/messages/:id` - Edit message
- DELETE `/messages/:id` - Delete message

---

## Performance Optimization

### Server-Side Rendering

Next.js App Router provides automatic server-side rendering for improved initial load performance and SEO optimization.

### Image Optimization

- Next.js Image component with automatic optimization
- Lazy loading for below-fold images
- Responsive image sizes
- WebP format support with fallbacks

### Code Splitting

- Automatic code splitting at the route level
- Dynamic imports for heavy components
- Lazy loading for non-critical features
- Tree shaking for unused code elimination

### Caching Strategy

- Static page generation for public content
- Incremental Static Regeneration (ISR) for dynamic content
- Client-side caching with IndexedDB
- Service worker for offline functionality

### Performance Metrics

Target performance metrics:
- First Contentful Paint: < 1.5s
- Largest Contentful Paint: < 2.5s
- Time to Interactive: < 3.5s
- Cumulative Layout Shift: < 0.1

---

## Progressive Web Application

### PWA Features

- **Installable:** Add to home screen functionality
- **Offline Support:** Service worker for offline functionality
- **Push Notifications:** Browser notification support
- **App-like Experience:** Full-screen mode and navigation patterns

### Service Worker

Custom service worker (`public/sw.js`) handles:
- Asset caching for offline access
- Background sync for offline actions
- Push notification handling
- Update prompts for new versions

---

## Browser Compatibility

### Supported Browsers

**Desktop**
- Chrome 120+
- Firefox 120+
- Safari 17+
- Edge 120+

**Mobile**
- Chrome Mobile 120+
- Safari iOS 17+
- Samsung Internet 23+

### Required Features

- ES2022 JavaScript support
- CSS Grid and Flexbox
- WebSocket API
- Fetch API
- IndexedDB
- Service Workers
- Web Push Notifications

---

## Security Considerations

### Authentication Security

- JWT tokens stored in localStorage
- Token expiration and refresh mechanisms
- Secure password requirements enforcement
- Session management and device tracking

### Input Validation

- Client-side validation for user input
- Server-side validation enforcement
- XSS protection through React's built-in escaping
- CSRF protection via same-origin policy

### Data Protection

- HTTPS enforcement in production
- Secure API communication
- Sensitive data encryption
- GDPR compliance features

---

## Deployment

### Production Build

```bash
npm run build
npm run start
```

### Environment Variables

Required production environment variables:
- `NEXT_PUBLIC_API_BASE_URL`: Backend API URL
- `NEXT_PUBLIC_WS_URL`: WebSocket connection URL

### Deployment Platforms

Compatible with:
- Vercel (recommended for Next.js)
- Netlify
- AWS Amplify
- Self-hosted Node.js server
- Docker containers

### Build Optimization

- Automatic code minification
- Asset optimization and compression
- Route-based code splitting
- Image optimization pipeline
- CSS optimization and purging

---

## Testing

### Manual Testing Checklist

- Authentication flow (registration, login, logout)
- Profile management operations
- Content creation (posts, articles, polls)
- Social interactions (follow, like, comment, share)
- Messaging functionality
- Notification delivery
- Settings configuration
- Responsive design across devices
- Dark mode functionality
- PWA installation and offline mode

### Browser Testing

Test across supported browsers for:
- Feature functionality
- Visual consistency
- Performance metrics
- Accessibility compliance

---

## Documentation

### Additional Documentation

- **Design Specification:** `docs/FRONTEND_DESIGN.md`
  - Complete design system documentation
  - Component specifications
  - Layout patterns and responsive behavior

- **Implementation Summary:** `docs/IMPLEMENTATION_SUMMARY.md`
  - Feature implementation status
  - Component inventory
  - Integration details

### Code Documentation

- Inline comments for complex logic
- TypeScript interfaces for type documentation
- JSDoc comments for public functions
- Component prop documentation

---

## Maintenance and Support

### Version Management

- Semantic versioning (MAJOR.MINOR.PATCH)
- Changelog tracking for updates
- Breaking change documentation
- Migration guides for major updates

### Bug Reporting

Report issues through:
- Repository issue tracker
- Internal bug tracking system
- User feedback channels

### Feature Requests

Feature requests should include:
- Use case description
- Expected behavior
- Proposed implementation approach
- Priority justification

---

## Credits and Leadership

**Project Founder and CEO:** Hamza Hafeez

This application represents a comprehensive implementation of modern web development practices, designed to serve as the primary interface for the Upvista Community platform. The architecture emphasizes scalability, performance, and user experience while maintaining code quality and maintainability standards appropriate for enterprise-level applications.

**Development Philosophy:** The application is built with a focus on professional-grade implementation, emphasizing code quality, type safety, performance optimization, and user-centric design. All technical decisions prioritize long-term maintainability and scalability.

---

## License

This project is proprietary software developed for Upvista Community. All rights reserved.

---

**Last Updated:** November 2025  
**Document Version:** 1.0.0  
**Maintained by:** Upvista Development Team
