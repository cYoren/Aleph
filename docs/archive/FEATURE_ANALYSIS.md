# Original Bible App - Feature Analysis

Status: historical (2026-06-02) — archived 2026-11-08; kept for provenance.

> **Document Purpose**: Comprehensive gap analysis comparing current state to competitive requirements for both scholarly and layperson audiences.

---

## Current State Summary

### ✅ What We Have

| Category | Feature | Status |
|----------|---------|--------|
| **Core Reading** | Hebrew/Greek original text display | ✅ Working |
| **Core Reading** | RTL support for Hebrew | ✅ Working |
| **Core Reading** | Chapter navigation | ✅ Working |
| **Core Reading** | Book picker with OT/NT sections | ✅ Working |
| **Word Analysis** | Tap-to-define (lexicon lookup) | ✅ Working |
| **Word Analysis** | Strong's numbers integration | ✅ Working |
| **Word Analysis** | Morphology codes (raw) | ✅ Working |
| **Word Analysis** | Lemma display | ✅ Working |
| **Pronunciation** | Transliteration toggle | ✅ Working |
| **Translations** | Multiple translation support | ✅ Working |
| **Translations** | Side-by-side original + translation | ✅ Working |
| **Search** | Full-text search with FTS5 | ✅ Working |
| **Settings** | Theme (light/dark/system) | ✅ Working |
| **Settings** | Font size adjustment | ✅ Working |
| **Settings** | Translation selection | ✅ Working |
| **i18n** | Interface in EN, PT, DE, FR | ✅ Working |
| **Platform** | iOS, Android, Web, Desktop | ✅ Working |
| **Data** | 110MB SQLite with full Bible | ✅ Working |

### Technical Stack
- **Framework**: Flutter 3.10+
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Database**: SQLite (sqflite)
- **Fonts**: EzraSIL for Hebrew

---

## Gap Analysis: Scholar Features

### 🔴 Critical (Must Have for Scholars)

#### 1. Interlinear View Mode
**Current**: Words displayed inline with tap-to-define
**Needed**: Stacked word-by-word display showing:
- Original text (Hebrew/Greek)
- Transliteration
- Grammatical parsing (decoded)
- English gloss

**Implementation Complexity**: Medium
**User Value**: Essential - this is the #1 scholar feature

#### 2. Morphology Code Decoding
**Current**: Raw codes displayed (e.g., "Ncmsa", "V-AAI-3S")
**Needed**: Human-readable parsing:
- Hebrew: "Noun, common, masculine, singular, absolute"
- Greek: "Verb, Aorist, Active, Indicative, 3rd person, Singular"

**Implementation Complexity**: Low (parsing logic)
**User Value**: High - raw codes are unusable for most

#### 3. Parallel Text View
**Current**: Original + single translation vertically stacked
**Needed**: 
- Side-by-side columns
- Multiple translations simultaneously
- Synced scrolling

**Implementation Complexity**: Medium
**User Value**: Essential for comparative study

#### 4. Cross-References
**Current**: None
**Needed**: 
- Scripture cross-reference system
- Tap verse → see related passages
- Treasury of Scripture Knowledge integration

**Implementation Complexity**: Medium (requires data)
**User Value**: High for deep study

#### 5. Word Frequency & Concordance
**Current**: None
**Needed**:
- "This word (H1234) appears 47 times in OT"
- Link to all occurrences
- Filter by book/testament

**Implementation Complexity**: Low (SQL queries)
**User Value**: Medium-High

#### 6. Semantic Range Display
**Current**: Single gloss in definition
**Needed**:
- Multiple meaning options
- Usage contexts
- Example verses for each meaning

**Implementation Complexity**: Medium (requires lexicon enhancement)
**User Value**: High for word studies

---

### 🟡 Important (Differentiation for Scholars)

#### 7. Syntax/Clause Visualization
**Current**: None
**Needed**: Diagramming of sentence structure
**Implementation Complexity**: High
**User Value**: Medium (advanced scholars)

