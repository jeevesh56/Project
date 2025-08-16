# Smart AI Finance Chatbot Backend

Node.js backend server for the Smart AI Flutter finance app with AI-powered financial insights.

## Features

- **Budget Tracking**: Compute remaining monthly budget and category-specific budgets
- **Smart Analytics**: Weekend spending recommendations and waste percentage analysis
- **AI Integration**: Gemini/OpenAI powered financial advice with context-aware responses
- **Firebase Integration**: Secure access to user data and transactions
- **Fast Pattern Matching**: Quick responses for common financial queries

## Setup

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Environment Configuration**
   ```bash
   cp env.example .env
   # Edit .env with your actual values:
   # - LLM_API_KEY: Your Gemini/OpenAI API key
   # - FIREBASE_SERVICE_ACCOUNT_JSON: Firebase service account (or use file-based auth)
   ```

3. **Firebase Setup**
   - Download service account JSON from Firebase Console
   - Either put the full JSON in `FIREBASE_SERVICE_ACCOUNT_JSON` env var
   - Or save as `service-account.json` and set `GOOGLE_APPLICATION_CREDENTIALS` path

## Usage

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

### API Endpoints

- `GET /` - Health check
- `POST /chat` - AI financial assistant
  ```json
  {
    "userId": "user_uid_here",
    "message": "How much do I have left this month?"
  }
  ```

## Quick Patterns

The server recognizes these patterns for fast responses:
- "expense left" / "remaining this month" → Budget remaining
- "weekend" / "this weekend" → Weekend spending recommendations  
- "food budget" → Category-specific budget analysis
- "waste" → Spending waste percentage analysis

## Security Notes

- Never commit `.env` files to version control
- Use Firebase service account files instead of inline JSON in production
- Implement proper authentication middleware for production use
- Rate limit API endpoints to prevent abuse

## Integration with Flutter

From your Flutter app, make HTTP POST requests to:
```
http://localhost:3000/chat
```

Example Flutter code:
```dart
final response = await http.post(
  Uri.parse('http://localhost:3000/chat'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'userId': FirebaseAuth.instance.currentUser?.uid,
    'message': 'How much can I spend this weekend?'
  }),
);

final data = jsonDecode(response.body);
print(data['answer']);
```



