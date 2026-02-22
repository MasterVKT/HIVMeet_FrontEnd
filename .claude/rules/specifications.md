# HIVMeet - Project Specifications Index

**Purpose**: Quick reference to all project specification documents in `docs/` folder.

---

## Primary Specifications

### 1. Development Plan
**File**: `docs/Plan de Développement Frontend Détaillé - HIVMeet.txt`

**Contains**:
- Complete development roadmap
- Feature implementation order
- Module dependencies
- Timeline and milestones

**When to Consult**: BEFORE starting any new feature or module.

---

### 2. Technical Architecture
**File**: `docs/Architecture Technique Frontend - HIVMeet.txt`

**Contains**:
- System architecture diagrams
- Technology stack details
- Design patterns used
- Infrastructure setup

**When to Consult**: When making architectural decisions or refactoring.

---

### 3. Functional Specifications
**File**: `docs/Spécifications Fonctionnelles Frontend - HIVMeet.txt`

**Contains**:
- Complete feature descriptions
- User workflows
- Business rules
- Acceptance criteria

**When to Consult**: When implementing user-facing features.

---

### 4. Data Model
**File**: `docs/Modèle de Données Frontend - HIVMeet.txt`

**Contains**:
- Entity definitions
- Data relationships
- State management models
- Local storage schema

**When to Consult**: When creating entities, models, or state classes.

---

### 5. UI/UX Design Guidelines
**File**: `docs/Charte Graphique Detaille - HIVMeet.txt`

**Contains**:
- Color palette
- Typography
- Component designs
- Spacing and layout rules

**When to Consult**: When building UI components or pages.

---

### 6. Screen Descriptions & Navigation
**File**: `docs/Description Détaillé des Écrans et Navigation -HIVMeet.txt`

**Contains**:
- Screen-by-screen descriptions
- Navigation flows
- User journeys
- Screen mockups/wireframes

**When to Consult**: When building pages or implementing navigation.

---

### 7. Interface Specifications
**File**: `docs/Document de Spécification Interface - HIVMeet.txt`

**Contains**:
- Backend API contracts
- Request/response formats
- Error handling specifications
- Data validation rules

**When to Consult**: When integrating with backend APIs.

---

## API Documentation (Modules)

### Authentication API
**File**: `docs/FRONTEND_AUTH_API.md`

**Endpoints**:
- Registration
- Login/Logout
- Password reset
- Email verification
- Token management

---

### Profiles API
**File**: `docs/FRONTEND_PROFILES_API.md`

**Endpoints**:
- Get user profile
- Update profile
- Upload photos
- Profile visibility settings
- Verification documents

---

### Matching API
**File**: `docs/FRONTEND_MATCHING_API.md`

**Endpoints**:
- Discovery profiles
- Like/Pass actions
- Super likes
- Match notifications
- Unmatch

---

### Messaging API
**File**: `docs/FRONTEND_MESSAGING_API.md`

**Endpoints**:
- Get conversations
- Send message
- Real-time chat (WebSocket)
- Message read status
- Block/Report

---

### Subscriptions API
**File**: `docs/FRONTEND_SUBSCRIPTIONS_API.md`

**Endpoints**:
- Get subscription plans
- Subscribe/Upgrade
- Payment processing
- Subscription status
- Cancel subscription

---

### Resources API
**File**: `docs/FRONTEND_RESOURCES_API.md`

**Endpoints**:
- Educational content
- Support resources
- Community guidelines
- FAQ

---

### Integration Guide
**File**: `docs/FRONTEND_INTEGRATION_GUIDE.md`

**Contains**:
- Step-by-step integration instructions
- Environment setup
- Testing guidelines
- Deployment checklist

---

## Additional Guides

### Complete Endpoints Documentation
**File**: `guides/ENDPOINTS_COMPLETE_DOCUMENTATION.md`

**Contains**: Comprehensive reference for ALL backend endpoints with examples.

**Note**: For most recent API reference, use **`API_DOCUMENTATION.md`** (root directory, updated September 14, 2025).

---

### Interaction History API
**File**: `guides/INTERACTION_HISTORY_API_DOCUMENTATION.md`

**Contains**: Detailed documentation for likes, passes, and interaction tracking.

---

### Activation Guide
**File**: `docs/GUIDE_ACTIVATION_API_INTERACTION_HISTORY.md`

**Contains**: Instructions for enabling interaction history feature.

---

## How to Use These Specifications

### Development Workflow

1. **Before Starting**:
   - Read `Plan de Développement Frontend Détaillé - HIVMeet.txt`
   - Identify current development phase
   - Check dependencies

2. **During Implementation**:
   - Consult relevant API documentation
   - Verify data models in `Modèle de Données Frontend`
   - Check UI/UX guidelines in `Charte Graphique Detaille`
   - Validate navigation flows in `Description Détaillé des Écrans`

3. **Before Completion**:
   - Verify against `Spécifications Fonctionnelles Frontend`
   - Ensure compliance with `Architecture Technique Frontend`
   - Test according to `FRONTEND_INTEGRATION_GUIDE`

---

### Quick Decision Tree

**"How should I implement feature X?"**
→ `Spécifications Fonctionnelles Frontend - HIVMeet.txt`

**"What endpoint do I call?"**
→ `API_DOCUMENTATION.md` (root) or `docs/FRONTEND_[MODULE]_API.md`

**"What colors/fonts should I use?"**
→ `Charte Graphique Detaille - HIVMeet.txt`

**"How should I structure my code?"**
→ `Architecture Technique Frontend - HIVMeet.txt`

**"What's the navigation flow?"**
→ `Description Détaillé des Écrans et Navigation -HIVMeet.txt`

**"What models do I need?"**
→ `Modèle de Données Frontend - HIVMeet.txt`

**"What's the implementation order?"**
→ `Plan de Développement Frontend Détaillé - HIVMeet.txt`

---

## Spec Compliance Checklist

Before completing any feature:

- [ ] Reviewed relevant specification documents
- [ ] Followed development plan order
- [ ] API contracts respected (`API_DOCUMENTATION.md`)
- [ ] Data models match `Modèle de Données Frontend`
- [ ] UI matches `Charte Graphique Detaille`
- [ ] Navigation flows correct per `Description Détaillé des Écrans`
- [ ] Code architecture follows `Architecture Technique Frontend`
- [ ] Internationalization implemented (FR/EN)
- [ ] No regressions introduced

---

**Always validate your implementation against these specifications before considering a task complete.**