#### 8. Textual Apparatus
**Current**: None  
**Needed**: Critical variant readings, manuscript attestation
**Implementation Complexity**: High (requires specialized data)
**User Value**: Medium (textual critics)

#### 9. Manuscript Source Information
**Current**: None
**Needed**: Display source texts (BHS, NA28, etc.)
**Implementation Complexity**: Low (documentation)
**User Value**: Medium (academic credibility)

#### 10. Export & Citation
**Current**: None
**Needed**:
- Copy verse with formatting
- Export to Markdown/plain text
- Academic citation format

**Implementation Complexity**: Low
**User Value**: High for researchers

---

## Gap Analysis: Layperson Features

### 🔴 Critical (Must Have for Casual Readers)

#### 1. Audio Pronunciation
**Current**: Visual transliteration only
**Needed**:
- Tap-to-hear Hebrew/Greek words
- Verse-level audio playback
- AI-generated or recorded pronunciation

**Implementation Complexity**: Medium-High (audio assets)
**User Value**: Essential - removes fear of original languages

#### 2. Bookmarks & Favorites
**Current**: None
**Needed**:
- Bookmark verses
- Organize into collections
- Quick access from home screen

**Implementation Complexity**: Low
**User Value**: Essential for engagement

#### 3. Personal Notes
**Current**: None
**Needed**:
- Attach notes to verses
- Rich text or markdown
- Searchable notes

**Implementation Complexity**: Medium
**User Value**: High for devotional use

#### 4. Verse Highlighting
**Current**: None
**Needed**:
- Color-coded highlighting
- Multiple highlight colors
- Filter view by color

**Implementation Complexity**: Low-Medium
**User Value**: High - visual engagement

#### 5. Swipe Navigation
**Current**: Button-based chapter navigation
**Needed**:
- Swipe left/right for chapters
- Pull-to-refresh gesture
- Smooth page transitions

**Implementation Complexity**: Low
**User Value**: High - expected UX pattern

#### 6. Reading Plans
**Current**: None
**Needed**:
- Pre-built plans ("Bible in a Year", "Gospels in 30 Days")
- Progress tracking
- Reminders/notifications
- Custom plan creation

**Implementation Complexity**: Medium
**User Value**: Essential for retention

#### 7. Verse Sharing
**Current**: None
**Needed**:
- Share as text to messaging apps
- Generate image with verse (for Instagram/social)
- Copy with reference

**Implementation Complexity**: Low-Medium
**User Value**: High for virality

---

### 🟡 Important (Delight Features)

#### 8. Daily Verse Notifications
**Current**: Verse of the day on home (passive)
**Needed**:
- Push notifications
- Customizable timing
- Category selection

**Implementation Complexity**: Medium
**User Value**: High for habit formation

#### 9. Home Screen Widget
**Current**: None
**Needed**:
- iOS/Android widget with daily verse
- Quick access to continue reading

**Implementation Complexity**: Medium-High (platform-specific)
**User Value**: Medium

#### 10. Reading Streak & Gamification
**Current**: None
**Needed**:
- Daily streak counter
- Achievements/badges
- Reading statistics

**Implementation Complexity**: Medium
**User Value**: Medium (engagement hook)

#### 11. Night Reading Mode
**Current**: Dark theme only
**Needed**:
- Sepia/warm tones
- Blue light reduction
- Auto-switch by time

**Implementation Complexity**: Low
**User Value**: Medium

#### 12. "Learn the Alphabet" Tutorial
**Current**: Basic onboarding
**Needed**:
- Interactive Hebrew alphabet lesson
- Greek alphabet introduction
- Gamified learning

**Implementation Complexity**: High
**User Value**: High for beginners

---

## Gap Analysis: Polish & UX

### Issues to Address

| Issue | Current State | Required Fix |
|-------|---------------|--------------|
| Empty states | Generic text | Illustrated, helpful guidance |
| Loading states | Basic spinner | Skeleton loaders |
| Greek typography | Uses EzraSIL | Add proper Greek font |
| Hardcoded strings | Some English only | Full i18n coverage |
| Strong's display | Raw "H1234" codes | Friendly labels + explanation |
| Definition sheet | Minimal info | Rich content + usage examples |
| Search | No filters | Book, testament, language filters |
| Chapter navigation | No preview | Chapter summaries/titles |
| Error handling | Basic | User-friendly messages + retry |
| Onboarding | Minimal | Guided tour of features |

