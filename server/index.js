// server/index.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch'); // or native fetch on newer Node versions
const admin = require('firebase-admin');

const app = express();
app.use(express.json());
app.use(cors());

// ---------- Firestore initialization ----------
// Option A: If you have service account JSON in env (for demo). For prod use file or ADC.
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '{}');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

// ---------- Helpers: compute metrics ----------

/**
 * computeRemainingBudget
 * - Assumes you keep per-user monthlyBudget in users/{uid}.document field monthlyBudget (number)
 * - and transactions in users/{uid}/transactions with fields: amount (positive income, negative expense), date (ISO string or Timestamp), category
 */
async function computeRemainingBudget(userId) {
  const userDoc = await db.collection('users').doc(userId).get();
  const monthlyBudget = (userDoc.exists && userDoc.data().monthlyBudget) ? Number(userDoc.data().monthlyBudget) : 0;

  // sum expenses for current month
  const start = new Date();
  start.setDate(1);
  start.setHours(0,0,0,0);
  const end = new Date(start);
  end.setMonth(end.getMonth() + 1);

  const txSnap = await db.collection('users').doc(userId)
    .collection('transactions')
    .where('date', '>=', admin.firestore.Timestamp.fromDate(start))
    .where('date', '<', admin.firestore.Timestamp.fromDate(end))
    .get();

  let spent = 0;
  txSnap.forEach(d => {
    const t = d.data();
    const amt = Number(t.amount || 0);
    if (amt < 0) spent += Math.abs(amt);
  });

  const remaining = Math.max(0, monthlyBudget - spent);
  return { monthlyBudget, spent, remaining };
}

/**
 * computeWeekendBudget
 * - Simple heuristic: split remaining into days left; allocate a safety factor for weekend
 */
function computeWeekendBudget(remaining) {
  const today = new Date();
  const day = today.getDay(); // 0 Sun .. 6 Sat

  // find next Saturday and Sunday length
  // We'll compute remaining weekend days this week (Sat, Sun)
  const saturday = new Date(today);
  saturday.setDate(today.getDate() + ((6 - day + 7) % 7));
  const sunday = new Date(saturday);
  sunday.setDate(saturday.getDate() + 1);

  // safety factor (don't recommend spending all remaining)
  const safetyFactor = 0.5; // suggests spend only 50% of remaining for weekend
  const weekendBudget = Math.round(remaining * safetyFactor);
  return { weekendBudget, safetyFactor };
}

/**
 * categoryRemaining
 */
async function computeCategoryRemaining(userId, category) {
  const userDoc = await db.collection('users').doc(userId).get();
  const budgets = (userDoc.exists && userDoc.data().categoryBudgets) ? userDoc.data().categoryBudgets : {}; // example: { food: 500, travel: 200 }
  const catBudget = Number(budgets[category] || 0);

  // sum category spent this month
  const start = new Date(); start.setDate(1); start.setHours(0,0,0,0);
  const end = new Date(start); end.setMonth(end.getMonth() + 1);

  const txSnap = await db.collection('users').doc(userId)
    .collection('transactions')
    .where('date', '>=', admin.firestore.Timestamp.fromDate(start))
    .where('date', '<', admin.firestore.Timestamp.fromDate(end))
    .where('category', '==', category)
    .get();

  let spent = 0;
  txSnap.forEach(d => { const amt = Number(d.data().amount || 0); if (amt < 0) spent += Math.abs(amt); });

  const remaining = Math.max(0, catBudget - spent);
  return { catBudget, spent, remaining };
}

/**
 * waste percentage heuristic
 * - Example heuristic: count transactions flagged as 'waste' or small purchases less than threshold and not repeated
 */
async function computeWastePercentage(userId) {
  // Simple heuristic: small expenses < 50 INR considered 'possible waste' (customize)
  const threshold = 50;
  const txSnap = await db.collection('users').doc(userId).collection('transactions').get();
  let totalSpent = 0, possibleWaste = 0;
  txSnap.forEach(d => {
    const t = d.data();
    const amt = Number(t.amount || 0);
    if (amt < 0) {
      totalSpent += Math.abs(amt);
      if (Math.abs(amt) <= threshold) possibleWaste += Math.abs(amt);
    }
  });
  const pct = totalSpent > 0 ? Math.round((possibleWaste / totalSpent) * 100) : 0;
  return { totalSpent, possibleWaste, pct, threshold };
}

// ---------- LLM call helper (supports OpenAI or Gemini via environment variables) ----------
const LLM_PROVIDER = (process.env.LLM_PROVIDER || 'openai').toLowerCase();
const LLM_KEY = process.env.LLM_API_KEY;
const LLM_MODEL = process.env.LLM_MODEL || 'gpt-4o-mini';

