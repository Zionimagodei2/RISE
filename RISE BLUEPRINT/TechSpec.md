# REALGLOBAL — Technical Specification

## 1. Tech Stack Overview

| Category | Technology |
|----------|------------|
| Framework | Next.js 14 (App Router) |
| Language | TypeScript |
| Styling | Tailwind CSS |
| UI Components | shadcn/ui |
| Animation | Framer Motion |
| State Management | Zustand |
| Data Fetching | React Query (TanStack Query) |
| Maps | Mapbox GL JS |
| Charts | Recharts |
| Forms | React Hook Form + Zod |
| Icons | Lucide React |
| Date Handling | date-fns |
| Currency | Intl.NumberFormat |

## 2. Tailwind Configuration

```javascript
// tailwind.config.ts extensions
{
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#EFF6FF',
          100: '#DBEAFE',
          200: '#BFDBFE',
          300: '#93C5FD',
          400: '#60A5FA',
          500: '#3B82F6',
          600: '#2563EB',
          700: '#1D4ED8',
          800: '#1E40AF',
          900: '#1E3A8A',
          DEFAULT: '#0B61FF',
        },
        accent: {
          DEFAULT: '#00B37E',
          light: '#D1FAE5',
          dark: '#059669',
        },
        neutral: {
          50: '#F8FAFC',
          100: '#F1F5F9',
          200: '#E2E8F0',
          300: '#CBD5E1',
          400: '#94A3B8',
          500: '#64748B',
          600: '#475569',
          700: '#334155',
          800: '#1E293B',
          900: '#0F1724',
        },
        error: {
          DEFAULT: '#DC2626',
          light: '#FEE2E2',
        },
        warning: {
          DEFAULT: '#F59E0B',
          light: '#FEF3C7',
        },
        info: {
          DEFAULT: '#06B6D4',
          light: '#CFFAFE',
        },
      },
      fontFamily: {
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
      },
      fontSize: {
        'display': ['48px', { lineHeight: '1.1', letterSpacing: '-0.02em', fontWeight: '800' }],
        'h1': ['36px', { lineHeight: '1.2', letterSpacing: '-0.01em', fontWeight: '700' }],
        'h2': ['28px', { lineHeight: '1.25', letterSpacing: '-0.01em', fontWeight: '700' }],
        'h3': ['22px', { lineHeight: '1.3', fontWeight: '600' }],
        'h4': ['18px', { lineHeight: '1.4', fontWeight: '600' }],
        'h5': ['16px', { lineHeight: '1.4', fontWeight: '600' }],
        'h6': ['14px', { lineHeight: '1.4', letterSpacing: '0.01em', fontWeight: '600' }],
        'body-lg': ['18px', { lineHeight: '1.6', fontWeight: '400' }],
        'body': ['16px', { lineHeight: '1.6', fontWeight: '400' }],
        'body-sm': ['14px', { lineHeight: '1.5', fontWeight: '400' }],
        'caption': ['12px', { lineHeight: '1.4', letterSpacing: '0.01em', fontWeight: '500' }],
        'overline': ['11px', { lineHeight: '1.2', letterSpacing: '0.08em', fontWeight: '600' }],
      },
      spacing: {
        '18': '4.5rem',
        '22': '5.5rem',
      },
      borderRadius: {
        'xl': '12px',
        '2xl': '16px',
        '3xl': '24px',
      },
      boxShadow: {
        'card': '0 1px 3px rgba(0,0,0,0.1)',
        'card-hover': '0 4px 12px rgba(0,0,0,0.1)',
        'dropdown': '0 10px 40px rgba(0,0,0,0.15)',
        'modal': '0 25px 50px rgba(0,0,0,0.2)',
      },
      transitionTimingFunction: {
        'bounce': 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
      },
      keyframes: {
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        slideInRight: {
          '0%': { opacity: '0', transform: 'translateX(100%)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
      },
      animation: {
        shimmer: 'shimmer 1.5s infinite',
        fadeIn: 'fadeIn 0.3s ease-out',
        slideUp: 'slideUp 0.4s ease-out',
        slideInRight: 'slideInRight 0.3s ease-out',
      },
    },
  },
}
```

## 3. Component Inventory

### 3.1 shadcn/ui Components (Built-in)

