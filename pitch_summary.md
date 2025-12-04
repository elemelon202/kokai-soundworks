# Kokai Pitch Flow - Band Management + LINE Bot (5 Minutes)

## The Setup
**Login:** `thunder@band.com` / `password123` (Tokyo Thunder)
**LINE Group:** Have test group ready with pre-loaded messages (send these BEFORE the demo starts)

---

## 1. THE HOOK (30 sec)

> "Managing a band is chaos. You've got gigs to plan, members to coordinate, tasks piling up. Everyone's scattered across different apps."

> "Kokai brings it all together - and I'll show you something at the end that will blow your mind."

**Action:** Show the Band Dashboard - quick overview

---

## 2. GIG COUNTDOWN & CALENDAR (45 sec)

> "First thing you see - your next gig countdown. No more asking 'wait, when's that show again?'"

**Action:**
- Point out the countdown card (days/hrs/min)
- Show the calendar with rehearsals, gigs, member availability
- Click on an event to show details

> "Gigs, rehearsals, member availability - all in one view. Every band member sees this."

---

## 3. TASK MANAGEMENT (45 sec)

> "Running a band is like running a startup. There's always something that needs doing."

**Action:**
- Show Kanban board
- Show tasks across To Do / In Progress / Done
- Drag a task between columns
- Show task assignment dropdown

> "Who's bringing merch? Who's handling promo? Book the studio? Everyone knows their job. No more things falling through the cracks."

---

## 4. MUSICIANS WANTED (45 sec)

> "Your drummer breaks his hand a week before a big show. What do you do?"

**Action:**
- Go to `/feed` (Musicians Wanted)
- Show filters: drums, Tokyo
- Point out urgent badges

> "Post a request, musicians filter by instrument and location, they DM you directly. Find a fill-in in hours, not weeks."

---

## 5. THE LINE BOT MAGIC (1 min 30 sec) - THE BIG FINALE

> "Now here's where it gets really interesting. All these features are great, but they require you to manually update the app. What if you didn't have to?"

> "Your band already talks in LINE. What if LINE could update Kokai automatically?"

**Action:** Show LINE group on phone/screen with this conversation:

```
Taro: Let's rehearse this weekend
Yuki: Saturday works for me
Sam: Actually Sunday is better, I have work Saturday
Taro: Ok Sunday then, 3pm?
Yuki: Make it 4pm, I have lunch with my parents
Sam: 4pm works
Taro: Cool, I'll book Studio Wave
Yuki: Can someone make a flyer for the gig next month?
Sam: I'll do it
```

> "Normal band chat. Back and forth. Plans changing. This is what every band's LINE group looks like. Now watch..."

**Action:** Type "kokai" and send - LIVE

**Bot responds:**
> Rehearsal scheduled for Sunday at 4pm at Studio Wave. Sam will create the gig flyer.
>
> Added 1 event and 1 task to Tokyo Thunder!

> "The AI just read that entire conversation. It understood Saturday became Sunday. 3pm became 4pm. It extracted the FINAL decision. And it knew Sam volunteered for the flyer."

**Action:** Refresh Kokai dashboard - LIVE
- Show new rehearsal appearing on calendar
- Show new task on kanban (assigned to Sam)

> "Everything synced. Automatically. No copy-paste. No forgetting. No more 'wait, what did we decide?'"

---

## 6. THE CLOSE (30 sec)

> "That's Kokai."

> "Gig planning. Task management. Musician network. And an AI that turns your messy LINE group chat into an organized band."

> "You focus on the music. We handle the chaos."

**Action:** Pause. Let it land.

---

## One-Liner

**"Kokai turns your messy LINE group chat into an organized band - with AI that actually understands what you decided."**

---

## Key Demo Accounts

| Account | Password | Use For |
|---------|----------|---------|
| thunder@band.com | password123 | Main demo (Tokyo Thunder) |
| neon@band.com | password123 | Alternative band demo |
| yuki.drums@musician.com | password123 | Musician perspective |

---

## LINE Bot Demo Checklist

Before the pitch:
- [ ] LINE group ready with test messages
- [ ] Kokai dashboard open, show empty/current state first
- [ ] Send "kokai" LIVE during demo (this is the wow moment)
- [ ] Refresh dashboard to show new event/task appear
- [ ] Practice the timing - the live demo is everything

---

## Features to Highlight

- **LINE Bot Integration** - AI-powered, understands natural conversation
- **Smart Calendar** - Events from LINE + manual, member availability
- **Kanban Board** - Tasks assigned automatically from chat
- **Countdown Timer** - Visual urgency for upcoming gigs
- **Musicians Wanted** - Find fill-ins fast

---

## How the LINE Bot Works (if asked)

1. Bot listens silently to all messages (doesn't interrupt)
2. When someone says "kokai", it analyzes recent messages
3. Claude AI extracts events, tasks, and assignments
4. Automatically creates records in Kokai
5. Only processes messages since last "kokai" (no duplicates)

**Key differentiators:**
- Understands back-and-forth (not just last message)
- Knows who volunteered for tasks
- Works in Japanese and English
- Stays quiet until called

---

## Technical Talking Points (if asked)

- **Claude AI (Anthropic)** - Best-in-class language understanding
- **LINE Messaging API** - Native to Japan's #1 messaging app
- **Real-time sync** - Webhook-based, instant updates
- **Rails backend** - Solid, scalable, production-ready

---

## Backup Demo Script (if LINE fails)

If the live LINE demo fails:
1. Show screenshots of the conversation
2. Show the pre-created event/task
3. Explain what would have happened
4. "The AI analyzed this conversation and created these automatically"

Always have a backup. Live demos can fail.