---

## Competitive Positioning Matrix

| Feature | Logos | Blue Letter Bible | YouVersion | Original Bible (Target) |
|---------|-------|-------------------|------------|------------------------|
| Original Languages | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐ |
| Interlinear | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ | ⭐⭐⭐⭐ |
| Audio | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Reading Plans | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Social/Sharing | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Price | $$$$ | Free | Free | Free |
| Ease of Use | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Offline | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### Our Unique Value Proposition
**"The friendly original language Bible"** - Bridge the gap between:
- Scholars who want depth (Logos)
- Casual readers who want simplicity (YouVersion)

Target: Curious believers who want to go deeper without needing a seminary degree.

---

## Priority Matrix

### Phase 1: MVP Enhancement (Weeks 1-4)
> Goal: Make the app genuinely usable for daily reading

1. ⭐ Interlinear view mode
2. ⭐ Morphology decoding
3. ⭐ Bookmarks system
4. ⭐ Swipe navigation
5. ⭐ Better empty/loading states
6. ⭐ Greek font support

### Phase 2: Engagement (Weeks 5-8)
> Goal: Give users reasons to return daily

7. Personal notes
8. Verse highlighting
9. Reading plans (1-2 built-in)
10. Verse sharing (text + image)
11. Daily notifications

### Phase 3: Depth (Weeks 9-12)
> Goal: Satisfy intermediate scholars

12. Cross-references
13. Word frequency/concordance
14. Parallel text view
15. Audio pronunciation (basic)
16. Export/copy features

### Phase 4: Delight (Weeks 13+)
> Goal: Stand out from competition

17. Reading streaks/gamification
18. Learn the alphabet tutorial
19. Advanced syntax visualization
20. Home screen widgets

---

## Success Metrics

| Metric | Current | Target (6 months) |
|--------|---------|-------------------|
| Daily Active Users | 0 | 1,000+ |
| Session Duration | N/A | 8+ minutes |
| D7 Retention | N/A | 25%+ |
| App Store Rating | N/A | 4.5+ stars |
| Reading Plan Completion | N/A | 15%+ |

---

## Technical Debt to Address

1. **Web platform**: `database_web.dart` is stub only
2. **Test coverage**: No unit/widget tests
3. **Error handling**: Inconsistent across providers
4. **Accessibility**: Not audited for screen readers
5. **Performance**: Large chapter loads not optimized
6. **Data validation**: No schema versioning for DB updates

---

## Appendix: Data Requirements

### Additional Database Tables Needed

```sql
-- Bookmarks
CREATE TABLE bookmarks (
  id INTEGER PRIMARY KEY,
  verse_id TEXT NOT NULL,
  created_at INTEGER,
  collection_id INTEGER
);

-- Notes
CREATE TABLE notes (
  id INTEGER PRIMARY KEY,
  verse_id TEXT NOT NULL,
  content TEXT,
  created_at INTEGER,
  updated_at INTEGER
);

-- Highlights
CREATE TABLE highlights (
  id INTEGER PRIMARY KEY,
  verse_id TEXT NOT NULL,
  color TEXT,
  created_at INTEGER
);

-- Reading Plans
CREATE TABLE reading_plans (
  id TEXT PRIMARY KEY,
  name TEXT,
  description TEXT,
  total_days INTEGER
);

CREATE TABLE reading_plan_progress (
  id INTEGER PRIMARY KEY,
  plan_id TEXT,
  day_number INTEGER,
  completed_at INTEGER
);

-- Cross References  
CREATE TABLE cross_references (
  id INTEGER PRIMARY KEY,
  source_verse_id TEXT,
  target_verse_id TEXT,
  relationship TEXT
);
```

---

*Document Version: 1.0*  
*Last Updated: 2026-01-16*