| Component | Installation | Customization Notes |
|-----------|--------------|---------------------|
| Button | `npx shadcn add button` | Add accent, ghost variants |
| Card | `npx shadcn add card` | Default 12px radius |
| Input | `npx shadcn add input` | 48px height, 8px radius |
| Select | `npx shadcn add select` | Match input styling |
| Dialog | `npx shadcn add dialog` | Scale + fade animation |
| Dropdown | `npx shadcn add dropdown-menu` | 12px radius |
| Tabs | `npx shadcn add tabs` | Underline style |
| Badge | `npx shadcn add badge` | Pill shape |
| Avatar | `npx shadcn add avatar` | 3 sizes |
| Skeleton | `npx shadcn add skeleton` | Shimmer effect |
| Toast | `npx shadcn add toast` | Slide from right |
| Tooltip | `npx shadcn add tooltip` | 200ms delay |
| Popover | `npx shadcn add popover` | 12px radius |
| Sheet | `npx shadcn add sheet` | Slide from bottom/right |
| Accordion | `npx shadcn add accordion` | Smooth expand |
| Slider | `npx shadcn add slider` | Price range styling |
| Switch | `npx shadcn add switch` | Accent color |
| Checkbox | `npx shadcn add checkbox` | Rounded square |
| Radio | `npx shadcn add radio-group` | Circle style |
| Separator | `npx shadcn add separator` | 1px neutral-200 |
| ScrollArea | `npx shadcn add scroll-area` | Custom scrollbar |
| Table | `npx shadcn add table` | Striped rows |
| Calendar | `npx shadcn add calendar` | Date picker |
| Command | `npx shadcn add command` | Search palette |

### 3.2 Custom Components

| Component | Purpose | Props |
|-----------|---------|-------|
| PropertyCard | Property listing display | property, variant, onSave, onClick |
| PropertyGrid | Grid of property cards | properties, loading, emptyState |
| SearchBar | Main search input | value, onChange, onSearch, filters |
| FilterPanel | Search filters | filters, onChange, onReset |
| ImageGallery | Property images | images, onExpand |
| PriceDisplay | Formatted price | price, currency, prefix, suffix |
| AttributePills | Property attributes | beds, baths, sqft, className |
| AgentCard | Agent info display | agent, variant, onContact |
| MapView | Interactive map | properties, center, zoom, onMarkerClick |
| RatingStars | Star rating display | rating, count, size |
| BadgeGroup | Multiple badges | badges, max |
| EmptyState | Empty content state | icon, title, description, action |
| LoadingState | Loading spinner | size, text |
| ErrorState | Error display | error, onRetry |
| StatCard | Dashboard stat | label, value, change, icon |
| ChartCard | Chart container | title, children, period |
| DataTable | Sortable table | data, columns, onSort |
| FormField | Form input wrapper | label, error, children |
| StepWizard | Multi-step form | steps, current, onChange |
| NotificationItem | Notification card | notification, onRead, onDismiss |
| MessageThread | Chat thread | messages, onSend |
| MortgageCalculator | Calc widget | type, onCalculate |

## 4. Animation Implementation Plan

| Interaction | Tech | Implementation |
|-------------|------|----------------|
| Page load fade | Framer Motion | `initial={{ opacity: 0 }} animate={{ opacity: 1 }}` |
| Scroll reveal | Framer Motion | `whileInView` with `viewport={{ once: true }}` |
| Stagger children | Framer Motion | `staggerChildren: 0.1` in parent variants |
| Card hover lift | Tailwind + FM | `whileHover={{ y: -4 }}` + shadow transition |
| Button press | Framer Motion | `whileTap={{ scale: 0.98 }}` |
| Modal open | Framer Motion | `AnimatePresence` + scale/fade |
| Sheet slide | Framer Motion | `x` or `y` animation with spring |
| Toast enter | Framer Motion | Slide from right + fade |
| Toast exit | Framer Motion | `exit` prop with slide out |
| Skeleton shimmer | CSS | `animate-shimmer` with gradient |
| Number count | Custom hook | `useCountUp` with RAF |
| Image gallery | Framer Motion | `AnimatePresence` for image swap |
| Map pin bounce | CSS | `animate-bounce` on hover |
| Tab underline | Framer Motion | `layoutId` for shared layout |
| Accordion | Framer Motion | `AnimatePresence` + height animation |
| Dropdown | Framer Motion | Scale + opacity from top |

### Animation Variants

