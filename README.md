# Track Me — Backend API

> AI-Powered Productivity Application — NestJS REST API

## 🚀 Tech Stack

- **NestJS** — Node.js framework
- **TypeScript** — Type-safe JavaScript
- **Prisma ORM** — Type-safe database client
- **PostgreSQL** — via Supabase
- **JWT** — Authentication (access + refresh tokens)
- **Passport.js** — Auth strategies (JWT, Google OAuth2)
- **Swagger** — Auto-generated API docs
- **Google Gemini** — AI insights

---

## 📁 Project Structure

```
src/
├── auth/               # JWT + Google OAuth authentication
│   ├── dto/            # Request validation DTOs
│   ├── guards/         # JWT auth guards
│   └── strategies/     # Passport strategies
├── users/              # User profile management
├── habits/             # Habit CRUD + streak tracking
├── habit-logs/         # Habit completion/skip logging
├── goals/              # Goal CRUD + progress tracking
├── ai/                 # Gemini AI integration
├── notifications/      # Push notification management
├── prisma/             # Database service
└── common/
    ├── interceptors/   # Response wrapper
    └── filters/        # Exception handler
prisma/
└── schema.prisma       # Database schema (8 tables)
```

---

## ⚙️ Setup

### 1. Prerequisites

- Node.js 18+
- npm or yarn
- Supabase account ([supabase.com](https://supabase.com))

### 2. Install Dependencies

```bash
cd track_me_backend
npm install
```

### 3. Configure Environment

```bash
cp .env.example .env
```

Fill in your values in `.env`:

```env
DATABASE_URL="postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"
JWT_SECRET=your_super_secret_key_at_least_32_characters
GEMINI_API_KEY=your_gemini_api_key
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### 4. Database Setup (Supabase)

1. Create a new Supabase project
2. Get your connection string from Settings → Database
3. Add it to `DATABASE_URL` in `.env`
4. Run Prisma migrations:

```bash
# Generate Prisma client
npx prisma generate

# Push schema to database (development)
npx prisma db push

# Or run migrations (production)
npx prisma migrate deploy
```

### 5. Start the Server

```bash
# Development (hot reload)
npm run start:dev

# Production
npm run build
npm run start:prod
```

---

## 📚 API Documentation

Once running, view Swagger UI at:
```
http://localhost:3000/api/docs
```

---

## 🔌 API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register with email/password |
| POST | `/api/auth/login` | Login with email/password |
| POST | `/api/auth/google` | Login with Google token |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/forgot-password` | Request password reset |
| POST | `/api/auth/logout` | Logout (invalidate tokens) |
| GET | `/api/auth/me` | Get current user |

### Users
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/me` | Get user profile |
| PATCH | `/api/users/me` | Update profile |
| GET | `/api/users/me/stats` | Get user stats |
| PATCH | `/api/users/me/fcm-token` | Update FCM token |

### Habits
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/habits` | Get all habits + weekly logs |
| POST | `/api/habits` | Create habit |
| PATCH | `/api/habits/:id` | Update habit |
| DELETE | `/api/habits/:id` | Delete (soft) habit |
| GET | `/api/habits/:id/streak` | Get habit streak |

### Habit Logs
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/habit-logs` | Mark habit complete |
| POST | `/api/habit-logs/skip` | Skip habit with reason |
| DELETE | `/api/habit-logs/:habitId/:date` | Uncomplete habit |
| GET | `/api/habit-logs/weekly-stats` | Get weekly statistics |

### Goals
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/goals` | Get all goals |
| POST | `/api/goals` | Create goal |
| PATCH | `/api/goals/:id` | Update goal |
| PATCH | `/api/goals/:id/progress` | Update progress (0.0-1.0) |
| DELETE | `/api/goals/:id` | Delete goal |

### AI
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/ai/insights` | Get AI productivity insights |
| POST | `/api/ai/weekly-report` | Generate weekly AI report |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/notifications` | Get user notifications |
| GET | `/api/notifications/unread-count` | Get unread count |
| PATCH | `/api/notifications/:id/read` | Mark as read |
| PATCH | `/api/notifications/read-all` | Mark all as read |

---

## 🗄️ Database Schema

8 tables with proper relations and indexes:
- `users` — User accounts
- `refresh_tokens` — JWT refresh tokens
- `habits` — User habits
- `habit_logs` — Daily completion/skip records
- `goals` — User goals
- `goal_progress` — Goal progress history
- `ai_reports` — Weekly AI-generated reports
- `notifications` — User notification records

---

## 🔐 Authentication

All protected endpoints require:
```
Authorization: Bearer <access_token>
```

Access tokens expire in 15 minutes. Use the refresh token endpoint to get new tokens.

---

## 🚢 Deployment (Railway)

1. Push code to GitHub
2. Create new Railway project
3. Add PostgreSQL plugin or connect Supabase
4. Set all environment variables
5. Deploy → Railway auto-detects NestJS

```bash
# Build command (auto-detected)
npm run build

# Start command
npm run start:prod
```
