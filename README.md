# 🏠 Household OS

> The operating system for people who live together.

Household OS is a shared home management platform for roommates, families, and small living groups. It brings your grocery list, chores, bills, maintenance reminders, and shared expenses into one place — so everyone stays on the same page without the arguments.

---

## The Problem

People who live together deal with the same coordination failures every week:

- "Did anyone pay the electricity bill?"
- "Whose turn is it to clean the bathroom?"
- "We're out of rice again."
- "The AC hasn't been serviced in months."

Groups currently patch this together with WhatsApp threads, shared Notes apps, Excel sheets, and memory. It breaks constantly. **Household OS fixes this.**

---

## Who It's For

| Segment                 | Pain Point                                              |
| ----------------------- | ------------------------------------------------------- |
| **Roommates**           | Bill splitting, chore conflicts, shared shopping        |
| **Students in hostels** | Low coordination, shared spaces, tight budgets          |
| **Families**            | Grocery tracking, maintenance reminders, task ownership |
| **Apartment complexes** | Multi-unit management, payment tracking _(later)_       |
| **Property managers**   | Tenant coordination, maintenance logs _(later)_         |

**Start narrow.** The v1 targets roommates and student housing — they have daily coordination pain, zero budget for expensive tools, and they'll actually use something simple if it saves them time and conflict.

---

## Core Features (v1)

### 🔐 Authentication & House Setup

- Sign up / log in
- Create a House (name it, set address)
- Generate an invite link or code for members
- Roles: **Admin** (house creator) and **Member**

### 👥 Member Management

- Add and remove members
- View who's in the house
- Optional: member avatars and nicknames

### 📋 Shared To-Do & Task List

- Add tasks visible to everyone in the house
- Assign tasks to specific members
- Mark tasks done
- Recurring tasks (daily / weekly / monthly)

### 🧹 Chore Scheduler

- Assign chores with deadlines
- Rotating assignments (auto-rotate each week)
- Status: Pending → In Progress → Done
- Overdue chore alerts

### 🛒 Grocery & Household Inventory

- Shared shopping list with categories (food, cleaning, toiletries)
- Members can add, check off, or remove items
- Low-stock alerts for tracked inventory items
- Purchase history

### 💡 Bill Reminders & Payment Tracking

- Add recurring bills (electricity, gas, internet, water, rent)
- Set due dates and amounts
- Mark as paid — with who paid
- Payment history log

### 💸 Expense Split

- Log a shared expense (who paid, what for, how much)
- Split equally or by custom amount
- View who owes what at a glance
- Settle up and mark debts as cleared
- Running balance between members

### 🔧 Maintenance Reminders

- Add appliances or systems (fridge, AC, gas cylinder, water filter, fire alarm)
- Set service intervals (every 3 months, 6 months, yearly)
- Get reminders before the due date
- Log service history with date and notes

### 📁 House Documents _(optional in v1)_

- Upload and store shared documents: lease agreement, utility contacts, warranties
- Accessible to all members

---

## Product Philosophy

**Daily use, not monthly panic.** Most home apps get opened when something breaks or a bill is due. Household OS is built for everyday check-ins — the grocery list alone brings people back every 2–3 days.

**No complicated setup.** Create a house, share a link, start adding items. It should work in under 5 minutes without reading any documentation.

**Opinionated defaults.** The app makes sensible assumptions (equal splits by default, weekly chore rotation, 30-day bill reminder window) so users don't have to configure everything upfront.

**Group-first design.** Every feature is designed around shared visibility. Nothing is private by default inside a house.

---

## Tech Stack (Recommended)

### Backend

```
Node.js + Express          → REST API
PostgreSQL                 → Primary database
Prisma ORM                 → Schema management and queries
Redis                      → Session store, caching
BullMQ                     → Background jobs (reminders, recurring tasks)
JWT                        → Authentication tokens
```

### Frontend

```
React (Vite)               → UI framework
TailwindCSS                → Styling
React Query                → Server state management
React Router               → Client-side routing
```

### Infrastructure

```
Railway / Render           → Backend hosting (cheap, fast to ship)
Vercel / Netlify           → Frontend hosting
Supabase / Neon            → Managed PostgreSQL (generous free tier)
Cloudflare R2              → Document storage (if implemented)
```

### Notifications _(v1 simple version)_

```
Email (Resend / Nodemailer)  → Bill due reminders, chore overdue alerts
Push *(v2)*                  → Web push or mobile via Expo
```

---

## Database Schema (Overview)