```typescript
// Fade up variant
const fadeUpVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { 
    opacity: 1, 
    y: 0,
    transition: { duration: 0.4, ease: [0.4, 0, 0.2, 1] }
  }
};

// Stagger container
const staggerContainer = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.1 }
  }
};

// Scale fade (for modals)
const scaleFadeVariants = {
  hidden: { opacity: 0, scale: 0.95 },
  visible: { 
    opacity: 1, 
    scale: 1,
    transition: { duration: 0.3, ease: [0.4, 0, 0.2, 1] }
  },
  exit: { 
    opacity: 0, 
    scale: 0.95,
    transition: { duration: 0.2 }
  }
};

// Slide from right (for toasts)
const slideRightVariants = {
  hidden: { opacity: 0, x: 100 },
  visible: { 
    opacity: 1, 
    x: 0,
    transition: { duration: 0.3, ease: [0.4, 0, 0.2, 1] }
  },
  exit: { 
    opacity: 0, 
    x: 100,
    transition: { duration: 0.2 }
  }
};
```

## 5. Project File Structure

```
my-app/
├── app/                          # Next.js App Router
│   ├── page.tsx                  # Home page
│   ├── layout.tsx                # Root layout
│   ├── globals.css               # Global styles
│   ├── search/
│   │   └── page.tsx              # Search page
│   ├── property/
│   │   └── [id]/
│   │       └── page.tsx          # Property detail
│   ├── agent/
│   │   └── [id]/
│   │       └── page.tsx          # Agent profile
│   ├── dashboard/
│   │   └── page.tsx              # User dashboard
│   ├── mortgage/
│   │   └── page.tsx              # Mortgage hub
│   ├── landlord/
│   │   └── page.tsx              # Landlord console
│   ├── developer/
│   │   └── page.tsx              # Developer portal
│   ├── admin/
│   │   └── page.tsx              # Admin console
│   └── auth/
│       └── page.tsx              # Authentication
├── components/
│   ├── ui/                       # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── input.tsx
│   │   └── ...
│   ├── layout/                   # Layout components
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   ├── Sidebar.tsx
│   │   └── Navigation.tsx
│   ├── property/                 # Property components
│   │   ├── PropertyCard.tsx
│   │   ├── PropertyGrid.tsx
│   │   ├── PropertyGallery.tsx
│   │   ├── PriceDisplay.tsx
│   │   └── AttributePills.tsx
│   ├── search/                   # Search components
│   │   ├── SearchBar.tsx
│   │   ├── FilterPanel.tsx
│   │   └── MapView.tsx
│   ├── dashboard/                # Dashboard components
│   │   ├── StatCard.tsx
│   │   ├── ChartCard.tsx
│   │   └── DataTable.tsx
│   ├── mortgage/                 # Mortgage components
│   │   ├── MortgageCalculator.tsx
│   │   ├── LenderCard.tsx
│   │   └── RateComparison.tsx
│   ├── admin/                    # Admin components
│   │   ├── ModerationQueue.tsx
│   │   ├── UserTable.tsx
│   │   └── AnalyticsDashboard.tsx
│   └── shared/                   # Shared components
│       ├── EmptyState.tsx
│       ├── LoadingState.tsx
│       ├── ErrorState.tsx
│       ├── RatingStars.tsx
│       ├── BadgeGroup.tsx
│       ├── AgentCard.tsx
│       ├── NotificationItem.tsx
│       └── MessageThread.tsx
├── hooks/                        # Custom hooks
│   ├── useAuth.ts
│   ├── useProperties.ts
│   ├── useSearch.ts
│   ├── useFavorites.ts
│   ├── useNotifications.ts
│   ├── useCountUp.ts
│   └── useMediaQuery.ts
├── lib/                          # Utilities
│   ├── utils.ts                  # General utilities
│   ├── api.ts                    # API client
│   ├── constants.ts              # Constants
│   ├── formatters.ts             # Formatting utils
│   └── validators.ts             # Zod schemas
├── store/                        # Zustand stores
│   ├── authStore.ts
│   ├── searchStore.ts
│   ├── favoritesStore.ts
│   └── uiStore.ts
├── types/                        # TypeScript types
│   ├── index.ts
│   ├── property.ts
│   ├── user.ts
│   ├── agent.ts
│   └── api.ts
├── public/                       # Static assets
│   ├── images/
│   └── fonts/
├── tailwind.config.ts
├── next.config.js
└── package.json
```

## 6. Package Installation List

