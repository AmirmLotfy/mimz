# Design Audit — Mimz

Assessment of visual consistency and design system decisions.

---

## Design System Foundation

### Tokens

| Token | Value | Usage |
|-------|-------|-------|
| **Background** | `#0A0A0F` | All screen backgrounds |
| **Surface** | `#1A1A2E` | Cards, panels, bottom sheet |
| **Primary** | `#6C5CE7` → `#A29BFE` gradient | Buttons, accents, active states |
| **Secondary** | `#00CEC9` | Success states, achievements |
| **Error** | `#FF6B6B` | Error states, warnings |
| **Text Primary** | `#FFFFFF` | Headings, primary content |
| **Text Secondary** | `#B0B0C0` | Labels, metadata |
| **Border Radius** | 16px (cards), 24px (buttons), 50% (avatars) | Consistent rounding |

### Typography

| Style | Font | Weight | Size |
|-------|------|--------|------|
| H1 | Inter | Bold | 28sp |
| H2 | Inter | SemiBold | 22sp |
| Body | Inter | Regular | 16sp |
| Caption | Inter | Regular | 12sp |
| Label | Inter | Medium | 14sp |
| Score | Space Grotesk | Bold | 48sp |

### Motion

| Effect | Duration | Curve |
|--------|----------|-------|
| Page transition | 300ms | easeInOutCubic |
| Card appear | 200ms | easeOut |
| Score increment | 400ms | elasticOut |
| Waveform | continuous | sinusoidal |
| Map tile | 150ms | easeIn |

---

## Visual Consistency Assessment

### Strengths

- **Dark theme is consistent** — every screen uses the same `#0A0A0F` background. No white flash on transitions.
- **Card system is unified** — all content cards use `Surface` color, 16px radius, and consistent padding (16px internal).
- **Gradient usage is restrained** — primary gradient appears only on CTAs and active navigation. Not overused.
- **Typography hierarchy is clear** — H1 for screen titles, H2 for section headers, Body for content. No ambiguity.
- **Score display is differentiated** — Space Grotesk at 48sp makes gameplay numbers feel like a sports scoreboard, not a spreadsheet.

### Where the Design Normalizes Weak Source Patterns

| Source Issue | Resolution |
|-------------|-----------|
| Inconsistent card padding (12-24px) | Standardized to 16px |
| Mixed button heights | Standardized to 48px touch target |
| Varying text opacity for secondary text | Standardized to `#B0B0C0` |
| Some screens had white backgrounds | All converted to dark theme |
| Tab indicators varied in style | Unified to bottom nav with icon + label |

---

## Component Strategy

### Reusable Components

| Component | Used In | Purpose |
|-----------|---------|---------|
| `MimzCard` | All screens | Consistent surface container |
| `MimzButton` | All interactive screens | Primary and secondary actions |
| `StatusPill` | Live screens | Connection/session state indicator |
| `WaveformVisualizer` | Quiz, Onboarding | Audio state feedback |
| `ProgressBar` | District, Squad, Events | Completion tracking |

### Screen-Specific Components

| Screen | Custom Element |
|--------|---------------|
| World Home | Map grid painter with district boundary |
| Live Quiz | Score counter with animated increment |
| Vision Quest | Camera viewfinder with analysis overlay |
| Reward Vault | Blueprint cards with tier-colored borders |
| Squad Hub | Member list with contribution bars |

---

## Spacing and Layout

- **Screen padding**: 24px horizontal
- **Section spacing**: 24px vertical
- **Card gap**: 12px
- **Bottom nav height**: 64px
- **App bar height**: 56px (transparent, blending into background)
- **Safe area**: Respected on all screens (iOS notch, Android gesture nav)

---

## Glassmorphism Usage

Applied selectively for premium feel:
- Bottom navigation bar background
- Live session status pill
- Quiz score container
- Not on content cards (readability concern on dark backgrounds)

All glass effects: `blur: 20, opacity: 0.1, border: 1px white/0.1`