```
users
  id, name, email, password_hash, avatar_url, created_at

houses
  id, name, address, invite_code, created_by, created_at

house_members
  id, house_id, user_id, role (admin|member), joined_at

tasks
  id, house_id, title, assigned_to, due_date, status, is_recurring, recurrence, created_by, created_at

grocery_items
  id, house_id, name, category, quantity, unit, is_checked, added_by, created_at

bills
  id, house_id, name, amount, due_date, recurrence, is_paid, paid_by, paid_at, created_at

expenses
  id, house_id, description, amount, paid_by, split_type (equal|custom), created_at

expense_splits
  id, expense_id, user_id, amount_owed, is_settled, settled_at

maintenance_items
  id, house_id, name, interval_days, last_serviced, next_due, notes, created_at

documents
  id, house_id, name, file_url, uploaded_by, created_at
```

---

## API Structure

```
POST   /auth/signup
POST   /auth/login
POST   /auth/logout

POST   /houses                    → create house
GET    /houses/:id                → get house info
POST   /houses/:id/invite         → generate invite
POST   /houses/join               → join via invite code

GET    /houses/:id/members
DELETE /houses/:id/members/:uid

GET    /houses/:id/tasks
POST   /houses/:id/tasks
PATCH  /tasks/:id
DELETE /tasks/:id

GET    /houses/:id/grocery
POST   /houses/:id/grocery
PATCH  /grocery/:id
DELETE /grocery/:id

GET    /houses/:id/bills
POST   /houses/:id/bills
PATCH  /bills/:id/pay

GET    /houses/:id/expenses
POST   /houses/:id/expenses
GET    /houses/:id/balances
POST   /expenses/:id/settle

GET    /houses/:id/maintenance
POST   /houses/:id/maintenance
PATCH  /maintenance/:id/service

GET    /houses/:id/documents
POST   /houses/:id/documents
```

---

## MVP Scope (What to Build First)

The goal of v1 is **one working group end-to-end**. That means:

1. Auth (signup / login / logout)
2. Create a house and invite 2–3 people
3. Shared task list with basic assignment
4. Grocery list (add, check off, delete)
5. Bill reminders (add bill, mark as paid)
6. Expense split (log expense, view who owes what)

**Chore rotation, maintenance reminders, and documents are v1.5** — implement after the core loop is stable and tested with real users.

---

## Growth Path

```
v1   →  Roommates and students (manual, free, web-only)
v1.5 →  Mobile-friendly PWA + push notifications
v2   →  Premium plan: unlimited houses, file storage, receipt scanning
v3   →  Apartment complexes and hostels (admin dashboard, multi-unit)
v4   →  Property manager tier (tenant management, maintenance vendor tracking)
```

---

## Monetization

| Plan                   | Price               | Who                                                                             |
| ---------------------- | ------------------- | ------------------------------------------------------------------------------- |
| **Free**               | $0                  | 1 house, up to 6 members, core features                                         |
| **Home Premium**       | ~$4/month per house | Unlimited members, document storage, expense history export, priority reminders |
| **Hostel / Apartment** | ~$20–50/month       | Multi-unit dashboard, manager accounts, bulk bill tracking                      |
| **Property Manager**   | Custom              | Full property suite, tenant portal, maintenance vendor integration              |

**Do not charge v1 users.** Get 50–100 active households using it daily first. Then charge for the features they ask for.

---

## Project Structure

```
household-os/
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── houses.js
│   │   │   ├── tasks.js
│   │   │   ├── grocery.js
│   │   │   ├── bills.js
│   │   │   ├── expenses.js
│   │   │   └── maintenance.js
│   │   ├── middleware/
│   │   │   ├── auth.js
│   │   │   └── houseAccess.js
│   │   ├── jobs/
│   │   │   ├── billReminders.js
│   │   │   └── maintenanceAlerts.js
│   │   ├── prisma/
│   │   │   └── schema.prisma
│   │   └── index.js
│   ├── .env.example
│   └── package.json
│
├── frontend/
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Dashboard.jsx
│   │   │   ├── Grocery.jsx
│   │   │   ├── Chores.jsx
│   │   │   ├── Bills.jsx
│   │   │   ├── Expenses.jsx
│   │   │   └── Maintenance.jsx
│   │   ├── components/
│   │   ├── hooks/
│   │   └── App.jsx
│   └── package.json
│
└── README.md
```

---

## Getting Started

```bash
# Clone the repo
git clone https://github.com/Saad7890-web/Household-Os.git
cd household-os

# Backend setup
cd backend
cp .env.example .env        # Fill in DATABASE_URL, JWT_SECRET, etc.
npm install
npx prisma migrate dev
npm run dev

# Frontend setup
cd ../frontend
npm install
npm run dev
```

Open `http://localhost:5173`, create a house, share the invite code with your roommates.

---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add chore rotation logic"`
4. Push and open a pull request

Please keep PRs focused. One feature or fix per PR.

---

_Built for people who live together and want fewer arguments._