```bash
# Initialize project
cd /mnt/okcomputer/output/
echo "my-app" | npx shadcn@latest init --yes --template next --base-color slate

# Navigate to project
cd my-app

# Install shadcn components
npx shadcn add button card input select dialog dropdown-menu tabs badge avatar skeleton toast tooltip popover sheet accordion slider switch checkbox radio-group separator scroll-area table calendar command

# Install animation libraries
npm install framer-motion

# Install state management
npm install zustand

# Install data fetching
npm install @tanstack/react-query

# Install form handling
npm install react-hook-form @hookform/resolvers zod

# Install date handling
npm install date-fns

# Install maps (optional - for map features)
npm install mapbox-gl react-map-gl

# Install charts
npm install recharts

# Install utilities
npm install clsx tailwind-merge
npm install lucide-react

# Install dev dependencies
npm install -D @types/mapbox-gl
```

## 7. API Structure (Mock)

```typescript
// Base API client
const api = {
  // Properties
  properties: {
    list: (params: SearchParams) => Promise<Property[]>,
    get: (id: string) => Promise<Property>,
    create: (data: CreatePropertyInput) => Promise<Property>,
    update: (id: string, data: UpdatePropertyInput) => Promise<Property>,
    delete: (id: string) => Promise<void>,
  },
  
  // Agents
  agents: {
    list: (params: AgentSearchParams) => Promise<Agent[]>,
    get: (id: string) => Promise<Agent>,
  },
  
  // Users
  users: {
    me: () => Promise<User>,
    update: (data: UpdateUserInput) => Promise<User>,
    favorites: {
      list: () => Promise<Property[]>,
      add: (propertyId: string) => Promise<void>,
      remove: (propertyId: string) => Promise<void>,
    },
  },
  
  // Search
  search: {
    suggest: (query: string) => Promise<SearchSuggestion[]>,
    filters: () => Promise<FilterOptions>,
  },
  
  // Mortgage
  mortgage: {
    rates: () => Promise<MortgageRate[]>,
    prequal: (data: PrequalInput) => Promise<PrequalResult>,
    calculate: (data: CalculateInput) => Promise<CalculateResult>,
  },
  
  // Admin
  admin: {
    moderation: {
      queue: () => Promise<ModerationCase[]>,
      action: (caseId: string, action: ModerationAction) => Promise<void>,
    },
    users: {
      list: (params: UserListParams) => Promise<User[]>,
      update: (id: string, data: UpdateUserInput) => Promise<User>,
    },
    analytics: {
      overview: () => Promise<AnalyticsOverview>,
      metrics: (period: string) => Promise<MetricsData>,
    },
  },
};
```

## 8. State Management

```typescript
// Zustand store patterns

// Auth Store
interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  setUser: (user: User) => void;
}

// Search Store
interface SearchState {
  query: string;
  filters: FilterState;
  results: Property[];
  isLoading: boolean;
  setQuery: (query: string) => void;
  setFilters: (filters: Partial<FilterState>) => void;
  search: () => Promise<void>;
  reset: () => void;
}

// Favorites Store
interface FavoritesState {
  favorites: string[];
  add: (propertyId: string) => void;
  remove: (propertyId: string) => void;
  isFavorite: (propertyId: string) => boolean;
}

// UI Store
interface UIState {
  sidebarOpen: boolean;
  modalOpen: boolean;
  toast: Toast | null;
  setSidebarOpen: (open: boolean) => void;
  setModalOpen: (open: boolean) => void;
  showToast: (toast: Toast) => void;
}
```

## 9. Performance Optimizations

1. **Image Optimization**
   - Use Next.js Image component
   - WebP format with JPEG fallback
   - Lazy loading with blur placeholder
   - Responsive srcset

2. **Code Splitting**
   - Dynamic imports for heavy components
   - Route-based splitting
   - Component lazy loading

3. **Data Fetching**
   - React Query for caching
   - Prefetch on hover
   - Stale-while-revalidate

4. **Rendering**
   - Server components where possible
   - Client components only when needed
   - Memoization with React.memo

5. **Bundle Size**
   - Tree shaking
   - Import only needed icons
   - Dynamic map loading

## 10. Security Considerations

1. **Authentication**
   - JWT with refresh tokens
   - Secure httpOnly cookies
   - CSRF protection

2. **Input Validation**
   - Zod schemas for all inputs
   - Sanitize user content
   - Rate limiting

3. **Data Protection**
   - PII encryption at rest
   - HTTPS only
   - Secure headers

4. **Admin Access**
   - Role-based access control
   - Audit logging
   - Session timeouts
