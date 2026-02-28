# Architecture Overview

Meta: updated 2026-02-20 | commit: mem/005

## Project Summary
- **Name**: acme-store
- **Type**: Full-stack e-commerce application
- **Framework**: Next.js 14 (App Router) + Supabase
- **Language**: TypeScript (strict mode)

## Tech Stack
- **Frontend**: Next.js 14, React 18, Tailwind CSS, shadcn/ui
- **Backend**: Next.js API Routes + Supabase Edge Functions
- **Database**: PostgreSQL (via Supabase)
- **Auth**: Supabase Auth (OAuth + email/password)
- **Payments**: Stripe (Checkout Sessions + Webhooks)
- **Storage**: Supabase Storage (product images)
- **Deployment**: Vercel (frontend) + Supabase (backend)

## Directory Structure
```
src/
├── app/                    # Next.js App Router pages
│   ├── (auth)/             # Auth-related pages (login, register)
│   ├── (shop)/             # Public shop pages
│   ├── admin/              # Admin dashboard (protected)
│   └── api/                # API routes
│       ├── webhooks/       # Stripe webhook handlers
│       └── trpc/           # tRPC router
├── components/
│   ├── ui/                 # shadcn/ui base components
│   ├── shop/               # Shop-specific components
│   └── admin/              # Admin-specific components
├── lib/
│   ├── supabase/           # Supabase client + helpers
│   ├── stripe/             # Stripe client + helpers
│   └── trpc/               # tRPC setup + routers
├── hooks/                  # Custom React hooks
└── types/                  # Shared TypeScript types
```

## Core Data Flow
1. **Product browsing**: Client → Next.js SSR → Supabase (products table) → rendered page
2. **Cart**: Client-side state (Zustand) → Stripe Checkout Session on purchase
3. **Payment**: Stripe Checkout → Stripe Webhook → API route → update Supabase orders table
4. **Auth**: Supabase Auth → middleware checks → protected routes

## Key Conventions
- All database queries go through `lib/supabase/` helpers, never raw SQL in components
- Stripe webhook signature verification is mandatory in all webhook handlers
- Server Components by default; Client Components only when interactivity required
- Environment variables: `.env.local` for dev, Vercel env vars for production

## Known Limitations
- No real-time inventory tracking (stock checked at checkout, not on product page)
- Admin dashboard has no role-based access control yet (single admin role)
- Image optimization relies on Vercel's built-in Image Optimization

## Technical Debt
- Cart state is client-only; no server-side persistence for guest users
- Some product queries lack pagination (fine for current catalog size of ~200 items)