async function callLLM(prompt) {
  if (!LLM_KEY) throw new Error('LLM API key not configured on server.');

  if (LLM_PROVIDER === 'openai') {
    // Use OpenAI Chat Completions as an example
    const url = 'https://api.openai.com/v1/chat/completions';
    const body = {
      model: LLM_MODEL,
      messages: [{ role: 'system', content: 'You are a helpful finance assistant.' }, { role: 'user', content: prompt }],
      temperature: 0.2,
      max_tokens: 400
    };
    const r = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${LLM_KEY}` },
      body: JSON.stringify(body)
    });
    if (!r.ok) {
      const t = await r.text();
      throw new Error('LLM error: ' + t);
    }
    const j = await r.json();
    const text = j.choices?.[0]?.message?.content || JSON.stringify(j);
    return text;
  } else if (LLM_PROVIDER === 'gemini') {
    // NOAA: Gemini API shapes change; adjust to your chosen endpoint per docs.
    // This example assumes a simple generative endpoint accepting 'prompt' and returning 'candidates'
    const url = process.env.GEMINI_URL || 'https://api.generativeai.google/v1beta2/models/gemini-1.5/outputs';
    const body = {
      // This is a simplified structure — check Google docs for exact fields
      input: prompt,
      model: LLM_MODEL
    };
    const r = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${LLM_KEY}` },
      body: JSON.stringify(body)
    });
    if (!r.ok) {
      const t = await r.text();
      throw new Error('Gemini error: ' + t);
    }
    const j = await r.json();
    // extraction depends on API version — try common fields:
    const text = j?.candidates?.[0]?.content || j?.output?.[0]?.content?.[0]?.text || JSON.stringify(j);
    return text;
  } else {
    throw new Error('Unknown LLM provider: ' + LLM_PROVIDER);
  }
}

// ---------- Main /chat endpoint ----------
app.post('/chat', async (req, res) => {
  try {
    const { userId, message } = req.body;
    if (!userId || !message) return res.status(400).json({ error: 'userId and message required' });

    // normalize message
    const m = message.toLowerCase();

    // Quick pattern matches - deterministic server-side answers (faster & cheaper)
    if (/(expense left|remaining this month|how much left)/i.test(m)) {
      const r = await computeRemainingBudget(userId);
      return res.json({ answer: `You have ${r.remaining} left out of ₹${r.monthlyBudget} this month. You've spent ₹${r.spent}.` });
    }

    if (/(weekend|this weekend|spend this weekend)/i.test(m)) {
      const r = await computeRemainingBudget(userId);
      const wk = computeWeekendBudget(r.remaining);
      return res.json({ answer: `Based on your remaining ₹${r.remaining}, you can safely spend about ₹${wk.weekendBudget} this weekend (safety factor ${wk.safetyFactor * 100}%).` });
    }

    if (/how much.*food|spend.*food|food budget/i.test(m)) {
      const cat = 'food';
      const r = await computeCategoryRemaining(userId, cat);
      return res.json({ answer: `Your ${cat} budget this month is ₹${r.catBudget}. You have spent ₹${r.spent}. You can still spend ₹${r.remaining} on ${cat}.` });
    }

    if (/(waste|wasted|wasting)/i.test(m)) {
      const r = await computeWastePercentage(userId);
      return res.json({ answer: `Approximately ${r.pct}% of your spending may be 'possible waste' (small purchases under ₹${r.threshold}). Total spent: ₹${r.totalSpent}.` });
    }

    // Fallback: call LLM with a short context (include computed facts to reduce hallucination)
    const remainingInfo = await computeRemainingBudget(userId);
    const wasteInfo = await computeWastePercentage(userId);

    const context = `
User question: ${message}

Facts:
- Monthly budget: ₹${remainingInfo.monthlyBudget}
- Spent this month: ₹${remainingInfo.spent}
- Remaining this month: ₹${remainingInfo.remaining}
- Waste percentage estimate: ${wasteInfo.pct}%

Instructions:
Answer concisely. When providing numeric suggestions verify numbers against the facts above. Use short bullets or 1-2 sentence suggestions.
`;

    const llmAnswer = await callLLM(context);
    // Optional: you may further sanitize or extract numeric suggestions server-side

    return res.json({ answer: llmAnswer });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Server error', details: err.message });
  }
});

// Health
app.get('/', (req, res) => res.send('AI Finance Chatbot Backend OK'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server listening on ${PORT}`));



